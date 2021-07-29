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

## Non Goals

Hotpot isn't a library full of functions and macros to configure Neovim with.
Hotpot wants to make it easier for *you* to play with Fennel and write your own
functions and macros. I suggest checking out
[Lume](https://github.com/rxi/lume) as a complementary standard libray.

I wrote Hotpot as a way to learn Fennel, It doesn't intend to provide anything
more than an intermediary layer between Fennel and Lua; to make combining
Fennel and Neovim a litle smoother.

If you want to play with Fennel and maybe write a few macros or helpers, Hotpot
might be for you. If you want a easy out of the box experience with all the
bells and all the whistles, you might want to [look elsewhere](#see-also).

**⚠️ Alpha: Updates may have breaking changes, this is also the first Lisp and
Fennel I've ever written, so it ~~might be~~ is garbage!**

## TOC

- [Requirements](#requirements)
- [Install](#install)
- [Helpers](#helpers)
- [Using with Plugins](#using-with-plugins)
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

-- Pick appropriate path for your package manager

-- packer
-- local hotpot_path = vim.fn.stdpath('data')..'/site/pack/packer/start/hotpot.nvim'

-- paq
-- local hotpot_path = vim.fn.stdpath('data')..'/site/pack/paqs/start/hotpot.nvim'

-- vim-plug
-- local hotpot_path = vim.fn.stdpath('data')..'/site/plugged/hotpot.nvim'

-- You can automatically install hotpot if it is missing (i.e for fresh
-- nvim setups). Don't forget to add hotpot to your package manager or
-- it may uninstall hotpot!

if vim.fn.empty(vim.fn.glob(hotpot_path)) > 0 then
  print("Could not find hotpot.nvim, cloning new copy to", hotpot_path)
  vim.fn.system({'git', 'clone',
                 'https://github.com/rktjmp/hotpot.nvim', hotpot_path})
end

-- If you're using vim-plug, you will have to manually insert hotpot
-- into the runtimepath!
-- vim.opt.runtimepath:append(hotpot_path)

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

See: [vim-plug](#vim-plug), [packer](#packer), [paq](#paq) or [sans package
manager](#npm-no-package-manager)

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

### vim-plug

```viml
" for vim-plug
call plug#begin(g:config.plug_dir)
  Plug 'rktjmp/hotpot.nvim'
call plug#end()
" after end(), our rtp will be set and require('hotpot') will work.

" we probably want todo this **immediately** after plug#end() so
" the resolver is setup asap.
lua require("hotpot")
```

### ~~NPM~~ No Package Manager

- Clone Hotpot somewhere very special to you.
- Add to init.lua:

```lua
vim.opt.runtimepath:append("~/clones/hotpot.nvim")
require("hotpot")
```

## Helpers

Hotpot includes a few helper functions.

Access to Fennel, for any reason:

- `fennel_version()`
  - version of Fennel that is bundled with Hotpot.
- `fennel()`
  - exposes the bundled Fennel (is a function for performance reasons).
- `compile_string(string, options)`
  - exposes Fennel's compiler, returns `{true, lua}` or `{false, errors}`.

Access to cache paths for files or modules:

- `cache_path_for_module(module.name)`
  - returns the path to module, either in the cache (if the module is Fennel
    derived) or the Lua file.
- `cache_path_for_file(path)`
  - expects path to point to a `.fnl` file, returns mirrored `.lua` file from
    cache or nil.

The following functions can aid in learning Fennel:

- `show_buf(n)`
  - compiles given buffer (`0` is current buffer) and prints the resulting Lua.
- `show_selection()`
  - compiles visual selection and prints the resulting Lua.

A binding like the following can be useful:

```lua
vim.api.nvim_set_keymap("v",
                        "<leader>nn",
                        ":lua require('hotpot').show_selection()<cr>",
                        {noremap = true, silent = false})
```

```clojure
(local hotpot (require :hotpot))

(fn maybe-open-cache-file []
  ;; get cache path for current file or dont, idk.
  (match (hotpot.cache-path-for-file (vim.fn.expand "%"))
    nil (print "No matching cache file for current file")
    path (vim.cmd (.. ":new " path))))

(fn maybe-open-module []
  ;; get cache path for input modname.
  (local modname (vim.fn.input "module name: "))
  (match (hotpot.cache-path-for-module modname)
    nil (print "No matching cache file for module")
    path (vim.cmd (.. ":new " path))))

(wk.register {:h {:name "+hotpot"
                   :f  [(.. ":lua " (pug maybe-open-cache-file) "()<cr>")
                        "Open hotpot cache for current fnl file"]
                   :m  [(.. ":lua " (pug maybe-open-module) "()<cr>")
                        "Open hotpot cache for module"]}}
             {:prefix "<leader>"})
```

(See [pug](https://github.com/rktjmp/hotpot.nvim/discussions/6)).

> ⚠️ Lua will cache any modules it has loaded. This means that repeated calls to
> `require(module)` wont show any changes. You can "unload" a module by calling
> `package.loaded[module] = nil`. This is something of a hack, and some state
> may be retained. Unloading `module` **does not** unload `module.submodule`.
>
> Currently Hotpot treats un/reloading modules as out of scope (hint: you can
> `(ipairs package.loaded)`).

## Using with Plugins

While you can write plugins in Fennel and allow Hotpot to load them, shipping a
plugin with an added dependency and setup complexity is maybe not recommended?

That said, it has no issues working with plugins assuming you are able to setup
the module resolver before loading them.

Hotpot may get a small build toolchain in the future to allow hot-code
development that you can bake out to lua for release.

If you want to write a plugin in Fennel, look at the excellent
[Aniseed](#see-also), or simply install the Fennel toolchain yourself.

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

The performance cost is very low after compilation, infact is's nearly
identical to just using Lua (technically there's 2 additional checks on whether
a file exists, but the syscall cost is tiny).

## See Also

If you like Hotpot, you should definitely look into two excellent projects by
the enviously talented Oliver Caldwell:

- [Conjure](https://github.com/Olical/conjure) is a *fantastic* REPL-but-better
  tool for working with Fennel, as well as other lisps.
- [Aniseed](https://github.com/Olical/aniseed) does all that Hotpot does, as
  well as including an improved stdlib, specific Neovim ergonomic improvements
  and pre-configured test harness. It's like Hotpot but better.

Additionally, [Zest](https://github.com/tsbohc/zest.nvim) provides similar
macros and aids, and may be combined with Aniseed.

> Hotpot may be compatible with both projects, it may not be. I think aniseed does
> some trickery in it's compile system that injects some macros. Zest can be
> used with or without Aniseed so I assume it would have no compatibility
> issues.
>
> You may wish to disable Zest or Aniseeds native compilation to let
> hotpot take over.

You may also like to install the Fennel toolchain and setup a "show me the lua"
buffer:

```vim
:e scratch.fnl
:w
:split
:term ls scratch.fnl | entr -sc 'fennel --compile scratch.fnl'
```

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
