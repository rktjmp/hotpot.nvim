# 🍲 Hotpot Changelog

## 2.0.6

- Fix `title is nil` errors when using `vim.lsp.status()` and possibly other
  consumers by disabling LSP `$/progress` messages while UX is explored.

## 2.0.5

- Prevent LSP `$/progress` messages from clearing prematurely in Neovim 0.12.

## 2.0.4

- Use correctly resolved path when performing nearest context lookups.
- Remove leftover `vim.print` in command param parser.

## 2.0.3

- Fix hidden `nvim.notify` mesages in Neovim 0.12.
- Show Fennel compiler *warnings* (not *errors*) via `nvim.notify`.

## 2.0.2

- Include missing lua files from 2.0.1.

## 2.0.1

- Fix hidden `:write` event `nvim_echo` report messages in Neovim 0.12.

## 2.0.0

- Ahead of Time compiler instead of Just in Time.
  - Better support for future nvim directories such as `lsp/` that can't
    effectively hook into the `require` framework.
- Added `:Hotpot` command with subcommands:
  - `watch`: enable/disable autocmd that triggers the compiler.
  - `sync`: access `Context.sync`.
  - `fennel update|rollback|version`: update fennel version from online.
- Emit `$/progress` LSP messages when compiling for rendering by plugins such
  as `figet.nvim`.
- **Macro files must use the extension `.fnlm`**
- `.hotpot.fnl` instead of `.hotpot.lua` configuration file.
  - New format, different keys, largely the same functionality.
  - Better support for working in different "contexts" with independent options.
- Reduced API with "context" aware functions.
  - This is the modern Fennel way, no concessions are currently made to support
    `init-macros.fnl` filenames.
- Removed diagnostics provider, instead use external LSP server.
- Removed `setup({...})` options for `.hotpot.fnl`.
  - Provides a consistent single entrypoint to configuration.
- Removed `:Fnldo` command.

## 1.0.0

- No functional changes.

## 0.15.0

- Updated to Fennel 1.6.0, may contain unintended breaking changes from
  upstream, see Fennels own changelog.
- Support macro files with `.fnlm` extension.
- Enable default dot-hotpot support for `.fnlm` macro files.

## 0.14.9

- Disable fennel parser warnings, which are printed to stderr.

## 0.14.8

- Updated to Fennel 1.5.3, may contain unintended breaking changes from
  upstream, see Fennels own changelog.

## 0.14.7

- Fix `:checkhealth hotpot` disk usage report attempting to `size + nil`.

## 0.14.6

- Improve `:checkhealth hotpot` module seacher report when luarocks is present.

## 0.14.5

- Fix diagnostics.disable trying to detach from nil buffer.

## 0.14.4

- Disable Fennel's stderr output (configuration option bugged upstream) when it encounters compiler warnings.

## 0.14.3

- Updated to Fennel 1.5.1, may contain unintended breaking changes from
  upstream, see Fennels own changelog.

## 0.14.2

- Fix support for dashes in runtime plugin paths, eg: `plugin/my-plugin.fnl`.

## 0.14.1

- Disable Fennel's stderr output (temporarily) when it encounters compiler warnings.

## 0.14.0

- **Remove `provide_require_fennel` option**, support for `require("fennel")`
  is now always provided.
- **Always enable diagnostics**. Previously was enabled by default, but only if
  you called `setup()`, now enabled by `require("hotpot")`.
- Add `./fnl` paths to `fennel.path` and `fennel.macro-path` when compiling.

## 0.13.1

- Improve Rocks.nvim compatibility.

## 0.13.0

- Updated to Fennel 1.5.0, may contain unintended breaking changes from
  upstream, see Fennels own changelog.

## 0.12.1

- Fix nvim 0.10.0 health report deprecation warnings.

## 0.12.0

- **`vim.loader.enable()` must be called before requiring hotpot *if you are using `vim.loader`*.**
- Added `:checkhealth hotpot`.
- Added `{silent=true}` option to `api.cache.clear-cache`
- **Changed `api.cache.open-cache` to accept a callback which should accept the
  cache path as its first argument. If no callback is given, the cache path is
  opened in a `vsplit`.**

## 0.11.1

- Updated to Fennel 1.4.2, may contain unintended breaking changes from
  upstream, see Fennels own changelog.

## 0.11.0

- **Updated to Fennel 1.4.1**, may contain unintended breaking changes from
  upstream, see Fennels own changelog.

## 0.10.0

- **Updated to Fennel 1.4.0**, may contain unintended breaking changes from
  upstream, see Fennels own changelog.

## 0.9.7

- Fix diagnostics message match pattern to include "column -1".
- Fix clean key missing from sigil file whitelist.

## 0.9.6

- Fix detecting mod/init.fnl vs mod-init.fnl.
- Pass modname, modpath to compiler plugins, available under ... as per
  normal lua requires.

## 0.9.5

- Add `api.make.auto.build(path, ?opts)` to manually trigger `.hotpot.lua`
  saving a file.
- Add `colocation = true` deprecation message, recommend `build = true`.

## 0.9.4

- Add support for plugin/* after/* indent/*
- Fix recompilation behaviour with ftplugins.
- Fix `.hotpot.lua` clean failing to run when `atomic = true`

## 0.9.3

- Fix "is a macro" indicator passed to preprocessor.
  - Both keys `macro?` and `macro` are supported, but `macro` is currently the
    documented key as it works in both lua and fennel contexts.

## 0.9.2

- Clear Fennels `macros-loaded` table during `api.make` compile calls to ensure
  macro changes are propagated.

## 0.9.1

- Fix ftplugin first-time loading bug

## 0.9.0

- Add support for `.hotpot.lua` file.
  - Specify per-project compiler options, automate build-on-save, see `:h hotpot-cookbook-using-dot-hotpot`.
- **Previous `api.make.build` interface has been deprecated, see `:h hotpot.api.make` for details.**
  - If you are using an `init.fnl` file, you should check the updated
  instructions in the [COOKBOOK](COOKBOOK.md).
- **`api.make.check` has been deprecated, see `dryrun` option for `api.make.build`.**
- **Most `api.*` function signatures have changed to accept `compile-options` as would be given to `setup()`.**
- **Removed some API cache lookup functions.**
  - Added `open-cache(how, opts)` which opens the cache path in neovims directory explorer.

## 0.8.2

- Better support for ftplugins.

## 0.8.1

- Remove compile accidental logging.

## 0.8.0

- **Writing macros in *lua* is no longer supported**.
- **Required Neovim version bumped to 0.9.**
- Replaced internal bytecode-index loader with `vim.loader` backed loader.
  - Lua files will only be cached by `vim.loader` if you enable caching via
  `vim.loader.enable`!
- Added support for lua colocation, compiling `dir/mod/fnl` into `dir/mod/lua`.
- Native support for `ftplugin/`.

## 0.7.0

- **Updated to Fennel 1.3.1**, may contain unintended breaking changes from
  upstream, see Fennels own changelog.

## 0.6.0

- **Updated to Fennel 1.3.0**, may contain unintended breaking changes from
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

- **Updated to Fennel 1.2.1**, may contain unintended breaking changes from
  upstream, see Fennels own changelog.

## 0.4.1

- Added traceback wrapper to strip ANSI escape codes from fennel
  compiler output.

## 0.4.0

- **Updated to Fennel 1.2.0**, may contain unintended breaking changes from
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
