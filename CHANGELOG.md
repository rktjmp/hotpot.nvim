# 🍲 Hotpot Changelog

Breaking changes are in **bold**. Note that the SEMVER MAJOR version is 0, so
breaking changes may occur on minor point releases. Generally breaking changes
to "core" code (things that effect loading and running your code/config) are
avoided but breaking changes to the API (things that might effect your bindings
and auto commands) are treated with less reverence.

## 0.8.1

- Remove compile accidental logging

## 0.8.0

- **Writing macros in *lua* is no longer supported**.
- **Required Neovim version bumped to 0.9.**
- Replaced internal bytecode-index loader with `vim.loader` backed loader.
  - Lua files will only be cached by `vim.loader` if you enable caching via
  `vim.loader.enable`!
- Added support for lua colocation, compiling `dir/mod/fnl` into `dir/mod/lua`.
- Native support for `ftplugin/`.

## 0.7.0

- **Updated to Fennel 1.3.1**, may contain un-intended breaking changes from
  upstream, see Fennels own changelog.

## 0.6.0

- **Updated to Fennel 1.3.0**, may contain un-intended breaking changes from
  upstream, see Fennels own changelog.
- Adjusted "file changed" tracking to use mtime + size for cache invalidation.

## 0.5.3

- Removed viml code from compiler code path so Hotpot has a better chance of
  running outside of neovims main thread. (Doing this requires nvim 0.8+).

## 0.5.2

- Fixed diagnostics inside "macro modules".
- Added `compiler.modules.plugins` and `compiler.macros.plugins` config options
  to support user specified fennel compiler plugins.

## 0.5.1

- Fixed `filename` option persisting between some `api.compile` function calls.
- Added module name guessing to `api.make.build` calls for relative-require
  support.

## 0.5.0

- **Updated to Fennel 1.2.1**, may contain un-intended breaking changes from
  upstream, see Fennels own changelog.

## 0.4.1

- Added traceback wrapper to strip ANSI escape codes from fennel
  compiler output.

## 0.4.0

- **Updated to Fennel 1.2.0**, may contain un-intended breaking changes from
  upstream, see Fennels own changelog.

## 0.3.2

- **Fixed `detach` spelling in `hotpot.api.diagnostics` and `hotpot.api.reflect`**
- Updated `hotpot.api.make.build` and `hotpot.api.make.check` to accept a
  directory or single file as the source argument.
- Fixed passing compiler options to Make API.
- Added experimental optional `how` argument to `hotpot.api.diagnostics.set-options`.

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
