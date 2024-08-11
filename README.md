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

## TOC

- [Requirements](#requirements)
- [Install](#install)
- [Usage](#usage)
- [Cookbook - common questions and usage guides](COOKBOOK.md)
- [Writing Plugins](COOKBOOK.md#writing-plugins)
- [Setup](#setup)
- [API](API.md)
- [Change Log](CHANGELOG.md)

<!-- panvimdoc-ignore-end -->

# Requirements

- Neovim 0.9.1+
- ~~Fanatical devotion to parentheses.~~

# Install

All you need to do is install Hotpot and call `require("hotpot")` before you
try to run any Fennel code.

<details>
<summary>Installing via Lazy.nvim or similar</summary>

```lua
-- ~/.config/nvim/init.lua
-- Ensure lazy and hotpot are always installed
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
local lazy_path = ensure_installed("folke/lazy.nvim", "stable")
local hotpot_path = ensure_installed("rktjmp/hotpot.nvim", "v0.13.1")
-- As per Lazy's install instructions, but also include hotpot
vim.opt.runtimepath:prepend({hotpot_path, lazy_path})

-- You must call vim.loader.enable() before requiring hotpot unless you are
-- passing {performance = {cache = false}} to Lazy.
vim.loader.enable()

require("hotpot") -- Optionally you may call require("hotpot").setup(...) here

-- You must include Hotpot in your plugin list for it to function correctly.
-- If you want to use Lazy's "structured" style, see the next code sample.
local plugins = {"rktjmp/hotpot.nvim"}
require("lazy").setup(plugins)

-- Include the rest of your config. Your call to Lazy.setup does not have
-- to be done in init.lua and could be in a required file.
require("say-hello")
```

The `say-hello` module would be put in `~/.config/nvim/fnl/say-hello.fnl`:

```fennel
;; ~/.config/nvim/fnl/say-hello.fnl
(print :hello!)
```

**"Structured Setup"**

Lazy.nvim allows you to separate your plugin specs into individual files and
folders, but to support this it must be able to find the raw lua files.

We can instruct Hotpot to compile your Fennel code ahead of time, into a
directory Lazy can find (eg: `lua/`).

First we must define a `.hotpot.lua` file at the root of `~/.config/nvim`. See
the documenation for additional details on "dot-hotpot".

```lua
-- ~/.config/nvim/.hotpot.lua

-- By default, the Fennel compiler wont complain if unknown variables are
-- referenced, we can force a compiler error so we don't try to run faulty code.
local allowed_globals = {}
for key, _ in pairs(_G) do
  table.insert(allowed_globals, key)
end

return {
  -- by default, build all fnl/ files into lua/
  build = true,
  -- remove stale lua/ files
  clean = true,
  compiler = {
    modules = {
      -- enforce unknown variable errors
      allowedGlobals = allowed_globals
    }
  }
}
```

Now open a `.fnl` file and save it, you should now have a populated `lua/`
directory and can pass the appropriate module to Lazy.

```lua
-- .config/nvim/init.lua

-- ...

-- See Lazy's own documentation for details.
require("lazy").setup({spec = {import = "plugins"}})
```

<details>
<summary>Hiding `lua/` when using `.hotpot.lua`</summary>

We can compile our lua to a hidden directory, and then add that directory to
Neovims RTP via Lazy's configuration.

```lua
-- ~/.config/nvim/.hotpot.lua
local allowed_globals = {}
for key, _ in pairs(_G) do
  table.insert(allowed_globals, key)
end

return {
  build = {
    {atomic = true, verbose = true},
    {"fnl/**/*macro*.fnl", false},
    -- put all lua files inside `.compiled/lua`, note we must still name the
    -- final directory lua/, due to how nvims RTP works.
    {"fnl/**/*.fnl", function(path)
      -- ~/.config/nvim/fnl/hello/there.fnl -> ~/.config/nvim/.compiled/lua/hello/there.lua
      return string.gsub(path, "/fnl/", "/.compiled/lua/")
    end},
    -- You may also compile a init.fnl file to init.lua
    {"init.fnl", true}
  },
  clean = {{".compiled/lua/**/*.lua", true}},
  compiler = {
    modules = {
      allowedGlobals = allowed_globals
    }
  }
}
```


```fennel
;; When calling Lazy setup, pass the hidden directory as an additional RTP patho
;; Note that the path here *does not* include `/lua`!
(setup {:performance {:rtp {:paths [(.. (vim.fn.stdpath :config) "/.compiled")}}
        :spec { ... }})
```

</details>

</details>


<details>
<summary>Installing via MiniDeps</summary>

```lua
-- ~/.config/nvim/init.lua
local path_package = vim.fn.stdpath('data') .. '/site/'
local function ensure_installed(plugin, branch)
  local user, repo = string.match(plugin, "(.+)/(.+)")
  local repo_path = path_package .. 'pack/deps/start/' .. repo
  if not (vim.uv or vim.loop).fs_stat(repo_path) then
    vim.notify("Installing " .. plugin .. " " .. branch)
    local repo_url = "https://github.com/" .. plugin
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
    vim.cmd('packadd ' .. repo .. ' | helptags ALL')
    vim.cmd('echo "Installed `' .. repo ..'`" | redraw')
  end
end

ensure_installed("echasnovski/mini.nvim", "stable")
ensure_installed("rktjmp/hotpot.nvim", "v0.13.1")

require("hotpot") -- Optionally you may call require("hotpot").setup(...) here

require("mini.deps").setup({path = {package = path_package}})
MiniDeps.add({source = "echasnovski/mini.nvim", checkout = "stable"})
MiniDeps.add({source = "rktjmp/hotpot.nvim", checkout = "v0.13.1"})

-- Include the rest of your config
require("say-hello")
```

The `say-hello` module would be put in `~/.config/nvim/fnl/say-hello.fnl`:

```fennel
;; ~/.config/nvim/fnl/say-hello.fnl
(print :hello!)
```

</details>

<details>
<summary>Installing via Rocks.nvim</summary>

Install via the `Rocks` command or editing `rocks.toml`.

```viml
:Rocks install hotpot.nvim
```

Now update your `init.lua` file to call `require("hotpot")` and include the
rest of your config.

```lua
-- ~/.config/nvim/init.lua
-- Likely you will have some code to ensure Rocks.nvim is installed here
-- ...

require("hotpot") -- optionally you may call require("hotpot").setup(...) here

-- Include the rest of your config
require("say-hello")
````

The `say-hello` module would be put in `~/.config/nvim/fnl/say-hello.fnl`:

```fennel
;; ~/.config/nvim/fnl/say-hello.fnl
(print :hello!)
```

</details>

# Usage

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

Hotpot will keep an internal cache of lua code, so you won't see files
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
  provide_require_fennel = true,
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
    },
    -- A function that accepts a string of fennel source and a table of
    -- of some information. Can be used to alter fennel code before it is
    -- compiled.
    preprocessor = nil
  }
})
```

- `provide_require_fennel` inserts a `package.preload` function that will load
  Hotpot's copy of fennel when you call `(require :fennel)`.

- `enable_hotpot_diagnostics` enable or disable automatic attachment of
  diagnostics to fennel buffers. See [diagnostics](#diagnostics).

- `compiler.modules` is passed to the Fennel compiler when compiling regular
  module files.

- `compiler.macros` is passed to the Fennel compiler when compiling macro files.
  **Be sure to include `env = "_COMPILER"`** unless you have a good reason not to.

- `compiler.preprocessor` is a function that accepts the fennel source code as a string,
  and a table, `{: path : modname : macro}`.

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

# dot-hotpot

Hotpot can optionally be configured to build `lua/` directories on-save with
per-project settings by using a `.hotpot.lua` file.

<!-- panvimdoc-ignore-start -->

See [`:h hotpot-cookbook-using-dot-hotpot`](COOKBOOK.md#using-dot-hotpot) in
the COOKBOOK.

<!-- panvimdoc-ignore-end -->

<!-- panvimdoc-include-comment

See `:h hotpot-cookbook-using-dot-hotpot` for a usage guide.

-->

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

<!-- panvimdoc-ignore-start -->

See [`:h hotpot.api`](API.md).

<!-- panvimdoc-ignore-end -->

<!-- panvimdoc-include-comment

See `:h hotpot.api`.

-->

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

In most cases, such as your config, Hotpot won't create `mod/lua/code.lua` and
you won't run into any issues but it may encounter friction when writing a
plugin in fennel.

# Quirks

- Hotpot will only *compile* fennel files that are found in Neovims RTP. It
will *evaluate* files that are found in luas `package.path`. This is for safety
purposes because it can be unclear where and when its safe to compile or
overwrite `.lua` files. In most usage this won't occur -- files will be found in
the RTP first but it can occur when executing in scratch buffers with the
[api](#api) or via [commands](#commands).

# Licenses

Hotpot embeds `fennel.lua`, see `lua/hotpot/fennel.lua` for licensing
information.
