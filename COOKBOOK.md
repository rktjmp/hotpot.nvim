# 🍲 Hotpot Cookbook

## TOC

- [Using Hotpot Reflect](#using-hotpot-reflect)
- [Compiling `ftplugins` and similar](#compiling-ftplugins-and-similar)
- [Ahead of Time Compilation](#ahead-of-time-compilation)
- [Checking your config](#checking-your-config)
- [Using the API](#using-the-api)
- [Included Commands](#Commands)

## Using Hotpot Reflect

<div align="center">
<p align="center">
  <img style="width: 100%" src="images/reflect.svg">
</p>
</div>

*!! The Reflect API is experimental and its shape may change, particularly around
accepting ranges instead of requiring a visual selection and some API terms
such as what a `session` is. !!*

*!! Do NOT run dangerous code (like `(system "rm -rf /")` inside an evaluation
block! You could cause massive damage to your system! !!*

*!! Some plugins (Parinfer) can be quite destructive to the buffer and can cause
marks to be lost or damaged. In this event you can just reselect your range. !!*

Reflect API acts similarly to a REPL environment but instead of entering
statements in a conversational manner, you mark sections of your code and the
API will "reflect" the result to you and update itself as you change your
code.

The basic usage of the API is:

1. Get an output buffer pass it to `attach-output`. A `session-id` is returned.

2. Visually select a region of code and call `attach-input session-id <buf>`
where buf is probably `0` for current buffer.

Note that windowing is not mentioned. The Reflect API leaves general window
management to the user as they can best decide how they wish to structure their
editor - with floating windows, splits above, below, etc. The Reflect API also
does not provide any default bindings.

The following is an example binding setup that will open a new window and
connect the output and inputs with one binding. It tracks the session and only
allows one per-editor session. This code is written verbosely for education and
could be condensed.

```fennel
;; Open session and attach input in one step.
;; Note the complexity here is mostly due to nvim not having an api to create a
;; split window, so we must shuffle some code to create a buf, pair input and output
;; then put that buf inside a window.
(local reflect-session {:id nil :mode :compile})
(fn new-or-attach-reflect []
  (let [reflect (require :hotpot.api.reflect)
        with-session-id (if reflect-session.id
                          (fn [f]
                            ;; session id already exists, so we can just pass
                            ;; it to whatever needs it
                            (f reflect-session.id))
                          (fn [f]
                            ;; session id does not exist, so we need to create
                            ;; an output buffer first then we can pass the
                            ;; session id on, and finally hook up the output
                            ;; buffer to a window
                            (let [buf (api.nvim_create_buf true true)
                                  id (reflect.attach-output buf)]
                              (set reflect-session.id id)
                              (f id)
                              ;; create window, which will forcibly assume focus, swap the buffer
                              ;; to our output buffer and setup an autocommand to drop the session id
                              ;; when the session window is closed.
                              (vim.schedule #(do
                                               (api.nvim_command "botright vnew")
                                               (api.nvim_win_set_buf (api.nvim_get_current_win) buf)
                                               (api.nvim_create_autocmd :BufWipeout
                                                                        {:buffer buf
                                                                         :once true
                                                                         :callback #(set reflect-session.id nil)}))))))]
    ;; we want to set the session mode to our current mode, and attach the
    ;; input buffer once we have a session id
    (with-session-id (fn [session-id]
                       ;; we manually set the mode each time so it is persisted if we close the session.
                       ;; By default `reflect` will use compile mode.
                       (reflect.set-mode session-id reflect-session.mode)
                       (reflect.attach-input session-id 0)))))
(vim.keymap.set :v :hr new-or-attach-reflect)

(fn swap-reflect-mode []
  (let [reflect (require :hotpot.api.reflect)]
    ;; only makes sense to do this when we have a session active
    (when reflect-session.id
      ;; swap held mode
      (if (= reflect-session.mode :compile)
        (set reflect-session.mode :eval)
        (set reflect-session.mode :compile))
      ;; tell session to use new mode
      (reflect.set-mode reflect-session.id reflect-session.mode))))
(vim.keymap.set :n :hx swap-reflect-mode)
```

## Compiling `ftplugins` and similar

Some files in Neovim are not loaded via lua's regular `require` infrastructure
and are instead directly interpreted by Neovim. This includes files inside
`ftplugins`, `colors` and `health`. Because of this, we need another way to
load these files, or convert our fennel to real `.lua` files that Neovim can
work with.

**1. Include a shim file**

Most simply, you can write a small `.lua` file in the offending location and
require your fennel code from there.

```lua
-- in ~/.config/nvim/ftplugins/some-type.lua
-- neovim can find and load this file as normal, and hotpot will
-- load fnl/my-config/ftplugins/some-type.fnl
require("my-config.ftplugins.some-type")
```

```fennel
;; in ~/.config/nvim/fnl/my-config/ftplugins/some-type.fnl
(set-options :for-type)
```

**2. Use AOT Compilation**

See [Ahead of Time Compilation](#ahead-of-time-compilation). `hotpot.api.make`
will wont compile files unless they've been modified, so it's reasonably
performant to include a call in your `init.fnl`, especially if your
`source-dir` argument is tightly focused.

**3. Autocommands**

You can hook into the `FileType` event and try to require a matching file.
This works because Hotpot *can* search `rtp` directories, Neovim just doesn't
tell it to by default.

```fennel
(let [{: nvim_create_autocmd : nvim_create_augroup} vim.api
      au-group (nvim_create_augroup :hotpot-ft {})
      cb #(pcall require (.. :ftplugin. (vim.fn.expand "<amatch>")))]
  (nvim_create_autocmd :FileType {:callback cb :group au-group}))
```

## Ahead of Time Compilation

You can compile code ahead of time with the `hotpot.api.make` module. This can
be used to build fennel plugins for distribution, or if you want to compile
your config.

The module currently provides two functions: `build` and `check` (functionally
equivalent `build` but with no changes to disk).

`build` accepts a `source-dir`, an optional `options` table and then a set of
`pattern function` argument pairs. Each `*.fnl` file in `source-dir` is
checked against each `pattern` given, and if any match the `function` is called
with the pattern captures as arguments. The function should return a path to
save the compiled file to, or `nil`.

For complete documentation, see [`:h hotpot.api.make`](doc/hotpot-api.txt).

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

## Checking your Config

You can use `hotpot.api.make` to check if your whole configuration compiles. As
described above, it provides a `check` function which will report any
compilation errors.

```fennel
(vim.keymap.set :n :<leader>ccc
                #(let [{: check} (require :hotpot.api.make)]
                   (check "~/.config/nvim/" {:force? true}
                          "(.+)/fnl/(.+)"
                          (fn [root part {: join-path}]
                            (if (not (string.find part "macros"))
                              (join-path root :lua part))))))

```

## Using the API

See [`:h hotpot.api`](doc/hotpot-api.txt) a complete listing.

**Whoops, this needs updating!**

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

## Commands

Commands to run snippets of Fennel, similar to Neovim's `:lua` et al commands.

- `:[range]Fnl {expression} -> evaluate range in buffer OR expression`
- `:[range]Fnldo {expression} -> evaluate expression for each line in range`
- `:Fnlfile {file} -> evaluate file`
- `:source {file} -> alias to :Fnlsource`, must be called as `:source
  my-file.fnl` or `:source %` and the given file must be a descendent of a
  `fnl` directory. Will attempt to recompile, recache and reload the given
  file.

Hotpot expects the user to specify most maps themselves via the API functions.
It does provide one `<Plug>` mapping for operator-pending eval.

```viml
map <Plug> ghe <Plug>(hotpot-operator-eval)
```

> gheip -> evaluate fennel code in paragraph

