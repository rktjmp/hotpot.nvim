![logo](images/logo.png)

# 🍲 Hotpot - Fennel inside Neovim

> You take this home, throw it in a pot, add some broth, some neovim... baby,
> you got a stew going!
>
> ~ Fennel Programmers (probably)

Hotpot is an on-demand *or* ahead-of-time [Fennel](https://fennel-lang.org/)
compiler plugin for Neovim. Just drop your files in `fnl/*.fnl` and Hotpot does
the cooking for you 🍻. Seamlessly mix and match Fennel and Lua as little or as
much as you want.

Your Fennel code is only compiled when it (or a dependency such as a macro) are
changed and everything is stored in a bytecode cache for super fast startup
time.

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

## TOC

- [Requirements](#requirements)
- [Purpose](#purpose)
- [Install](#install)
- [Setup](#setup)
- [Hotpot API](#api)
- [Commands](#commands)
- [Operator Pending](#operator-pending)
- [Using the API](#using-the-api)
- [Ahead of Time Compilation](#ahead-of-time-compilation)
- [How does Hotpot work?](#how-does-hotpot-work)
- [Windows](#windows)
- [See Also](#see-also)

## Requirements

- Neovim 0.7.2+
- ~~Fanatical devotion to parentheses.~~

## Purpose

Hotpot intends to provide a minimal-setup and unobtrusive fennel compiler, as
well as a set of low level tools for interacting with Fennel code in Neovim if
desired.

It should be frictionless as possible when you want, while providing the
hammers and nails to build something more complex *if* you want to.

It has functions to compile and evaluate Fennel code but it does not provide
keymaps to run those functions, or extensive functions to display the output.
Hotpot provides all the *tools to build* a Fennel REPL but does not *provide
one.* It does not contain pre-provided functions and macros to configure
Neovim with. See [API](#api), [`:h hotpot-api`](doc/hotpot-api.txt) and [using
the API](#using-the-api) for some example keymaps.

As a side effect of managing the `fnl -> lua` compilation process,
Hotpot also maintains a lua bytecode cache which can dramatically
improve your Neovim startup time, even if you write zero lines of
fennel. (See [How does Hotpot work?](#how-does-hotpot-work))


## Install

Hotpot can be installed via any package manager but you may prefer to manually
*install* it and let your package manager *update* it. This allows you to
configure your package manger with Fennel.

You must call `require("hotpot")` before you attempt to require any Fennel
files. If you do not do this manually, Neovim will call it for you but the
order and time that this occurs may be non-deterministic.

If you only want to experiment with Fennel, adding `rktjmp/hotpot.nvim` to your
plugin manager is probably good enough.

<details>
<summary>Automatic Install & Update (Recommended)</summary>

```lua
-- ~/.config/nvim/init.lua

-- This init.lua file will clone hotpot into your plugins directory if
-- it is missing. Do not forget to also add hotpot to your plugin manager
-- or it may uninstall hotpot!

-- Consult your plugin-manager documentation for where it installs plugins.
-- packer.nvim
-- local hotpot_path = vim.fn.stdpath('data') .. '/site/pack/packer/start/hotpot.nvim'
-- paq.nvim
local hotpot_path = vim.fn.stdpath('data') .. '/site/pack/paqs/start/hotpot.nvim'

if vim.fn.empty(vim.fn.glob(hotpot_path)) > 0 then
  print("Could not find hotpot.nvim, cloning new copy to", hotpot_path)
  vim.fn.system({'git', 'clone',
                 'https://github.com/rktjmp/hotpot.nvim', hotpot_path})
  vim.cmd("helptags " .. hotpot_path .. "/doc")
end

-- Enable fnl/ support
require("hotpot")

-- Now you can load fennel code, so you could put the rest of your
-- config in a separate `~/.config/nvim/fnl/my_config.fnl` or
-- `~/.config/nvim/fnl/plugins.fnl`, etc.
require("my_config")
```

</details>

<details>
<summary>Plugin Managers</summary>

```lua
-- example using paq.nvim
require "paq" {
  "rktjmp/hotpot.nvim"
}
```

</details>

<details>
<summary>Want to use an unreleased version of Fennel?</summary>

The `nightly` branch merges Fennel `HEAD` into Hotpot each day.

The main purpose of this is to run the test suite against upcoming releases.
If the test suite fails, the changes will not be merged, so it should be
reasonably stable to use day-to-day.

Because the `nightly` branch's primary purpose is to run tests, there is no
guarantee that it wont be recreated, renamed or force-pushed onto at some point
in the future, which would require you do manually force pull or create a fresh
clone.

For a preview of upcoming Fennel features, you can view the
[changelog](https://git.sr.ht/~technomancy/fennel/tree/main/item/changelog.md).

</details>

<details>
<summary>Windows</summary>

Windows installations may [require additional setup](#windows) depending on
your account privileges.

</details>

## Setup

Hotpot accepts the following configuration options, with defaults as shown.

You do not have to call setup *unless you are altering a default option*.

See `h: hotpot-setup` for more details.

```lua
require("hotpot").setup({
  -- allows you to call `(require :fennel)`.
  -- recommended you enable this unless you have another fennel in your path.
  -- you can always call `(require :hotpot.fennel)`.
  provide_require_fennel = false,
  -- compiler options are passed directly to the fennel compiler, see
  -- fennels own documentation for details.
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
})
```

## API

Hotpot provides a number of functions for evaluating and compiling Fennel code,
including helpers to easily operate on strings, selections and buffers for
example.

For complete details, see [`:h hotpot-api`](doc/hotpot-api.txt) and [Using the
API](#using-the-api).

## Commands

Commands to run snippets of Fennel, similar to Neovim's `:lua` et al commands.

- `:[range]Fnl {expression} -> evaluate range in buffer OR expression`
- `:[range]Fnldo {expression} -> evaluate expression for each line in range`
- `:Fnlfile {file} -> evaluate file`
- `:source {file} -> alias to :Fnlsource`, must be called as `:source
  my-file.fnl` or `:source %` and the given file must be a descendent of a
  `fnl` directory. Will attempt to recompile, recache and reload the given
  file.

## Operator Pending

Hotpot expects the user to specify most maps themselves via the API functions
listed above. It does provide one `<Plug>` mapping for operator-pending eval.

```viml
map <Plug> ghe <Plug>(hotpot-operator-eval)
```

> gheip -> evaluate fennel code in paragraph

## Using the API

As noted above, none of the API functions will display their results on
their own. Because people will have differing wants and needs for how
these tools are used, the interface is left to the user.

At it's most basic, you may simply `print` the results:

**Evaluate and Print Selection**

```lua
vim.api.nvim_set_keymap("v",
                        "<leader>fe",
                        "<cmd>lua print(require('hotpot.api.eval')['eval-selection']())<cr>",
                        {noremap = true, silent = false})
```

**Compile and Print Selection**

(Note: will print `true <luacode>` or `false <errors>`.

```lua
vim.api.nvim_set_keymap("v",
                        "<leader>fc",
                        "<cmd>lua print(require('hotpot.api.compile')['compile-selection']())<cr>",
                        {noremap = true, silent = false})
```

**Compile and Print Buffer**

(Note: will print `true <luacode>` or `false <errors>`.

```lua
vim.api.nvim_set_keymap("n",
                        "<leader>fc",
                        "<cmd>lua print(require('hotpot.api.compile')['compile-buffer'](0))<cr>",
                        {noremap = true, silent = false})
```

**Open Cached Lua file**

```lua
function _G.open_cache()
  local cache_path_fn = require("hotpot.api.cache")["cache-path-for-fnl-file"]
  local fnl_file = vim.fn.expand("%:p")
  local lua_file = cache_path_fn(fnl_file)
  if lua_file then
    vim.cmd(":new " .. lua_file)
  else
    print("No matching cache file for current file")
  end
end

vim.api.nvim_set_kemap("n",
                      "<leader>ff",
                      "<cmd>lua open_cache()<cr>",
                      {noremap = true, silent = false})
```

You can extend this to show results in floating windows, new splits, send via a
HTTP post, pipe to `/dev/null`, etc.

To implement these keymaps in Fennel, the [`pug` and
`vlua` helpers](https://github.com/rktjmp/hotpot.nvim/discussions/6) listed on
the discussion boards may be useful.

## Ahead of Time Compilation

You can compile code ahead of time with the `hotpot.api.make` module, which
currently provides two functions: `build` and `check` (functionally equivalent
`build` but with no changes to disk).

`build` accepts a `source-dir`, an optional `options` table and then a set of
`pattern function` argument pairs. Each `*.fnl` file in `source-dir` is
checked against each `pattern` given, and if any match the `function` is called
with the pattern captures as arguments. The function should return a path to
save the compiled file to, or `nil`.

```fennel
;; build all fnl files inside config dir
(build "~/.config/nvim"
       ;; ~/.config/nvim/fnl/*.fnl -> ~/.config/nvim/lua/*.lua
       "(.+)/fnl/(.+)" 
       (fn [root path {: join-path}] ;; root is the first match, path is the second
         ;; ignore our own macro file (init-macros.fnl is ignored by default)
         (if (not (string.match path "my-macros%.fnl$"))
           ;; join-path automatically uses the os-appropriate path separator
           (join-path root :lua path)))
       ;; config/ftplugins/*.fnl -> config/ftplugins/*.lua
       "(~/.config/nvim/ftplugins/.+)"
       (fn [whole-path] (values whole-path)))
```

See also [`:h hotpot.api.make`](doc/hotpot-api.txt) for all options and examples.

## How does Hotpot work?

Hotpot has three main systems, the lua cache, the bytecode cache and the
module loader.

The lua cache contains our compiled fennel code. When requiring a fennel
module, we must first compile that fennel code into lua, then save the result
to disk. This allows the user to easily view the result of the compilation for
debugging. See `:h hotpot-cache`.

The bytecode cache is a special file (normally called the `index`), loaded
into memory when Neovim starts. It contains the machine readable code for
every module that Neovim has previously loaded. By caching modules in-memory
and in a machine readable format, we can find and resolve modules very quickly
as most of the "heavy lifting" is already done. By maintaining a bytecode
cache we can achieve up to 15x performance increases.

The bytecode cache contains information about when the cache was created for
each module, so any modifications made to the original source files or
dependencies can be detected and reloaded into the cache.

The module loader will find and load lua (or fennel) modules. First it will
search the `index` and then Neovims runtime path for source files that match
the requested module name. If a source file is found, it is compiled to lua
(if needed), then the bytecode is saved to the `index`, then the module is
returned to the user.

As an example, given `require("my.module")` Hotpot will check the following
locations, in order, and return the first match.

- `index`
- `$RUNTIMEPATH/lua/my/module.lua`
- `$RUNTIMEPATH/lua/my/module/init.lua`
- `$RUNTIMEPATH/fnl/my/module.fnl`
- `$RUNTIMEPATH/fnl/my/module/init.fnl`
- `<package.path>/my/module.lua`
- `<package.path>/my/module.fnl`

You can see that it will preference a bytecode cache, then `.lua` files over
`.fnl`, if they exist.

## Windows

Hotpot must be able to create symlinks for some core functionality which
Windows may disallow by default, depending on your account type and Windows
version.

To enable symlink creation without elevated privileges, you may have to enable
"Developer Mode" in your account settings.

See ["Enable your device for
development"](https://docs.microsoft.com/en-us/windows/apps/get-started/enable-your-device-for-development)
and ["Symlinks in Windows
10"](https://blogs.windows.com/windowsdeveloper/2016/12/02/symlinks-windows-10/).

## See Also

- [Zest](https://github.com/tsbohc/zest.nvim) is a small library of functions
  and macros focused on configuring Neovim. Zest is compatible with Hotpot
  when Zest's own compiler is left disabled.
- [Conjure](https://github.com/Olical/conjure) is a *fantastic* REPL tool for
  working with Fennel, as well as other lisps.
- [Aniseed](https://github.com/Olical/aniseed) provides a config compiler, as
  well as including an improved stdlib, specific Neovim ergonomic improvements
  and pre-configured test harness. It's similar to Hotpot but with different
  goals.

## License

Hotpot embeds `fennel.lua`, see `lua/hotpot/fennel.lua` for licensing
information.
