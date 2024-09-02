# Plaintext Accounting using Hledger

Before continuing read about [full-fledged-ledger](https://github.com/adept/full-fledged-hledger/wiki/Key-principles-and-practices).
This Buchhaltung is structured after that.

## Setup

1. Install the necessary CLI tools via `brew`.

```bash
brew bundle
```

2. To work with the Haskell scripts, install [GHCup](https://www.haskell.org/ghcup/). I use `cabal` to build executables.

3. Download the latest version from [puffin](https://github.com/siddhantac/puffin?tab=readme-ov-file) if you want a nice TUI.

## Editor Config

### Nvim

- Install [vim-ledger](https://github.com/ledger/vim-ledger) as a plugin.
- Run :TSInstall ledger to enable nvim-treesitter for hledger.

## Useful Guides

- [setup guide](https://github.com/adept/full-fledged-hledger/tree/master)
- [long use case](https://memo.barrucadu.co.uk/personal-finance.html)

## Future changes

- For now I am sticking with Haskell as the scripting language.
- Use `Grafana` and `Prometheus` for a dashboard?

