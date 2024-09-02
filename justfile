default: generate

alias a := add
# Creates the `import` directory structure for an account.
add account:
    mkdir -p import/{{ account }}/in
    mkdir -p import/{{ account }}/csv
    mkdir -p import/{{ account }}/journal
    touch import/{{ account }}/in2csv
    chmod +x import/{{ account }}/in2csv
    touch import/{{ account }}/{{ account }}.rules
    echo "#!/bin/bash\nhledger print --rules-file {{ account }}.rules -f \"\$1\"" > import/{{ account }}/csv2journal
    chmod +x import/{{ account }}/csv2journal

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
    ./puffin --file all.journal
