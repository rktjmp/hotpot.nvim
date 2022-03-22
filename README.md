![logo](images/logo.png)

# 🍲 Hotpot - Seamless Fennel inside Neovim

> You take this home, throw it in a pot, add some broth, some neovim... baby,
> you got a stew going!
>
> ~ Fennel Programmers (probably)

Hotpot lets you use [Fennel](https://fennel-lang.org/) in Neovim anywhere you
would use Lua. Just drop your files in `fnl/*.fnl` and Hotpot does the cooking
for you 🍻. Seamlessly mix and match Fennel and Lua as little or as much as
you want.

```fennel
;; ~/.config/nvim/fnl/is_neat.fnl
;; some kind of fennel code
(fn [what]
  (print what "is neat!"))
```

```lua
-- and in your lua file
local neat = require('is_neat')
neat("fennel") -- => "fennel is neat!"
```

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
Neovim with. See [API](#api), [`:h hotpot-api`](doc/hotpot.txt) and [using the
API](#using-the-api) for some example keymaps.

As a side effect of managing the `fnl -> lua` compilation process,
Hotpot also maintains a lua bytecode cache which can dramatically
improve your Neovim startup time, even if you write zero lines of
fennel. (See [How does Hotpot work?](#how-does-hotpot-work))

## TOC

- [Requirements](#requirements)
- [Install](#install)
- [Setup](#setup)
- [Hotpot API](#api)
- [Operator Pending](#operator-pending)
- [Using the API](#using-the-api)
- [How does Hotpot work?](#how-does-hotpot-work)
- [See Also](#see-also)

## Requirements

- Neovim 0.6.1+
- ~~Fanatical devotion to parentheses.~~

## Install

Hotpot only needs you to call `require("hotpot")` *before* you attempt to
require any Fennel files.

Hotpot will automatically require itself via `hotpot/plugin/hotpot.vim`
however this may occur later than you would like.

It may be helpful to use a package manager to install and update Hotpot, but
inject it manually as soon as possible, so you can use Fennel to *configure the
package manager*.

Your init.lua file may look like this:

```lua
-- ~/.config/nvim/init.lua

-- packer
-- local hotpot_path = vim.fn.stdpath('data')..'/site/pack/packer/start/hotpot.nvim'
-- paq
-- local hotpot_path = vim.fn.stdpath('data')..'/site/pack/paqs/start/hotpot.nvim'

-- You can automatically install hotpot if it is missing (i.e for fresh nvim setups).
-- Don't forget to add hotpot to your package manager or it may uninstall hotpot!
if vim.fn.empty(vim.fn.glob(hotpot_path)) > 0 then
  print("Could not find hotpot.nvim, cloning new copy to", hotpot_path)
  vim.fn.system({'git', 'clone',
                 'https://github.com/rktjmp/hotpot.nvim', hotpot_path})
  vim.cmd("helptags " .. hotpot_path .. "/doc")
end

-- Bootstrap .fnl support
require("hotpot")

-- Now you can load fennel code, so you could put the rest of your
-- config in a separate `~/.config/nvim/fnl/fenneled_init.fnl` or
-- `~/.config/nvim/fnl/plugins.fnl`, etc.
require("fenneled_init")
```

Generally just remember you must call `require("hotpot")` before you attempt
to `require("a_fnl_module")`. `:scriptnames` and `--startuptime` may help you
diagnose any load order problems, as well as `:h initialization`.

### packer

```lua
return require('packer').startup(function()
  use 'wbthomason/packer.nvim'
  use 'rktjmp/hotpot.nvim'
end)
```

### paq

```lua
require "paq" {
  "rktjmp/hotpot.nvim"
}
```

### Setup

Hotpot accepts the following configuration options, with defaults as shown.

You do not have to call setup *unless you are altering a default option*.

See `h: hotpot-setup` for more details.

```lua
require("hotpot").setup({
  -- injects a loader so you can ergonomically call `(require :fennel)`.
  -- recommended you enable this unless you have another fennel in your path.
  provide_require_fennel = false,
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

Hotpot provides the following API functions, see [`:h
hotpot-api`](doc/hotpot.txt) for detailed documentation.

**Eval Functions**

Evaluate any given Fennel, returns the result of evaluation.

*Does not* automatically print the result!

Available in the `hotpot.api.eval` module.

- `(eval-string string) -> any`
- `(eval-range buf pos pos) -> any`
- `(eval-selection) -> any`
- `(eval-buffer buf) -> any`
- `(eval-file path) -> any`
- `(eval-module modname) -> any`

**Compile Functions**

Compiles any given Fennel, returns the result as a string.

*Does not* compile to cache, instead use `require("modname")`.

Available in the `hotpot.api.compile` module.

- `(compile-string string) -> true luacode | false errors`
- `(compile-range buf pos pos) -> true luacode | false errors`
- `(compile-selection) -> true luacode | false errors`
- `(compile-buffer buf) -> true luacode | false errors`
- `(compile-file path) -> true luacode | false errors`
- `(compile-module modname) -> true luacode | false errors`

**Cache Functions**

Find paths to files in the cache, or remove files from the cache.

Available in the `hotpot.api.cache` module.

- `(cache-path-for-fnl-file path) -> path | nil`
- `(cache-path-for-module modname) -> path | nil`
- `(clear-cache-for-fnl-file path) -> true`
- `(clear-cache-for-module modname) -> true`
- `(clear-cache) -> true`
- `(cache-prefix) -> path`

**Commands**

Commands to run snippets of Fennel, similar to Neovim's `:lua` et al commands.

- `:[range]Fnl {expression} -> evaluate range in buffer OR expression`
- `:[range]Fnldo {expression} -> evaluate expression for each line in range`
- `:Fnlfile {file} -> evaluate file`
- `:source {file} -> alias to :Fnlsource`, must be called as `:source
  my-file.fnl` or `:source %` and the given file must be a descendent of a
  `fnl` directory. Will attempt to recompile, recache and reload the given
  file.

**Other Functions**

*Provisionally spec'd API, consider unstable*

Access to Fennel, available under the `hotpot.api.fennel` module:

- `latest()` returns bundled Fennel, currently always (hopefully) tracks
  latest Fennel release.
  - prefer using `provide_require_fennel` fennel option.

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
- `package.path/my/module.fnl`

You can see that it will preference a bytecode cache, then `.lua` files over
`.fnl`, if they exist.

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
