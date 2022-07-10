# 🍲 Hotpot Changelog

Breaking changes are in bold.

## x.x.x

- Added ahead of time compilation via `hotpot.api.make`.
- **Improved `x-selection` API selection accuracy.**
  - Now uses `nvim_get_mode` which is sometimes incorrectly reported in keymaps
    set by `whichkey.nvim`, so this is potentially breaking. `vim.keymap.set`
    seems to behave correctly.
- **Moved `fnl`, `fnlfile`, `fnldo`, `eval-operator` and `eval-operator-bang`
  to `hotpot.api.command`.**

## 0.2.5

- Fixed bootstrapping in read-only nix environments.

## 0.2.4

- Fixed windows bytecode cache loading.

## 0.2.3

- Updated to Fennel 1.1.0.

## 0.2.2

- Fixed kebab-case file loading.

## 0.2.1

- Loading performance improvement.

## 0.2.0

- **Neovim 0.6 required**.
  - `0.1.0` was the last Neovim 0.5 compatible release.
- Added lua bytecode cache.
- 🪟 Added windows support.
- Localised all `require` calls for performance improvements.

## 0.1.0

- Updated to Fennel 1.0.0.

## 0.0.0

- ✨ Initial release.
