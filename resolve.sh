#!/bin/bash
set -e -o pipefail

cat ./export/*-accounts.txt | sort -u >/tmp/accounts.txt

while true; do
    # Choose one of the unknown transactions' description
    transactions=$(
        cat ./export/*unknown.journal |
            hledger -f - register -I -O csv |
            grep -v ":unknown" |
            {
                rules_file=$(find ./import -name "rules.psv" 2>/dev/null)
                if [ -n "$rules_file" ]; then
                    grep -v -f <(cat $rules_file | cut -d'|' -f1)
                else
                    cat # If no rules file found, just pass through all lines
                fi
            } |
            mlr --csv cut -f date,description,account,amount
    )
    count=$(echo "${transactions}" | mlr count | cut -d'=' -f2)
    ((count--)) # We don't want to count the header
    if [ "$count" == "0" ]; then
        echo "No unknown transactions left!"
        exit 0
    fi
    description_account=$(
        echo "${transactions}" |
            fzf --header="Choose transaction to resolve" --wrap --border --border-label "Resolving Unknowns (${count}) - 1/4" --tac -d ',' --header-lines=1 --nth 2 |
            mlr --csv --implicit-csv-header --headerless-csv-output cut -f 2,3
    )

    # Description_account is "<description>,<source account that money came from>"
    # We can use account to figure out which rules file we need to modify
    account=$(echo "${description_account}" | mlr --csv --implicit-csv-header --headerless-csv-output cut -f 2)
    description=$(echo "${description_account}" | mlr --csv --implicit-csv-header --headerless-csv-output cut -f 1)
    case "${account}" in
    assets:Lloyds*)
        dir="./import/lloyds/"
        ;;
    expenses:amazon)
        dir="./import/amazon/"
        ;;
    assets:temp:Paypal*)
        dir="./import/paypal/"
        ;;
    *)
        echo "Unknown source dir for ${account}"
        exit 1
        ;;
    esac

    # Create rules.psv if necessary
    if [ ! -f ${dir}/rules.psv ]; then
        base_folder=$(basename ${dir})
        touch ${dir}/rules.psv
        echo "if|account2|comment" >>${dir}/rules.psv
        echo $'\ninclude rules.psv' >>${dir}/${base_folder}.rules
        echo "Created ${dir}/rules.psv and added include directive to ${dir}/${base_folder}.rules."
        printf "\e[1;33mNOTE:\e[0m You must add \`rules.psv\` to the extra deps of ${base_folder} in export.hs!\n"
    fi

    regexp=$(
        # TODO: what about file specific rules in subdirectories? (Chapter 12)
        rules=$(
            for file in ${dir}/*.rules; do
                # Ignore comments, since they break fzf call
                grep -v '^#' "$file"
            done | paste -s -d ' ' -
        )
        RELOAD="reload:rg --color=always --line-number --ignore-case '{q}' ${rules} ${dir}/rules.psv ${dir}/csv || :"
        fzf --header=$'Fine-tune regexp to create import rule.\nSearching in '"${dir}"'/*.rules and '"${dir}"'/csv' \
            --disabled --ansi --wrap \
            --border --border-label "Resolving Unknowns (${count}) - 2/4" \
            --print-query \
            --bind "start:$RELOAD" --bind "change:$RELOAD" \
            --bind 'ctrl-d:delete-char' \
            --query "${description}" |
            head -n1
    )

    # Now lets choose account
    target_account=$(
        cat /tmp/accounts.txt |
            sort -u |
            fzf --header="Choose target account (prepend : to create new account)" --wrap \
                --border --border-label "Resolving Unknowns (${count}) - 3/4" \
                --bind "enter:accept-or-print-query"
    )
    if [[ $target_account == :* ]]; then
        target_account=$(echo $target_account | sed -e 's/^://')
        echo "Adding new account: ${target_account}"
        echo "${target_account}" >>/tmp/accounts.txt
    fi

    cat ${dir}/rules.psv | cut -d '|' -f3 | sort -u >/tmp/comments.txt

    # ... and comment. Comment could be either selected from existing comments
    # or just entered. When entered comment is a substring match of one of the existing comments,
    # you can prepend your comment with ":" to prevent the match from being selected
    comment=$(
        RELOAD="reload:rg --color=always --line-number {q} /tmp/comments.txt || :"
        fzf --header="Enter optional comment (prepend : to inhibit selection)" --disabled --ansi \
            --wrap --border --border-label "Resolving Unknowns (${count}) - 4/4" \
            --bind "start:$RELOAD" --bind "change:$RELOAD" \
            --bind "enter:accept-or-print-query" |
            cut -d ':' -f2
    )

    echo "${regexp}|${target_account}|${comment}" >>"${dir}/rules.psv"
    echo "Added rule: ${regexp}|${target_account}|${comment} to ${dir}/rules.psv"
done
