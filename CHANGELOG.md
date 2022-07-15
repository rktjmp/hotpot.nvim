# 🍲 Hotpot Changelog

Breaking changes are in **bold**.

## 0.3.X

- Updated `hotpot.api.make.build` and `hotpot.api.make.check` to accept a
  directory or single file as the source argument.
- Fixed passing compiler options to Make API.

## 0.3.1

- Added 1.1.0 and 1.2.0 compatible diagnostic line detection.
- Fixed diagnostics failing to attach to additional buffers.
- Added `diagnostics.set-options` to allow overriding compiler options for some
  buffers.

## 0.3.0

- **Neovim 0.7 required**
- **Improved `x-selection` API selection accuracy.**
  - Now uses `nvim_get_mode`, sometimes bindings set by `whichkey.nvim`
    incorrectly report the current mode, so this is potentially breaking if you
    use a non-standard way to set keys. Keymaps set via `vim.keymap.set` behave
    correctly.
- **`hotpot.api.eval` functions now return `true result` or `false error` for
symmetry with `hotpot.api.compile`.**
- **Moved `fnl`, `fnlfile`, `fnldo`, `eval-operator` and `eval-operator-bang`
  to `hotpot.api.command`.**
- Added in-editor diagnostics via `hotpot.api.diagnostics`
  - Enabled automatically in Fennel files. See `:h hotpot.api.diagnostics` for
    details and how to disable.
- Added ahead of time compilation via `hotpot.api.make`.
- Added in-editor repl-like via `hotpot.api.reflect`
  - Mark regions of your code and show the results of the compilation or
    evaluation as you edit. See `:h hotpot.api.reflect` for details.

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
