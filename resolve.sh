#!/bin/bash
set -e -o pipefail

cat ./export/*-accounts.txt | sort -u >/tmp/accounts.txt

while true; do
    # Choose one of the unknown transactions' description
    transactions=$(
        cat ./export/*unknown.journal |
            hledger -f - register -I -O csv |
            grep -v ":unknown" |
            grep -v -f <(cat ./import/*/rules.psv | cut -d'|' -f1) |
            mlr --csv cut -f date,description,account,amount
    )
    count=$(echo "${transactions}" | mlr count)
    if [ "$count" == "count=1" ]; then
        echo "No unknown transactions left!"
        exit 0
    fi
    description_account=$(
        echo "${transactions}" |
            fzf --header="Choose transaction" --wrap --border --border-label "Choose Transaction" --tac -d ',' --header-lines=1 --nth 2 |
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

    regexp=$(
        rules=$(paste -s -d ' ' $(ls ${dir}/*.rules))
        RELOAD="reload:rg --color=always --line-number --smart-case {q} ${rules} ${dir}/rules.psv ${dir}/csv || :"
        fzf --header="Searching in ${dir}/*.rules and ${dir}/csv" --disabled --ansi \
            --wrap --border --border-label "Fine-Tune Regex" \
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
                --border --border-label "Choose Account" \
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
        fzf --header="Enter comment (prepend : to inhibit selection)" --disabled --ansi \
            --wrap --border --border-label "Enter optional comment" \
            --bind "start:$RELOAD" --bind "change:$RELOAD" \
            --bind "enter:accept-or-print-query" |
            cut -d ':' -f2
    )

    echo "${regexp}|${target_account}|${comment}" >>"${dir}/rules.psv"
    echo "Added rule: ${regexp}|${target_account}|${comment} to ${dir}/rules.psv"
done
