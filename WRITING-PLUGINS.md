# Writing Neovim Plugins in Fennel with Hotpot

Writing a Neovim plugin with Hotpot is not much different to writing a regular
lua plugin.

With `hotpot.api.make` you can easily build and distribute a plugin with both
`lua/` and `fnl/` directories or in some cases, perhaps for private plugins,
you may prefer to only include a `fnl/` folder and list Hotpot or another
Fennel loader as a requirement.

# The Caveat

The only caveat to be aware of is that **Hotpot will prefer to load `.lua`
files over `.fnl` files for any given module**.

Hotpot assumes that if `module.lua` exists, *it exists for a reason* and should
always be loaded instead of `module.fnl` (if it exists). This allows for
additional processing steps between `fnl -> lua` which an end user may prefer
to do.

As an effect of this, when developing plugins you will have to:

- Delete the `lua/` folder while working and rebuild it when distributing a new
  release. You could also delete individual modules if that were more
  appropriate.

- Or, rebuild the `lua/` folder each time you wish to load a new version of the
  plugin.

- Or, as outlined above, just never build `lua` source files and use a Fennel
  runtime to load the plugin.

# Building `lua/` for distribution

`hotpot.api.make` can be used to populate the standard `lua/` folder for
distribution.

As an example, you may write a `make.fnl` file in your plugin directory:

```
my-plugin.nvim/
  fnl/
   <files...>
  make.fnl
```

```fennel
;; my-plugin.nvim/make.fnl
(let [{: build} (require :hotpot.api.make)
      ;; we'll force building every file each time and
      ;; raise an error if any files don't compile
      (oks errs) (build "./fnl" {:force? true :atomic? true}
                        "./fnl/(.+)" (fn [p {: join-path}] (join-path :./lua p)))]
  (values nil))
```

Then you may run this by `:Fnlfile make.fnl`. You may prefer to bind this to a
key or command, or setup a libuv fsevent watcher to run it automatically on save.

See the documentation via `:h hotpot.api.make` and
[rktjmp/paperplanes.nvim](https://github.com/rktjmp/paperplanes.nvim) or
[rktjmp/highlight-current-n.nvim](https://github.com/rktjmp/highlight-current-n.nvim)
for example plugins using this system.
