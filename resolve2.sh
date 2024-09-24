#!/bin/bash
set -e -o pipefail

# Stores list of current accounts
cat ./export/*-accounts.txt | sort -u >/tmp/accounts.txt
# Stores transactions that were resolved by specific rules
: >/tmp/hledger_specific_txns.mlr

while true; do
    # Choose one of the unknown transactions' description
    transactions=$(
        cat ./export/*unknown.journal |
            hledger -f - register -I -O csv |
            grep -v ":unknown" |
            mlr --csv filter -x -f /tmp/hledger_specifc_txns.mlr then cut -f txnidx,date,description,account,amount
    )

    rules_files=$(find ./import -name "rules.psv" 2>/dev/null)
    if [ -n "$rules_files" ]; then
        transactions=$(echo $transactions | grep -v -f <(cat $rules_files | cut -d'|' -f1))
    else
    # TODO

    count=$(echo "${transactions}" | mlr count | cut -d'=' -f2)
    ((count--)) # We don't want to count the header
    if [ "$count" == "0" ]; then
        echo "No unknown transactions left!"
        exit 0
    fi
    transaction_info=$(
        echo "${transactions}" |
            fzf --header="Choose transaction to resolve" --wrap --border --border-label "Resolving Unknowns (${count}) - 1/5" --tac -d ',' --header-lines=1 --nth 2
    )
    txnidx=$(echo "${transaction_info}" | mlr --csv --implicit-csv-header --headerless-csv-output cut -f 2)
    transaction_date=$(echo "${transaction_info}" | mlr --csv --implicit-csv-header --headerless-csv-output cut -f 2)
    description=$(echo "${transaction_info}" | mlr --csv --implicit-csv-header --headerless-csv-output cut -f 3)
    account=$(echo "${transaction_info}" | mlr --csv --implicit-csv-header --headerless-csv-output cut -f 4)
    amount=$(echo "${transaction_info}" | mlr --csv --implicit-csv-header --headerless-csv-output cut -f 5)

    # Description_account is "<description>,<source account that money came from>"
    # We can use account to figure out which rules file we need to modify
    case "${account}" in
    assets:us:sfcu*)
        dir="./import/sfcu/"
        ;;
    *)
        echo "Unknown source dir for ${account}"
        exit 1
        ;;
    esac

    specific=$(echo $'General Rule\nOne Time Rule (Hyper Specific)' | fzf --header="What kind of rule would you like to create?" --wrap --border --border-label "Resolving Unknowns (${count}) - 2/5")

    base_folder=$(basename ${dir})
    if [[ $specific == "General Rule" ]]; then
        # General workflow
        # Create rules.psv if necessary
        if [ ! -f ${dir}/rules.psv ]; then
            touch ${dir}/rules.psv
            echo "if|account2|comment" >>${dir}/rules.psv
            echo $'\n# Import rules to categorize transactions\ninclude rules.psv' >>${dir}/${base_folder}.rules
            echo "Created ${dir}/rules.psv and added include directive to ${dir}/${base_folder}.rules."
            printf "\e[1;33mNOTE:\e[0m You must add \`rules.psv\` to the extra deps of ${base_folder} in export.hs!\n"
        fi

        regexp=$(
            rules=$(ls ${dir}/*.rules | paste -s -d' ' -)
            RELOAD="reload:rg --color=always --line-number --ignore-case "{q}" ${rules} ${dir}/rules.psv ${dir}/csv || :"
            fzf --header=$'Fine-tune regexp to create import rule.\nSearching in '"${dir}"'/*.rules and '"${dir}"'/csv' \
                --disabled --ansi --wrap \
                --border --border-label "Resolving Unknowns (${count}) - 3/5" \
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
                fzf --header="Choose account money was sent to (prepend : to create new account)" --wrap \
                    --border --border-label "Resolving Unknowns (${count}) - 4/5" \
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
                --wrap --border --border-label "Resolving Unknowns (${count}) - 5/5" \
                --bind "start:$RELOAD" --bind "change:$RELOAD" \
                --bind "enter:accept-or-print-query" |
                cut -d ':' -f2
        )

        echo "${regexp}|${target_account}|${comment}" >>"${dir}/rules.psv"
        echo "Added rule: ${regexp}|${target_account}|${comment} to ${dir}/rules.psv"
    else
        # Specific workflow
        # Get source csv files
        date_format=$(awk '/^date-format/ {$1=""; print substr($0,2)}' ${dir}/${base_folder}.rules)

        if [ -z "$date_format" ]; then
            echo "No date format found in ${dir}/${base_folder}.rules."
            echo "Specifc rules require a date format."
            exit 1
        fi
        converted=$(date -d "$transaction_date" +$date_format 2>/dev/null || date -jf "%Y-%m-%d" "$transaction_date" +$date_format 2>/dev/null)
        amount=$(echo $amount | grep -o '[0-9]*\.[0-9]*')
        matches=$(awk -v x="$converted" -v y="$description" -v z="$account" -v w="$amount" '$0~x && $0~y && $0~z && $0~w {print FILENAME}' ${dir}/csv/*)
        fzf_input=$(echo $matches | xargs -n1 basename | sed 's/\.[^.]*$/.rules/' | tr ' ' '\n')
        selection=$(echo "$fzf_input" | fzf --header="Choose specific rules file to edit." --wrap --border --border-label "Resolving Unknowns (${count}) - 5/5")

        # Now lets choose account
        target_account=$(
            cat /tmp/accounts.txt |
                sort -u |
                fzf --header="Choose account money was sent to (prepend : to create new account)" --wrap \
                    --border --border-label "Resolving Unknowns (${count}) - 3/3" \
                    --bind "enter:accept-or-print-query"
        )
        if [[ $target_account == :* ]]; then
            target_account=$(echo $target_account | sed -e 's/^://')
            echo "Adding new account: ${target_account}"
            echo "${target_account}" >>/tmp/accounts.txt
        fi

        # Add to specific rules file.
        # Create the file if necessary.
        if [ ! -d ${dir}/rules ]; then
            mkdir ${dir}/rules
        fi
        if [ ! -f ${dir}/rules/${selection} ]; then
            touch ${dir}/rules/${selection}
            echo "# Put the include statement at the top of the file, so that the rules that" >>${dir}/rules/${selection}
            echo "# you write below take precedence over the general rules" >>${dir}/rules/${selection}
            echo "include ../${base_folder}.rules" >>${dir}/rules/${selection}
            echo "Created ${dir}/rules/${selection}."
        fi
        csv_file=$(echo $selection | sed 's/\.[^.]*$/.csv/')
        og_line=$(awk -v x="$converted" -v y="$description" -v z="$account" -v w="$amount" '$0~x && $0~y && $0~z && $0~w' ${dir}/csv/${csv_file})
        echo "" >>${dir}/rules/${selection}
        echo "if" >>${dir}/rules/${selection}
        echo $og_line >>${dir}/rules/${selection}
        echo "  account2 ${target_account}" >>${dir}/rules/${selection}
        echo "Added hyper specific rule: ${og_line} to ${dir}/rules/${selection}."
        # Store txnidx to filter out transaction in the next iteration
        echo "\$txnidx == ${txnidx};" >>/tmp/hledger_specific_txns.mlr
    fi
done
