# 🍲 Hotpot Changelog

Breaking changes are in bold.

## x.x.x

- **Neovim 0.7 required**
- **Improved `x-selection` API selection accuracy.**
  - Now uses `nvim_get_mode`, sometimes bindings set by `whichkey.nvim`
    incorrectly report the current mode, so this is potentially breaking if you
    use a non-standard way to set keys. Keymaps set via `vim.keymap.set` behave
    correctly.
- **`hotpot.api.eval` functions now return `true|false result|error`** for
  symetry with `hotpot.api.compile`.
- **Moved `fnl`, `fnlfile`, `fnldo`, `eval-operator` and `eval-operator-bang`
  to `hotpot.api.command`.**
- Added in-editor diagnostics via `hotpot.api.diagnostics`
  - Enabled automatically in Fennel files. See documentation for details and
    how to disable.
- Added ahead of time compilation via `hotpot.api.make`.

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
