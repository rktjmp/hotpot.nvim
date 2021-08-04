![logo](images/logo.png)

# 🍲 Hotpot - Seamless Fennel inside Neovim

> You take this home, throw it in a pot, add some broth, some neovim... baby,
> you got a stew going!
>
> ~ Fennel Programmers (probably)

Hotpot lets you use [Fennel](https://fennel-lang.org/) in Neovim anywhere you
would use Lua, just replace your `lua/*.lua` files with `fnl/*.fnl` and Hotpot
does the cooking for you 🍻.

```clojure
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

Hotpot will transparently compile your Fennel code into Lua and then return the
compiled module. Future calls to `require` (including in future Neovim
sessions) will skip the compile step unless it's stale, meaning you only pay
the cost once, keeping your ~~`init.fnl`~~ `init.lua` 🐎 rapido 🐎. Seamlessly
mix and match Fennel and Lua as little or as much as you want.

**Notices**

*2021-08-03*

- :sparkling_heart: New! Bigger and better API, eval Fennel from just about
  anywhere:compass:, or get compiled Lua too. Buffer, selection, files, modules
  or regular plain old zero spice nothing special ijustworkhere string
  literals! :mechanical_arm:

  See [API](#api), [Using the API](#using-the-api) and [`:h
  hotpot-api`](doc/hotpot.txt). :+1:

- :sparkling_heart: New! Commands! `:Fnl` for evaluating parts of
  a buffer or entering expressions right on the command line, `:Fnldo` and
  `:Fnlfile` just like `:lua[do|file]`. Spicy! :hot_pepper:

- :sparkling_heart: New! `doc/hotpot.txt`! Read all about Hotpot in your
  favourite file format... `vimdoc`! :eggplant:

- :sparkling_heart: New! Better error reporting and error handling. Your neovim
  config won't give up if a single module is missing a parentheses! Hotpot
  configs might even be more resilient than normal lua configs! :raised_hands:

  This is an experimental feature, pay attention to errors you see and fix them
  or your session might get wonky! :raised_eyebrow: Post an issue if you see really
  strange behaviour.

- :broken_heart: Gone! `hotpot.compile_string`, `hotpot.show_buf`,
  `hotpot.show_selection`, `hotpot.cache_path_for_module` and
  `hotpot.cache_path_for_file` have been :skull: banished :skull: in favour of
  the more comprehesive `hotpot.api.*` functions.


## Purpose

Hotpot intends to provides a set of low level tools for interacting with Fennel
code in Neovim (see [API](#api), [`:h hotpot-api`](doc/hotpot.txt)). It has
functions to compile and evaluate Fennel code, but provides no keymaps to run
those functions, or methods of displaying the output.

Hotpot provides all the *tools to build* a Fennel REPL but does not *provide
one.*

Hotpot isn't a library full of functions and macros to configure Neovim with.
Hotpot wants to make it easier for *you* to play with Fennel and write your own
functions and macros.

If you want to play with Fennel and maybe write a few macros or helpers, Hotpot
might be for you. If you want a easy out of the box experience with all the
bells and all the whistles, you might want to [look elsewhere](#see-also).

## TOC

- [Requirements](#requirements)
- [Install](#install)
- [Hotpot API](#api)
- [Using the API](#using-the-api)
- [How does Hotpot work?](#how-does-hotpot-work)
- [See Also](#see-also)
- [FAQ & Trouble Shooting](#faq--trouble-shooting)

## Requirements

- Neovim 0.5+ (probably)
- ~~Fanatical devotion to parentheses.~~

## Install

Hotpot only needs you to call `require("hotpot")` *before* you attempt to
require any Fennel files. Hotpot currently has no user configurable options,
there is no `setup()` function.

Hotpot will 🤖 automatically require itself via `hotpot/plugin/hotpot.vim` but
this may occur later than you would like.

Carl Weathers recommends using a package manager to install and update Hotpot,
but manually injecting it as soon as possible, so you can use Fennel to
*configure the package manager* 😙👌.

Your init.lua file may look like this:

```lua
-- ~/.config/nvim/init.lua

-- packer
-- local hotpot_path = vim.fn.stdpath('data')..'/site/pack/packer/start/hotpot.nvim'
-- paq
-- local hotpot_path = vim.fn.stdpath('data')..'/site/pack/paqs/start/hotpot.nvim'

-- You can automatically install hotpot if it is missing (i.e for fresh
-- nvim setups). Don't forget to add hotpot to your package manager or
-- it may uninstall hotpot!
if vim.fn.empty(vim.fn.glob(hotpot_path)) > 0 then
  print("Could not find hotpot.nvim, cloning new copy to", hotpot_path)
  vim.fn.system({'git', 'clone',
                 'https://github.com/rktjmp/hotpot.nvim', hotpot_path})
end

-- Bootstrap .fnl support
require("hotpot")

-- Now you can load fennel code, so you could put the rest of your
-- config in a separate `~/.config/nvim/fnl/fenneled_init.fnl` or 
-- `~/.config/nvim/fnl/plugins.fnl`, etc.
require("fenneled_init")
```

Generally just remember you must call `require("hotpot")` before you attempt to
`require("a_fnl_module")`. `:scriptnames` and `--startuptime` may help you
diagnose any load order problems, as well as `:h initialization`.

> The above instructions should be the most reliable and useful method of
> installing. If you are calling `require("hotpot")` before your starting your
> package manager you do not have to call it afterwards, it is shown in the
> instructions below only for completeness.

### packer

```lua
return require('packer').startup(function()
  use 'wbthomason/packer.nvim'
  -- probaly put high up in your chain
  use {
    'rktjmp/hotpot.nvim',
    -- packer says this is "code to run after this plugin is loaded."
    -- but it seems to run before plugin/hotpot.vim (perhaps just barely)
    config = function() require("hotpot") end
  }
end)
-- or just call it here
require("hotpot")
```

### paq

```lua
require "paq" {
  "rktjmp/hotpot.nvim"
}
require("hotpot")
```

## API

Hotpot provides the following API functions, see [`:h
hotpot-api`](doc/hotpot.txt) for detailed documentation.

**Eval Functions**

Evaluate any given Fennel, returns the result of evaulation.

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

**Log Functions**

Access Hotpot's log file.

Available in the `hotpot.api.log` module.

- `(log-path) -> path | nil`

**Commands**

Commands to run snippets of Fennel, similar to Neovims `:lua` et al commands.

- `:[range]Fnl {expression} -> evaluate range in buffer OR expression` 
- `:[range]Fnldo {expression} -> evaluate expression for each line in range`
- `:Fnlfile {file} -> evaluate file`
- `:source {file} -> alias to :Fnlfile`

**Other Functions**

*Provisionally spec'd API, consider unstable*

- `hotpot.api.fennel.latest() -> embedded fennel library`

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

**Compile and Print Buffer**

(Note: will print `true <luacode>` or `false <errors>`.

```lua
vim.api.nvim_set_keymap("n",
                        "<leader>fc",
                        "<cmd>lua print(require('hotpot.api.compile')['compile-buffer'](0))<cr>",
                        {noremap = true, silent = false})
```

You can extend this to show results in floating windows, new splits, send via a
HTTP post, pipe to `/dev/null`, etc.

To implement these keymaps in Fennel, the [`pug` and
`vlua` helpers](https://github.com/rktjmp/hotpot.nvim/discussions/6) listed on the disussion boards may be useful.

## How does Hotpot work?

Hotpot prepends itself onto Lua's module finder. It has a specific load order,
that mirrors Neovims native process.

Given `require("my.module")` Hotpot will check the following locations, in
order, and return the first match.

- `$RUNTIMEPATH/lua/my/module.lua`
- `$RUNTIMEPATH/lua/my/module/init.lua`
- `$RUNTIMEPATH/fnl/my/module.fnl`
- `$RUNTIMEPATH/fnl/my/module/init.fnl`
- `package.path/my/module.fnl`

You can see that it will preference `.lua` files over `.fnl`, if they exist.
This lets Hotpot play well with plugins written in Fennel that provide a
precompiled source tree (eg: probably 100% of them), as they may have
additional build steps (and they've already done the work).

If a `.fnl` file is found, it will check whether there is a matching `.lua`
file in cache. Hotpot will transparently compile the Fennel into Lua if needed
(when the file is missing, or is stale). Finally it loads and returns the Lua
module.

The compiled `.lua` files are stored in Neovims cache directory, under the
`hotpot` subdirectory. You will not see the compiled artefacts among your
`.fnl` files or in any `.lua` directory.

You can find your cache directory by running `:echo stdpath("cache)"`.

## See Also

I suggest checking out [Lume](https://github.com/rxi/lume) as a complementary
functional standard libray.

[Zest](https://github.com/tsbohc/zest.nvim) is a small library of functions and
macros focused on configuring Neovim. Zest is compatible with Hotpot when Zest's
own compiler is left disabled.

If you like Hotpot, you should definitely look into two excellent projects by
the enviously talented Oliver Caldwell:

- [Conjure](https://github.com/Olical/conjure) is a *fantastic* REPL tool for
  working with Fennel, as well as other lisps.
- [Aniseed](https://github.com/Olical/aniseed) provides a config compiler, as
  well as including an improved stdlib, specific Neovim ergonomic improvements
  and pre-configured test harness. It's similar to Hotpot but with different
  goals.

## FAQ & Trouble Shooting

**attempt to call local 'load_fn'**

Often when I see an error like this it's because I have a unnecessary backslash
in a string.

Fennel (or Lua?) seems to have more robust handing than VimL. Unfortunately I
am not sure I can provide a clearer error as this is all the compiler returns.

As you can see, the final error is in `parse_string` which should give you a
hint as to when you're falling into this trap.

```
Error detected while processing /home/$user/.config/nvim/init.lua:
runtime error: attempt to call local 'load_fn' (a nil value)
stack traceback:
  /home/$user/.../hotpot.nvim/lua/hotpot/fennel.lua:3297: in function 'parse_string'
  /home/$user/.../hotpot.nvim/lua/hotpot/fennel.lua:3376: in function '(for generator)'
  /home/$user/.../hotpot.nvim/lua/hotpot/fennel.lua:2716: in function ?
  [C]: in function 'compile_string'
  ...$user/.../hotpot.nvim/fnl/hotpot/searcher/module.lua:84: in function 'maybe_compile'
  ...$user/.../hotpot.nvim/fnl/hotpot/searcher/module.lua:117: in function '_1_'
  ...$user/.../hotpot.nvim/fnl/hotpot/searcher/module.lua:126: in function ?
  [C]: in function 'require'
  ...e/nvim/hotpot//home/$user/.config/nvim/fnl/init.lua:13: in main chunk
  [C]: in ?
  [C]: in function 'require'
```

## Licence

Hotpot embeds `fennel.lua`, see `lua/hotpot/fennel.lua` for licencing
information.
