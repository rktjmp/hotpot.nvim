![logo](images/logo.png)

# 🍲 Hotpot - Seemless Fennel inside Neovim

**🚧 Alpha: Updates may have breaking changes, this is also the first Lisp and Fennel I've ever written, so it might be garbage! 🚧**

> You take this home, throw it in a pot, add some broth, some neovim... baby,
> you got a stew going!
>
> ~ Fennel Programmers (probably)

Hotpot lets you use Fennel in Neovim anywhere you would use Lua, just replace
your `.lua` files with `.fnl`. If you squint *really* hard and intentionally
misunderstand some concepts, it *almost* looks like a Fennel JIT for Neovim.
*Almost.*

```clojure
;; ~/.config/nvim/is_neat.fnl
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
compiled module.

Future calls to `require` (including in future Neovim sessions) will skip the
compile step unless it's stale, meaning you only pay the cost once, keeping
your ~~`init.fnl`~~ `init.lua` 🐎 rapido 🐎.

## TOC

- [Requirements](#requirements)
- [Install](#install)
- [Helpers](#helpers)
- [Using with Plugins](#using-with-plugins)
- [How does Hotpot work?](#how-does-hotpot-work)
- [See Also](#see-also)

## Requirements

- Neovim 0.5+ (probably)
- ~~Fanatical devotion to lisp.~~

## Install

See: [vim-plug](#vim-plug), [packer](#packer), [paq](#paq) or [sans package manager](#npm-no-package-manager)

Generally, you want to call `require("hotpot").setup()` as soon as possible,
probaby right after your package manager has configured your runtimepath.

```lua
some_packager {
  'rktjmp/hotpot.nvim'
  ...
}
-- inject hotpot module resolver
require("hotpot").setup()
-- you may now require("some.fnl.module") just as if it were a lua file
```

But installation and usage may vary, depending on the package manager in use, how
your nvim configuration is setup and how you're using Hotpot.

Most importantly, you must inject Hotpot's module resolver before you requre any
`.fnl` file, this may be after your package manager is finished, inbetween or
before it even starts.

Hotpot will automatically run `setup()` when it's loaded but depending on your
package manager that may happen later than you want.

`setup()` is idempotent, so calling it more than once will have no adverse effects.

`:scriptnames` and `--startuptime` may help you diagnose any load order
problems, as well as `:h initialization`.

> **Hint:** you may consider installing Hotpot via your package manager, but
> manually inserting it into your runtimepath ASAP.
>
> See [No Package Manager](#npm-no-package-manager) for information.

### vim-plug

```viml
" for vim-plug
call plug#begin(g:config.plug_dir)
  Plug 'rktjmp/hotpot.nvim'
call plug#end()
" after end(), our rtp will be set and require('hotpot') will work.

" we probably want todo this **immediately** after plug#end() so
" the resolver is setup asap.
lua require("hotpot").setup()
```

### packer

```lua
return require('packer').startup(function()
  use 'wbthomason/packer.nvim'
  -- probaly put high up in your chain
  use {
    'rktjmp/hotpot.nvim',
    -- depending on use, you may be able to call setup() here,
    -- packer says this is "code to run after this plugin is loaded."
    -- but it seems to run before plugin/hotpot.vim (perhaps just barely)
    config = function() require("hotpot").setup() end
  }
end)
-- or just call it here
require("hotpot").setup()
```

### paq

```lua
require "paq" {
  "rktjmp/hotpot.nvim"
}
require("hotspot").setup()
```

### ~~NPM~~ No Package Manager

- Clone Hotpot somewhere very special to you.
- Add to init.lua:

```lua
vim.opt.runtimepath:append("~/path/to/hotpot.nvim")
require("hotpot").setup()
```

You if you are using a package manager to install and update Hotpot, but want to
run `setup` early, you may use a similar approach:

```lua
-- maybe at the very start of init.lua/vim
vim.opt.runtimepath:append("~/path/to/package-manager/hotpot.nvim")
require("hotpot").setup()
-- now you can load fennel code, so you could put the rest of your
-- config in a separate `fenneled_init.fnl`.
require("fenneled_init")
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


## Using with Plugins

While you can write plugins in Fennel and allow Hotpot to load them, shipping a
plugin with an added dependency and setup complexity is maybe not recommended?

That said, it has no issues working with plugins assuming you are able to setup
the module resolver before loading them.

If you want to write a plugin in Fennel, look at the excellent
[Aniseed](#see-also), or simply install the Fennel toolchain yourself.

## How does Hotpot work?

Hotpot prepends itself onto Lua's module finder. When `require("my.module")` is
called, it will first look for a `my/module.fnl` anywhere in `rtp` or
`package.path`.

If a `.fnl` file is found, it will check whether there is a matching `.lua`
file, and will transparently compile the Fennel into Lua if needed, then finally
it will return the module loader back to Lua.

The compiled `.lua` files are stored in Neovims cache directory, under the
`hotpot` subdirectory. You will not see the compiled artefacts among your
`.fnl` files. You can find your cache directory by running `:echo
stdpath("cache)"`.

The performance cost is very low after compilation, infact is's nearly
identical to just using Lua (technically there is one extra search happening,
but the cost is tiny).

## See also

If you like Hotpot, you should definitely look into two excellent projects by
the enviously talented Oliver Caldwell:

- [Aniseed](https://github.com/Olical/aniseed) does all that Hotpot does, as
  well as including an improved stdlib, specific Neovim ergonomic improvements
  and pre-configured test harness. It's like Hotpot but better.
- [Conjure](https://github.com/Olical/conjure) is a *fantastic* REPL-but-better
  tool for working with Fennel, as well as other lisps.

Additionally see [zest.nvim](https://github.com/tsbohc/zest.nvim), which
provides additional macros for configuring Neovim.

You may also like to install the Fennel toolchain and setup a "show me the lua"
buffer:

```vim
:e scratch.fnl
:w
:split
:term ls scratch.fnl | entr -sc 'fennel --compile scratch.fnl'
```

## Licence

Hotpot embeds `fennel.lua`, see `lua/hotpot/fennel.lua` for licencing
information.
