# Plain Text Accounting using Hledger

This is my starter template for tracking my finances. It is based on plain text accounting, which has the following advantages and disadvantages.

- Pros
    - Customization. You can build whatever you want the way you want it.
    - Manual labor gives intimate knowledge of your finances. Although, we try to automate all repetitive tasks away!
    - Privacy.
    - Open Source. Be inspired by other people.
- Cons
    - You need programming experience.
    - Needs a lot of time to set up.
    - If your financial life is very complicated, it might reach its limits.
    - Less fancy pre-built web UIs. `paisa` or `fava` are probably the best ones available.

Before continuing read about [full-fledged-ledger](https://github.com/adept/full-fledged-hledger/wiki/Key-principles-and-practices), which this repo is based on. It will do a good job of motivating you to get started! In case you would like to learn more about plain text accounting or doubly entry accounting, read [Command-line Accounting in Context](https://beancount.github.io/docs/command_line_accounting_in_context.html). Even though the document covers beancount, I really enjoyed reading it.

## Setup

1. Install the necessary CLI tools via `brew`.

```bash
brew bundle
```

2. Install Haskell tooling [GHCup](https://www.haskell.org/ghcup/). I use `cabal` to build executables.

3. Download the latest version from [puffin](https://github.com/siddhantac/puffin?tab=readme-ov-file) if you want a nice TUI.

## Usage & Conventions

The most important commands are saved in the `justfile`. View them using `just -l`.

- Create accounts by running `just add <institution name>`. 
    - Downloaded CSV files will be put into `./import/<institution>/in`.
    - You will have to write conversion scripts (`in2csv` and `csv2journal`) and rule files.
- Generate all reports by running `just generate`.
- Launch the TUI (puffin) by running `just view`.
- Generate a ROI report for a given asset by running `just roi <asset-name> -Y`.
- Journals are split by year. To allow for both `all.journal` and `<year>.journal`s we need to include opening journals and closing journals. For more info check the [guide](https://github.com/adept/full-fledged-hledger/wiki/Getting-full-history-of-the-account#on-the-opening-balances).

## Editor Config

### Nvim

- Install [vim-ledger](https://github.com/ledger/vim-ledger) as a plugin.
- Run :TSInstall ledger to enable nvim-treesitter for hledger.

## Useful Guides

- [full-fledged-ledger](https://github.com/adept/full-fledged-hledger/tree/master)
- [Personal Dashboard](https://memo.barrucadu.co.uk/personal-finance.html)

## Future changes

- Use `Grafana` and `Prometheus` for a dashboard?

