<div align="center">
<img src="images/logo.png" style="width: 100%" alt="Hotpot Logo"/>
</div>

# 🍲 Hotpot

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

Hotpot is a [Fennel](https://fennel-lang.org/) compiler plugin for Neovim. Just
`(require :my-fennel)` and Hotpot does the rest, recompiling your fennel code
as needed.

```fennel
;; ~/.config/nvim/fnl/is_neat.fnl
;; put your fennel code in fnl/
(fn [what] (print what "is neat!"))
```

```lua
-- and require it like normal in your lua file
local neat = require('is_neat') -- compiled & cached on demand
neat("fennel") -- => "fennel is neat!"
```

<!-- panvimdoc-ignore-start -->

## 🎉 New

- Per-project configuration via `.hotpot.lua`
  - See [`.hotpot.lua`](#dot-hotpot)
- `vim.loader` support
  - Replaces hotpots own bytecode cache, so call `vim.loader.enable()` if you want the
  fastest loading experience.
  - You can still use `vim.loader` without the bytecode cache if desired, you do not
  *have* to call `enable()`.
  - (`vim.loader` is pretty fast without the bytecode cache.)
- `preprocessor` setup option
  - Alter fennel source code before it is compiled, prefix with common imports
  or functions, implement alternative module namespaces wrappers, etc..
  - (Actually existed previously but now is documented).

<!-- panvimdoc-ignore-end -->

<!-- panvimdoc-ignore-start -->

## TOC

- [Requirements](#requirements)
- [Install](#install)
- [Usage](#usage)
- [Cookbook - common questions and usage guides](COOKBOOK.md)
- [Setup](#setup)
- [`.hotpot.lua`](#dot-hotpot)
- [Change Log](CHANGELOG.md)

<!-- panvimdoc-ignore-end -->

# Requirements

- Neovim 0.9.1+
- ~~Fanatical devotion to parentheses.~~

# Getting Started

## Install

All you need to do is install Hotpot and call `require("hotpot")` in your
`init.lua` Neovim configuration file.

First lets setup our `init.lua` file. In this example we use the lazy.nvim
plugin manager, but other plugin manager will follow the same pattern -- likely
without the runtimepath alterations.

```lua
-- ~/.config/nvim/init.lua

-- As per lazy's install instructions
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  })
end

-- Bootstap hotpot into lazy plugin dir if it does not exist yet.
local hotpotpath = vim.fn.stdpath("data") .. "/lazy/hotpot.nvim"
if not vim.loop.fs_stat(hotpotpath) then
  vim.notify("Bootstrapping hotpot.nvim...", vim.log.levels.INFO)
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "--single-branch",
    -- You may with to pin a known version tag with `--branch vX.Y.Z`
    "--branch=v0.8.2",
    "https://github.com/rktjmp/hotpot.nvim.git",
    hotpotpath,
  })
end

-- As per lazy's install instructions, but insert hotpots path at the front
vim.opt.runtimepath:prepend({hotpotpath, lazypath})

require("hotpot") -- optionally you may call require("hotpot").setup(...) here

-- include hotpot as a plugin so lazy will update it
local plugins = {"rktjmp/hotpot.nvim"}
require("lazy").setup(plugins)

-- inclue the rest of your config
require("say-hello")
````

The `say-hello` module would be put in `~/.config/nvim/fnl/say-hello.fnl`:

```fennel
;; ~/.config/nvim/fnl/say-hello.fnl
(print :hello!)
```

<!-- panvimdoc-ignore-start -->

<details>
<summary>Windows</summary>

Windows installations may [require additional setup](#windows) depending on
your account privileges.

</details>

<!-- panvimdoc-ignore-end -->

## Usage

Place all your fennel files under a `fnl` dir, as you would place lua files
under `lua`. This practice extends to other folders outside of your config
directory, such as plugins you may write or install.

With your file in the correct location, you only need to require it like you
would any normal lua module.

```fennel
;; ~/.config/nvim/fnl/is_neat.fnl
;; some kind of fennel code
(fn [what]
  (print what "is neat!"))
```

```lua
-- and in ~/.config/nvim/init.lua
local neat = require('is_neat')
neat("fennel") -- => "fennel is neat!"
```

Hotpot will keep an internal cache of lua code, so you wont see files
cluttering the `lua/` directory.

<!-- panvimdoc-ignore-start -->

You can may want to read the [cookbook](COOKBOOK.md) or see more options in
[setup](#setup).

<!-- panvimdoc-ignore-end -->

<!-- panvimdoc-include-comment

You can may want to read the `:h hotpot-cookbook` or see more options in
[setup](#setup).

-->

# Setup

The `setup()` function may *optionally* be called. `setup()` provides access to
Fennels configuration options as described on
[fennel-lang.org](https://fennel-lang.org) as well as some configuration of
hotpot itself.

**You do not have to call setup unless you are altering a default option.**

```lua
require("hotpot").setup({
  -- provide_require_fennel defaults to disabled to be polite with other
  -- plugins but enabling it is recommended.
  provide_require_fennel = false,
  enable_hotpot_diagnostics = true,
  compiler = {
    -- options passed to fennel.compile for modules, defaults to {}
    modules = {
      -- not default but recommended, align lua lines with fnl source
      -- for more debuggable errors, but less readable lua.
      -- correlate = true
    },
    -- options passed to fennel.compile for macros, defaults as shown
    macros = {
      env = "_COMPILER" -- MUST be set along with any other options
    }
  }
  -- A function that accepts a string of fennel source and a table of
  -- of some information. Can be used to alter fennel code before it is
  -- compiled.
  preprocessor = nil
})
```

- `provide_require_fennel` inserts a `package.preload` function that will load
  Hotpot's copy of fennel when you call `(require :fennel)`. This can be useful
  for ergonomics or for compatibility with libraries that expect Fennel to be in
  `package.path` without having to pay the cost of loading the Fennel compiler
  when its not used.

- `enable_hotpot_diagnostics` enable or disable automatic attachment of
  diagnostics to fennel buffers. See [diagnostics](#diagnostics).

- `compiler.modules` is passed to the Fennel compiler when compiling regular
  module files.

- `compiler.macros` is passed to the Fennel compiler when compiling macro files.
  **Be sure to include `env = "_COMPILER"`** unless you have a good reason not to.

<!-- panvimdoc-include-comment

- `preprocessor` is a function that accepts the fennel source code as a string,
and an table, `{: path : modname : macro?}`.

-->

<!-- panvimdoc-ignore-start -->

- `preprocessor` is a function that accepts the fennel source code as a string,
and an table, `{: path : modname : macro?}`.

<!-- panvimdoc-ignore-end -->

Fennel compiler plugins are supported in two forms, as a table (ie. as
described by Fennels documentation) and as a string which should be a module
name. If your plugin needs access to the "compiler environment" (ie. it uses
special forms such as `(sym)` or `(macroexpand)` not available to "normal"
Fennel code), you should specify the module name and hotpot will load it when
required in the compiler environment.

Note:

- The `filename` compilation option is always set to the appropriate value and
  can not be altered via the setup interface.

- The `modules` and `macros` tables _replace_ the defaults when given,
  they are _not_ merged. Include all options you wish to pass to the
  compiler!

- The `compiler` options are not currently passed to any `api.compile`
  functions and are only applied to Hotpots internal/automatic
  compilation. If you have use for passing options to `api.compile` please
  open an issue.

For a complete list of compiler options, see [Fennels
documentation](http://fennel-lang.org), specifically the API usage section.

# Dot Hotpot

Hotpot can optionally be configured per-project by a `.hotpot.lua` file. This
file should placed in the same directory as the `fnl/` directory in a project.
It should return a lua table, dont forget the `return` keyword!.

```lua
return {
  -- configuration
}
```

When a `.hotpot.lua` file is present, it will clear and override any settings
given to `setup()` for files in that project.

This allows different projects to have different module and macro settings, or
preprocessor functions.

The presence of a `.hotpot.lua` file also enables auto-building if desired,
where Hotpot will compile a project when any fennel file is saved.

*Note: even an empty `.hotpot.lua` file will reset all options to their
defaults!*

*Note: for performance reasons, the file is lua instead of fennel. You can use
the auto-build feature to compile `.hotpot.fnl` to `.hotpot.lua` by adding a
`{".hotpot.fnl", true}` value to the `build` list.*

## Supported Options

### `build`

Specify auto-build instructions for the `.hotpot.lua` directory. When present,
hotpot will build all fennel files in a project when a fennel file is saved.
See also `:h hotpot.api.make.build` for more details.

Supported values are:

- `build = false`, or `build = nil`

Disable auto-building.

- `build = true`

Enable auto-building with a default value that should be applicable to most
usage. The default value skips any file with `macro` in its name and compiles
all other files under `fnl/` to `lua/`, eg:

<!-- panvimdoc-include-comment

Note: due to a bug with the documentation generator, the glob patterns below
       are incorrectly rendered.

They should look like "fnl/**/*macro*.fnl", "fnl/**/*.fnl".

-->

```lua
{{"fnl/**/*macro*.fnl", false},
 {"fnl/**/*.fnl", true}}
```

- `build = {{glob_pattern, boolean_or_function}, ...}` or `build = {{options}, {glob_pattern, boolean_or_function}, ...}`

Each glob pattern is expanded in order and if the boolean value is true, the
file will be compiled, if false, the file will be ignored. If given a function,
the absolute path is passed to the function, the function should return the
desired lua path as a string, or false.

If a file matches multiple glob patterns, only the first value will be used.
This allows earlier, more specific matches to ignore files before broader
matches specify compiled files.

*Glob patterns that begin with `fnl/` are automatically compiled to to `lua/`,
other patterns are compiled in place or should be constructing explicitly by a
function.*

The first element in the list may also specify options to pass to
`hotpot.api.make.build.` such as `verbose` or `dryrun`. See `:h
:hotpot.api.make.build` for more details.

Ex.

<!-- panvimdoc-include-comment

Note: due to a bug with the documentation generator, the glob patterns below
       are incorrectly rendered, see the markdown file for the proper instructions.

They should look like "fnl/**/*macro*.fnl", "fnl/**/*-test.fnl", "fnl/**/*.fnl", "colors/*.fnl".

-->

```lua
build = {
  {verbose = true, atomic = true},
  {"fnl/**/*macro*.fnl", false}, -- dont compile macro files
  {"fnl/**/*-test.fnl", false}, -- dont compile x-test.fnl files
  {"fnl/**/*.fnl", true}, -- compile all other fnl files, automatically becomes lua/**/*.lua
  {"colors/*.fnl", true}, -- compiles colors/x.fnl to colors/x.lua
  {"colors/*.fnl", function(path) return string.gsub(path, "fnl$", "lua") end} -- same as above
}
```

### `clean`

Specify auto-clean instructions for the `.hotpot.lua` directory. When present
Hotpot will remove any unknown files matching the given glob pattern after it
runs an auto-build.

Supported values are:

- `clean = false` or `clean = nil`

Disable auto-cleaning.

- `clean = true`

Enable auto-cleaning with a default value that should be applicable to most
usage. The default value removes all files from `lua/`, eg:

<!-- panvimdoc-include-comment

Note: due to a bug with the documentation generator, the glob patterns below
       are incorrectly rendered, see the markdown file for the proper instructions.

They should look like "lua/**/*.lua".

-->

```lua
{{"lua/**/*.lua", true}}
```

- `clean = {{glob_pattern, boolean}, ...}`

Each glob pattern is expanded in order and if the boolean value is true, the
file will be marked for removal if it is unrecognised (eg: not created by
hotpot during the build step). If the values is false, the file will be
retained.

<!-- panvimdoc-include-comment

Note: due to a bug with the documentation generator, the glob patterns below
       are incorrectly rendered, see the markdown file for the proper instructions.

They should look like "lua/lib/**/*.lua", "lua/**/*.lua".

-->

```lua
clean = {
  {"lua/lib/**/*.lua", false}, -- dont remove lib files
  {"lua/**/*.lua", true}, -- remove anything else
}
```

### `compiler`

The compiler key supports the same values as the `compiler` options you may
pass to `setup()`. See `:h hotpot-setup`.

```lua
compiler = {
  modules = { ... },
  macros = { ... },
  preprocessor = function ... end
}
```

# Diagnostics

Hotpot ships with built in diagnostics feature to show fennel compilation
errors via Neovim diagnostics.

It automatically attaches to buffers with the filetype `fennel` and updates
when ever you leave insert mode or otherwise change the buffer.

"Macro modules" require a special fennel environment. To detect "macro modules",
Hotpot checks if the buffer filename ends in `macro.fnl` or `macros.fnl` which is
common practice. It's not currently possible to enable the macro environment in
other contexts (please open an issue).


# The API

<!-- "the api" instead of "api" so it doesnt generate a dupilcate help tag -->

Hotpot provides a number of functions for evaluating and compiling Fennel code,
including helpers to easily operate on strings, selections and buffers for
example.

See `:h hotpot.api`.

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

# Keymaps

Hotpot expects the user to specify most maps themselves via the API functions (see `:h hotpot.api`).
It does provide one `<Plug>` mapping for operator-pending eval.

`<Plug>(hotpot-operator-eval)`

Enters operator-pending mode and evaluates the Fennel code specified by the
proceeding motion.

```
map <Plug> ghe <Plug>(hotpot-operator-eval)

gheip -> evauate fennel code in paragraph
```

# Module preference

Given the directory structure,

```
mod/fnl/code.fnl
mod/lua/code.lua
```

and a call `(require :code)`, Hotpot will opt to load the lua file instead of
compiling the fennel source and overwriting `mod/lua/code.lua`.

This behaviour exists in case a plugin ships with both code in both the `lua`
and `fnl` directories, but the plugin author has post-processed the compiled
lua code, or is using an incompatible fennel version, etc.

In most cases, such as your config, Hotpot wont create `mod/lua/code.lua` and
you wont run into any issues but it may encounter friction when writing a
plugin in fennel.

<!-- panvimdoc-ignore-start -->

The colocation settings as described in the [cookbook](COOKBOOK.md) settings will
effect this behaviour.

<!-- panvimdoc-ignore-end -->

<!-- panvimdoc-include-comment

The colocation setting as described in `:h hotpot-cookbook` will effect this behaviour

-->

When colocation is enabled and if hotpot is confident it can modify the lua
file it will update it to match the fennel source. Otherwise it may prompt you
before taking action.

# Quirks

- Hotpot will only *compile* fennel files that are found in Neovims RTP. It
will *evaluate* files that are found in luas `package.path`. This is for safety
purposes because it can be unclear where and when its safe to compile or
overwrite `.lua` files. In most usage this wont occur -- files will be found in
the RTP first but it can occur when executing in scratch buffers with the
[api](#api) or via [commands](#commands).

# Windows

Hotpot must be able to create symlinks for some core functionality which
Windows may disallow by default, depending on your account type and Windows
version.

To enable symlink creation without elevated privileges, you may have to enable
"Developer Mode" in your account settings.

See ["Enable your device for
development"](https://docs.microsoft.com/en-us/windows/apps/get-started/enable-your-device-for-development)
and ["Symlinks in Windows
10"](https://blogs.windows.com/windowsdeveloper/2016/12/02/symlinks-windows-10/).

# Licenses

Hotpot embeds `fennel.lua`, see `lua/hotpot/fennel.lua` for licensing
information.
