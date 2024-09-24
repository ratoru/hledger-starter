default: generate

alias a := add
# Creates the `import` directory structure for an institution.
add institution:
    mkdir -p import/{{ institution }}/in
    mkdir -p import/{{ institution }}/csv
    mkdir -p import/{{ institution }}/journal
    mkdir -p import/{{ institution }}/rules
    touch import/{{ institution }}/in2csv
    chmod +x import/{{ institution }}/in2csv
    touch import/{{ institution }}/{{ institution }}.rules
    echo "#!/bin/bash\nhledger print --rules-file \"./rules/\$(basename \"\$1\" .csv).rules\" -f \"\$1\"" > import/{{ institution }}/csv2journal
    chmod +x import/{{ institution }}/csv2journal

alias g := generate
# Generates all reports.
generate *FLAGS: build
    cabal run export -- -C {{justfile_directory()}}/export -j --color {{FLAGS}}

alias b := build
# Builds Haskell scripts in `export`.
build:
    cabal build

alias v := view
# Explore the journal.
view:
    LEDGER_FILE={{justfile_directory()}}/all.journal ./puffin -cfg puffin-config.json

# Generate ROI report. Use -Y for yearly breakdown.
roi asset *FLAGS:
    hledger roi -f all.journal --investment 'acct:assets:{{asset}} not:acct:equity' --pnl 'acct:virtual:unrealized not:acct:equity' {{FLAGS}}

alias r := resolve
# Work through unknown transactions.
resolve:
    ./resolve.sh
