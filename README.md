<div align="center">
<img src="images/logo.png" style="width: 100%" alt="Hotpot Logo"/>
</div>

<!-- panvimdoc-ignore-start -->

# 🍲 Hotpot ![Github Tag Badge](https://img.shields.io/github/v/tag/rktjmp/hotpot.nvim) ![LuaRocks Release Badge](https://img.shields.io/luarocks/v/soup/hotpot.nvim)

> You take this home, throw it in a pot, add some broth, some neovim... baby,
> you got a stew going!
>
> ~ Fennel Programmers (probably)

<!-- panvimdoc-ignore-end -->

<!-- panvimdoc-include-comment

```
dP     dP             dP                       dP
88     88             88                       88
88aaaaa88a .d8888b. d8888P 88d888b. .d8888b. d8888P
88     88  88'  `88   88   88'  `88 88'  `88   88
88     88  88.  .88   88   88.  .88 88.  .88   88
dP     dP  `88888P'   dP   88Y888P' `88888P'   dP
                           88
                           dP

You take this home, throw it in a pot, add some
broth, some neovim...  baby, you got a stew going!

                   ~ Fennel Programmers (probably)
```

# Hotpot

-->

Hotpot is a [Fennel](https://fennel-lang.org/) compiler plugin for Neovim that
allows you to write your Neovim config and plugins in Fennel.

# Version 2

> [!IMPORTANT]
> Hotpot version 2's configuration is incompatible with version 1 (*née*
> version 0). For most users, the migration should be simple, see [migrating
> from version 1](#migrating-from-version-1).
>
> **The most dramatic change to all users is the requirement that all macro
> files must use the extension `.fnlm`.**
>
> If you are unable or do not want to update your configuration, pin your
> plugin manager version to the `v1.0.0` tag.
>
> Version 2 has a simpler configuration, better support for directories such as
> `lsp` as well as improved support working in multiple project directories
> with isolated configuration.
>
> See [Changes from Version 1](#changes-from-version-1)

> [!WARNING]
> Again, The most dramatic change to all users is the requirement that **all macro
> files must use the extension `.fnlm`.**

# Requirements

- Neovim 0.11.6+
  - Probably it works on `~0.10.x+` but it's untested. If you're unable to
    upgrade, you can set `_G.__hotpot_disable_version_check = true` before
    `require('hotpot')`.
- ~~Fanatical devotion to parentheses.~~

# Installation

Install with your package manager.

```lua
-- init.lua
vim.pack.add({
  {src = "https://github.com/rktjmp/hotpot.nvim",
   version = vim.version.range("~2.0.0")}
})
-- then most users will require their "config" module stored in `fnl/config/...`
-- there is no need to call `require("hotpot")`.
require("config")
```


<details>
<summary>Lazy.nvim</summary>

```lua
-- init.lua
local function ensure_installed(plugin, branch)
  local user, repo = string.match(plugin, "(.+)/(.+)")
  local repo_path = vim.fn.stdpath("data") .. "/lazy/" .. repo
  if not (vim.uv or vim.loop).fs_stat(repo_path) then
    vim.notify("Installing " .. plugin .. " " .. branch)
    local repo_url = "https://github.com/" .. plugin .. ".git"
    local out = vim.fn.system({
      "git",
      "clone",
      "--filter=blob:none",
      "--branch=" .. branch,
      repo_url,
      repo_path
    })
    if vim.v.shell_error ~= 0 then
      vim.api.nvim_echo({
        { "Failed to clone " .. plugin .. ":\n", "ErrorMsg" },
        { out, "WarningMsg" },
        { "\nPress any key to exit..." },
      }, true, {})
      vim.fn.getchar()
      os.exit(1)
    end
  end
  return repo_path
end

-- Install hotpot in the same manner as lazy.nvim, into Lazy's own plugin directory.
local lazy_path = ensure_installed("folke/lazy.nvim", "stable")
local hotpot_path = ensure_installed("rktjmp/hotpot.nvim", "v2.0.0")
-- As per Lazy's install instructions, but also include hotpot as
-- we have installed it to lazy.nvim's managed directory outside of Neovim's
-- runtimepath.
vim.opt.runtimepath:prepend({hotpot_path, lazy_path})

-- Important! When using Lazy.nvim you *must* require the hotpot module
-- before Lazy.nvim to ensure the module is loaded into memory prior to
-- lazy.nvim altering neovims behaviour.
require("hotpot")

-- require the rest of your config
require("config")
```

*You must also include Hotpot in your plugins list for Lazy.nvim to correctly manage
updates. You may be able to lazy-load Hotpot by `fnl` and `fnlm` filetype but
this is untested.*

```fennel
;; fnl/config/init.fnl

;; When calling `lazy.setup` you must include hotpots output directory in the
;; `performance.rtp.paths` option. If you have configured your config directory
;; to use `:target :colocate` (which is *not* the default), you may skip this step.
(let [lazy (require :lazy)
      api (require :hotpot.api)
      context (assert (api.context (vim.fn.stdpath :config))]
  (lazy.setup {:performance {:rtp {:paths [(context.locate :destination)]}}))

;; If you wish to use `Hotpot fennel update` to download fennel new versions of
;; fennel from the internet, you will also have to add the `target directory`
;; path, as listed in `:checkhealth hotpot` under the `Hotpot fennel update`
;; section.
```

</details>

# Usage

In general, anything you would put in `lua/` should be put in `fnl/`,
otherwise, put `.fnl` files in the standard runtime directories such as `lsp/`
or `ftplugin/`.

## `~/.config/nvim`

By default, Hotpot stores any compiled `.lua` files in a separate location to
maintain a clean directory tree, so you won't see any `.lua` files.

There is one special exception to the above: **`.config/nvim/init.fnl` will
always compile to `.config/nvim/init.lua`.**

You should be set to begin writing Fennel code by placing `.fnl` files inside
`fnl/` or other runtime directories.

```fennel
;; ~/.config/nvim/fnl/my-config/hello.fnl
(print :hello)
```

```fennel
;; ~/.config/nvim/lsp/my-lang.fnl
(print :setup-some-lsp)
```

To configure some of Hotpot's behaviour such as colocating `.lua`, ignoring
files or configuring the Fennel compiler, see [Configuration](#configuration).

## Plugins

When writing plugins in Fennel, you'll want to ship `.lua` code to users, so we
must "colocate" the `.fnl` and `.lua` files.

To enable Fennel compilation for a plugin, we must place a `.hotpot.fnl` file
in the root of the plugin directory. At a bare minimum, this file must specify
the `schema` and `target` keys, as shown below.

```fennel
;; projects/my-plugin/.hotpot.fnl
{:schema :hotpot/2
 :target :colocate}
```

After creating the `.hotpot.fnl` file, open any `.fnl` file and save it to
trigger a build, or use the `sync` [command](#commands).

See [Configuration](#configuration) for details on customising Hotpot's
behaviour, ignoring files or configuring the Fennel compiler.

## Macros

> [!IMPORTANT]
> Hotpot requires that Fennel macro files **must** use the modern `.fnlm`
> extension. Regular Fennel modules should use the `.fnl` extension.

# Configuration

All of Hotpot's behaviour is configured by a `.hotpot.fnl` file, placed in the
root of your config or plugin directory.

These files are independent of one another and only alter behaviour in the
same tree.

Note that if there is no `.hotpot.fnl` file in Neovim's config directory, a
default configuration is loaded. This is not the case for plugins, which *must*
have a `.hotpot.fnl` file.

```fennel
;; .hotpot.fnl
{
 ;; Required, string, valid: hotpot/2
 ;; Describes expected schema for table.
 :schema :hotpot/2

 ;; Required, string, valid: cache|colocate
 ;; Describes target location of lua files. `cache` places lua files "out of
 ;; tree" in a directory loadable by neovim, `colocate` places lua files "in
 ;; tree", next to their fennel counterparts.
 ;;
 ;; When no `.hotpot.fnl` file is present in your config directory,
 ;; the target defaults to :cache. You may set it to :colocate by adding a
 ;; .hotpot.fnl file.
 ;; Be aware that its the users responsibility to remove previously
 ;; generated lua files when swapping targets in either direction.
 ;;
 ;; For plugins, the only valid value is `colocate`.
 :target :cache

 ;; All other keys are optional.

 ;; Optional, boolean
 ;; If true (default), any single compilation error will prevent any changes
 ;; from being written.
 :atomic? true

 ;; Optional, boolean
 ;; If true (default: false), output messages after every successful
 ;; compilation instead of just on error.
 :verbose? true

 ;; Optional, function
 ;; If provided, all compiled fennel source is passed to the function, along
 ;; with its path, relative to `.hotpot.fnl`. The function must return the
 ;; modified source.
 ;; Transform is not called automatically when using the compile and eval API.
 :transform (fn [src path] src)

 ;; Optional, list of strings
 ;; Glob patterns to ignore when performing compile and clean operations.
 ;;
 ;; Files matching `.lua` patterns are never considered orphans and never removed.
 ;; Files matching `.fnl` patterns are never compiled.
 ;; Files matching `.fnlm` patterns are never considered when performing stale checks.
 :ignore [:some/lib/**/*.lua :junk/*.fnl]

 ;; Optional, table
 ;; Fennel compiler options, passed directly to `fennel.compile-string`.
 ;;
 ;; Hotpot enables strict global checking by default to prevent referencing
 ;; unknown or misspelled variables. To restore Fennel's default
 ;; behaviour, you can set `allowedGlobals` to `false`.
 ;;
 ;; If you wish to reference `vim` in your macros, set `:extra-compiler-env {: vim}`.
 ;;
 ;; Note that `error-pinpoint` is always forced to false and `filename` is
 ;; always set to the correct value.
 ;;
 ;; See Fennel's own API documentation and --help for further details.
 :compiler {:allowedGlobals (icollect [k _ (pairs _G)] k)
            :extra-compiler-env {: vim}
            :error-pinpoint false}
}
```

# API

Hotpot provides an API to compile and evaluate arbitrary Fennel code, as well
as compiling files in a project. All interaction is done via a `context` object.

## `context(path|nil)`

Creates a `context` object. Returns `context` or `nil, error`.

All other API interactions are performed through the `context` object.

```fennel
(let [api (require :hotpot.api)
      ctx (api.context (vim.fn.stdpath :config))]
  (ctx.eval "(+ 1 1)"))
```

`path` may be:

- A path to a file or directory that has a `.hotpot.fnl` in its file tree,
- your Neovim config directory, even if that does not have a `.hotpot.fnl` file,
- or `nil`.

If given a valid path, the `context` is loaded for use. If given `nil`, a
default "api" context is created which does not support some operations that
require disk paths, such as `sync`.

## `context.compile(string, compiler-options)`

Compiles the given string, using the context compiler options. Returns `true,
compiled string` or `false, error`>

Does *not* automatically apply any transform, which can be done manually by
`context.transform` *if one is set for the context*.

## `context.eval(string, compiler-options)`

Evaluates the given string, using the context compiler options. Returns `true,
...evaluated values` or `false, error`.

Does *not* automatically apply any transform, which can be done manually by
`context.transform` *if one is set for the context*.

## `context.sync(options|nil)`

Syncs the context by compiling files in the context. Returns `report table`.

Supports the following options:

- `force?`: force compilation of all files in the context, even if the `.lua` is up to date.
- `atomic?`: allow writing successfully compiled files even if others have compilation errors.
- `verbose?`: output additional compilation messages.
- `compiler`: additional Fennel compiler options.

Not available for "api" contexts, eg: those without any path given.

## `context.transform(string, filename|nil)`

Apply context transform to string, as defined in the context `.hotpot.fnl`. 

Not available if no `transform` has been defined.

## `context.locate(string)`

Convert given path into its counterpart, eg: given a `.fnl` file path inside
the context source, convert it to the `.lua` file path in the context
destination.

Accepts `.fnl` or `.lua` file paths. Will construct paths for files that do not
exist if desired.

# Commands

## `:Hotpot`

The `:Hotpot` command interacts with Hotpot (*surprise!*). It exposes the following subcommands:

### `:Hotpot sync`

Sync a given context's `.fnl` and `.lua` files. This is the same operation that
occurs when you save a `.fnl` or `.fnlm` file.

`:Hotpot sync` supports the following parameters:

- `context=<path>`: sets the context for the command, if not given, the current working directory is used.
- `force`: force compilation of all files in the context, even if the `.lua` is up to date.
- `atomic`: allow writing successfully compiled files even if others have compilation errors.
- `verbose`: output additional compilation messages.

### `:Hotpot watch`

Enable or disable the compile-on-save behaviour.

`:Hotpot watch` supports the following (mutually exclusive) parameters:

- `enable`: enable syncing on save for all contexts in this session.
- `disable`: disable syncing on save for all contexts in this session.

### `:Hotpot fennel`

Update or rollback `fennel.lua` to the latest version from [fennel-lang.org](https://fennel-lang.org).

Requires `curl` to be installed.

> [!IMPORTANT]
> Running this is not without some risk, as an updated version of Fennel *may*
> be incompatible with Hotpot. This is pretty unlikely unless the API to
> evaluate or compile fennel code is changed. If a release is only adding new
> "forms" (eg: `(accumulate ...)`) the update should be safe.

Exposes the following sub commands:

#### `:Hotpot fennel version`

Reports the currently loaded and used version of Fennel.

#### `:Hotpot fennel update`

Supports the following parameters:

- `url=<url>`: use given URL instead of finding the latest from [fennel-lang.org](https://fennel-lang.org).
- `force`: do not ask whether to update.

#### `:Hotpot fennel rollback`

Remove downloaded Fennel file and use version shipped with Hotpot.

## `:Fnl`

Evaluates either the command line provided Fennel, or a range from the current
buffer either specified on the command line or by selection.

This command is analogous to Neovim's built in `:lua` command, and supports the
same `=` output toggle, eg: `:Fnl= (+ 1 2)` will output `3`, where as `:Fnl (+
1 2)` will silently evaluate the code.

## `:Fnlfile {file.fnl}`

Evaluates the given file, also supports `:Fnlfile= file` to output the results.

## `:source {file.fnl}`

Sources given `.fnl` file. See `:h :source`

# Migrating from Version 1

>[!IMPORTANT]
> You **must** change all macro files to use the the `.fnlm` extension. This
> does not require any code changes.

For many users who have not explicitly configured Hotpot, after renaming any
macro files to `.fnlm`, version 2 should work without drama.

If you are using *Lazy.nvim*, you should re-check the
[installation](#installation) instructions to correctly set the `rtp` option.

If you have specifically configured compiler options (via the
`compiler.macros`/`compiler.modules` setup options) or use a `.hotpot.lua`
file, you will need to migrate to a `.hotpot.fnl` file. See
[configuration](#configuration) for details on `.hotpot.fnl`. You no longer
need to provide separate `macros` and `modules` compiler tables. All compiler
options are specified in the `compiler` key in your `.hotpot.fnl` file.

The [API](#api) has been simplified but with simplification, some previously
provided functions have been removed, eg: there is now only `eval(source,
options)`, no `eval-buffer`, `eval-file`, etc.

Previously Hotpot provided in-editor diagnostics. These have been removed in
favour of more complete solutions provided by LSP servers.

# Changes from Version 1

- **No more Just in Time, now an Ahead of Time compiler**
  - Hotpot now compiles all Fennel files that require compiling on save,
    instead of on-demand (i.e. on `require()`). This change was made for better
    compatibility with things such as the `lsp/` runtime directory.
  - You can still "hide" `.lua` files from your config, this is still the default behaviour.
- **Better support for different compiler contexts**
  - `.hotpot.fnl` supports configuring different directories with different
    compiler options and editing files in one plugin directory while your
    current working directory is elsewhere works better.
- **Macro files must use the extension `.fnlm`**
  - This is the modern Fennel way, no concessions are currently made to support
    `init-macros.fnl` filenames.
- **`.hotpot.lua` is now `.hotpot.fnl`**
  - See [configuration](#configuration), most of the same features exist, providing
    direct access to the compiler options, transforming source code and
    including/ignoring files. You can no longer redirect files on a case-by-case
    basis, either all are in cache or colocated (special case for
    `<config>/init.fnl` which is always colocated).
- **Diagnostics (in-editor compiler warnings) removed**
  - LSP (eg: `fennel-language-server`) provides a richer feature set.
- **Configuring Fennel compiler options via `setup()`**
  - Removed, use `.hotpot.fnl` file + `compiler` key *if needed*.
- **`hotpot.api.compile|evaluate_[file|selection|...]`**
  - Simplified and context aware, see [API](#API).
- **Removed `:Fnldo` commands**
  - This seem to have little value personally, if you really do have a use for
    it please open an issue.

# Licenses

Hotpot embeds `fennel.lua`, see `lua/hotpot/fennel.lua` for licensing
information.
