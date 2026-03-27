<div align="center">
<img src="images/logo.png" style="width: 100%" alt="Hotpot Logo"/>
</div>

# 🍲 Hotpot ![Github Tag Badge](https://img.shields.io/github/v/tag/rktjmp/hotpot.nvim) ![LuaRocks Release Badge](https://img.shields.io/luarocks/v/soup/hotpot.nvim)

<!-- panvimdoc-ignore-start -->

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

-->

Hotpot is a [Fennel](https://fennel-lang.org/) compiler plugin for Neovim that
allows you to write your Neovim config and plugins in Fennel.

# Version 2

> [!IMPORTANT]
> Version 2 of Hotpot has a different configuration style and altered feature
> set. It is incompatible with Version 1. See [Changes from Version
> 1](#changes-from-version-1)

# Requirements

- Neovim 0.11.6+
  - Probably it works on `~0.10.x+` but it's untested. If youre unable to
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

-- Install hotpot in the same manner as lazy, via ensure_installed
local lazy_path = ensure_installed("folke/lazy.nvim", "stable")
local hotpot_path = ensure_installed("rktjmp/hotpot.nvim", "v2.0.0")
-- As per Lazy's install instructions, but also include hotpot as
-- we have installed it to lazy's managed directory outside of nvims
-- runtimepath.
vim.opt.runtimepath:prepend({hotpot_path, lazy_path})

-- Important! When using Lazy.nvim you *must* require hotpot module
-- before lazy to ensure the module is loaded into memory prior to
-- lazy altering neovims behaviour.
require("hotpot")

-- require the rest of your config
require("config")
```

*You must also include hotpot in your plugins list for lazy to correctly manage updates.*

```fnl
;; fnl/config/init.fnl

;; When calling `lazy.setup` you must include hotpots output directory in the
;; `performance.rtp.paths` option. If you have configured your config directory
;; to use `:target :colocate` (which is *not* the default), you may skip this step.
(let [lazy (require :lazy)
      api (require :hotpot.api)
      context (api.context (vim.stdpath :config))]
  (lazy.setup {:performance {:rtp {:paths [context.path.destination]}}))
```

</details>

# Usage

In general, anything you would put in `lua/` should be put in `fnl/`, otherwise
put `.fnl` files in the standard runtime directories such as `lsp/` or
`ftplugin/`.

## `~/.config/nvim`

By default, Hotpot store any compiled `.lua` files in a separate location to
maintain a clean directory tree, so you won't see any `.lua` files, with one
exception: `.config/nvim/init.fnl` will always compile to
`.config/nvim/init.lua`.

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

To configure some of Hotpots behaviour such as colocating `.lua`, ignoring
files or configuring the Fennel compiler, see [Configuration](#configuration).

## Plugins

When writing plugins in Fennel, you'll want to ship `.lua` code to users, so we
must "colocate" the `.fnl` and `.lua` files.

To enable fennel compilation for a plugin, we must place a `.hotpot.fnl` file
in the root of the plugin directory. At a bare minimum, this file must specify
the `schema` and `target` keys, as shown below.

```fnl
;; projects/my-plugin/.hotpot.fnl
{:schema :hotpot/2
 :target :colocate}
```

After creating the `.hotpot.fnl` file, open any `.fnl` file and save it to
trigger a build, or use the `sync` [command](#commands).

See [Configuration](#configuration) for details on customising Hotpots
behaviour, ignoring files or configuring the Fennel compiler.

## Macros

Hotpot requires that fennel macro files **must** use the modern `.fnlm`
extension. Regular fennel modules should use the `.fnl` extension.

# Configuration

All of hotpots behaviour is configured by a `.hotpot.fnl` file, placed in the
root of your config or plugin directory.

These files are independent from one another and only effect behaviour in the
same tree.

Note that if there is no `.hotpot.fnl` file in Neovims config directory, a
default configuration is loaded. This is not the case for plugins, which *must*
have a `.hotpot.fnl` file.

```fennel
{
 ;; Required, string, valid: hotpot/2
 ;; Describes expected schema for table.
 :schema :hotpot/2

 ;; Required, string, valid: cache|colocate
 ;; Describes target location of lua files. `cache` places lua files "out of
 ;; tree" in a directory loadable by neovim, `colocate` places lua files "in
 ;; tree", next to their fennel counterparts.
 ;;
 ;; When no `.hotpot.fnl` file is present, the default value for the `config`
 ;; is `cache`, but may be set to `colocate`.
 ;; Be aware that its the users responsibility to remove previously
 ;; generated lua files when swapping targets.
 ;;
 ;; For plugins, the only valid value is `colocate`.
 :target :cache

 ;; All other keys are optional.

 ;; Optional, boolean
 ;; If true (default), any 1 compilation error will prevent all updated
 ;; files from being written.
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
 ;; unknown or misspelled variables. To restore Fennels default
 ;; behaviour, you can set `allowedGlobals` to `false`.
 ;;
 ;; If you wish to reference `vim` in your macros, you should set the
 ;; `extra-compiler-env` option to `:extra-compiler-env {: vim}`.
 ;;
 ;; Note that `error-pinpoint` is always forced to false and `filename` is
 ;; always set to the correct value.
 ;;
 ;; See Fennels own API documentation and --help for further details.
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

`path` may be:

- A path to a file or directory that has a `.hotpot.fnl` in its file tree,
- your Neovim config directory, even if that does not have a `.hotpot.fnl` file,
- or `nil`.

If given a valid path, the `context` is loaded for use. If given `nil`, a
default "api" context is created with no `sync` ability.

## `context.compile(string)`

Compiles the given string, using the context compiler options. Returns the
`compiled string` or `nil, error`

Does *not* automatically apply any transform, which can be done manually by
`context.transform` *if one is set for the context*.

## `context.eval(string)`

Evaluates the given string, using the context compiler options. Returns the
`evaluated values` or `nil, error`

Does *not* automatically apply any transform, which can be done manually by
`context.transform` *if one is set for the context*.

## `context.sync(options|nil)`

Syncs the context by compiling files in the context. Returns `report table`.

Supports the following options:

- `force: true|false`: compile all files, even if they are up to date.

Not available for "api" contexts, eg: those without any path given.

## `context.transform(string, filename|nil)`

Apply context transform to string, as defined in the context `.hotpot.fnl`. 

Not available if no `transform` has been defined.

# Commands

Hotpot provides 3 commands which behave similarly but not exactly like
Neovims Lua commands (see `:h lua-commands`).

It also allows the `:source` command to work with `.fnl` files.

:[range]Fnl {expression}

: Evaluates {expression} or range

If given form is preceded by `=`, the result is passed through `fennel.view`
and printed. Multiple return values are separated with `, `.

You may also use `=` when providing a range.

If a range and a form is provided, the range is ignored.

```
:Fnl (vim.keymap.set ...) ;; evaluates code, no output
:Fnl (values 99 (+ 1 1)) ;; evaluates code, no output
:Fnl =(values 99 (+ 1 1)) ;; evaluates code, outputs "99, 2"
:Fnl=(+ 1 1) ;; You may omit the space

:'<,'>Fnl ;; evaluates selection in current buffer
:1,10Fnl = ;; evaluate lines 1 to 10 in current buffer, prints output
:'<,'>Fnl= ;; again, the space may be omitted

:'<,'>Fnl (print :hello) ;; prints "hello" (range is ignored)
```

:[range]Fnldo {expression}

: Evaluates {expression} for each line in [range]

The result of the expression replaces each line in turn. Two variables are
available inside {expression}, `line` and `linenr`.

```
:'<,'>Fnldo (string.format "%d: %s" linenr (line:reverse))
=> Prepends line number and reverses the contents of line
```

:Fnlfile {file}

: Evaluates {file}, see also `:h :source`.

```
:Fnlfile %

:Fnlfile my-file.fnl
```

:source {file}

: See `:h :source`

# Changes from Version 1

- **No more Just in Time, now a Ahead of Time compiler**
  - Hotpot now compiles all fennel files that require compiling on save,
    instead of on-demand (i.e. on `require()`). This change was made for better
    compatibility with things such as the `lsp/` runtime directory.
  - You can still "hide" `.lua` files from your config, this is still the default behaviour.
- **Better support for different compiler contexts**
  - `.hotpot.fnl` supports configuring different directories with different
    compiler options and editing files in one plugin directory while the
    current working directory is elsewhere works better.
- **Macro files must use the extension `.fnlm`**
  - This is the modern Fennel way, no concessions are currently made to support
    `init-macros.fnl` filenames.
- **`.hotpot.lua` is now `.hotpot.fnl`**
  - See [configuration](#configuration), most of the same features exist, providing
    direct access to the compiler options, transforming source code and
    including/ignoring files. You can no-longer redirect files on a case-by-case
    basis, either all are in cache or colocated (special case for
    `<config>/init.fnl` which is always colocated).
- **Diagnostics (in-editor compiler warnings) removed**
  - LSP (eg: `fennel-language-server`) provides a richer feature set.
- **Configuring fennel compiler options via `setup()`***
  - Removed, use `.hotpot.fnl` file + `compiler` key *if needed*.
- **`hotpot.api.compile|evaluate_[file|selection|...]`**
  - Simplified and context aware, see [API](#API).

# Licenses

Hotpot embeds `fennel.lua`, see `lua/hotpot/fennel.lua` for licensing
information.
