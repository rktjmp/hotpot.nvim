# 🍲 Hotpot Cookbook

## TOC

- [Using Hotpot Reflect](#using-hotpot-reflect)
- [Diagnostics](#diagnostics)
- [Compiling `ftplugins` and similar](#compiling-ftplugins-and-similar)
- [Ahead of Time Compilation](#ahead-of-time-compilation)
- [Writing `~/.config/nvim/init.lua` in Fennel](#writing-confignviminitlua-in-fennel)
- [Checking your config](#checking-your-config)
- [Using the API](#using-the-api)
- [Included Commands](#Commands)
- [Using `vim` or `os` in macros](#compiler-sandbox)
- [Compiler Plugins](#compiler-plugins)

## Using Hotpot Reflect

<div align="center">
<p align="center">
  <img style="width: 80%" src="images/reflect.svg">
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

## Diagnostics

Hotpot ships with built in diagnostics feature to show fennel compilation
errors via Neovim diagnostics.

It automatically attaches to buffers with the filetype `fennel` and updates
when ever you leave insert mode or otherwise change the buffer.

"Macro modules" require a special fennel environment. To detect "macro modules",
Hotpot checks if the buffer filename ends in `macro.fnl` or `macros.fnl` which is
common practice. It's not currently possible to enable the macro environment in
other contexts (please open an issue).

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
`source-dir` argument is tightly focused or a single path.

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

`build` accepts a `source-path` (directory or file), an optional `options`
table and then a set of `pattern function` argument pairs. Each `*.fnl` file in
`source-dir` is checked against each `pattern` given, and if any match the
`function` is called with the pattern captures as arguments. The function
should return a path to save the compiled file to, or `nil`.

For complete documentation, see [`:h hotpot.api.make`](doc/hotpot-api.txt).

```fennel
;; build all fnl files inside config dir
(build "~/.config/nvim"
       ;; ~/.config/nvim/fnl/*.fnl -> ~/.config/nvim/lua/*.lua
       "(.+)/fnl/(.+)"
       ;; `root` is the first match, `path` is the second.
       ;; "(.+)/fnl/(.+)"
       ;;  ^^^^ root
       ;;           ^^^^ path
       ;; Note that the argument names are not important, you decide
       ;; what to call them, in the order they are captured.
       (fn [root path {: join-path}]
         ;; ignore our own macro file (init-macros.fnl is ignored by default)
         (if (not (string.match path "my-macros%.fnl$"))
           ;; join-path automatically uses the os-appropriate path separator
           (join-path root :lua path)))
       ;; config/ftplugins/*.fnl -> config/ftplugins/*.lua
       "(~/.config/nvim/ftplugins/.+)"
       ;; Note again, we have 1 capture, so only one arg, and since we're not
       ;; manipulating the path we can ignore the helpers table too.
       (fn [whole-path] (values whole-path)))
```

## Writing `~/.config/nvim/init.lua` in Fennel

We can use a combination of the Make API and LibUV to write our main `init.lua`
in Fennel and automatically compile it to loadable lua on save.

```fennel
;; ~/.config/nvim/init.fnl

(fn build-init []
  (let [{: build} (require :hotpot.api.make)
        ;; by default, Fennel wont perform strict global checking when
        ;; compiling but we can force it to check by providing a list
        ;; of allowed global names, this can catch some additional errors in
        ;; this file.
        allowed-globals (icollect [n _ (pairs _G)] n)
        opts {:verbosity 0 ;; set to 1 (or dont inclued the key) to see messages
              :compiler {:modules {:allowedGlobals allowed-globals}}}]
    ;; just pass back the whole path as is
    (build "~/.config/nvim/init.fnl" opts ".+" #(values $1))))

(let [hotpot (require :hotpot)
      setup hotpot.setup
      build hotpot.api.make.build
      uv vim.loop]
  ;; do some configuration stuff
  (setup {:provide_require_fennel true
          :compiler {:modules {:correlate true}
                     :macros {:env :_COMPILER
                              :compilerEnv _G
                              :allowedGlobals false}}})

  ;; watch this file for changes and auto-rebuild on save
  (let [handle (uv.new_fs_event)
        ;; uv wont accept condensed paths
        path (vim.fn.expand "~/.config/nvim/init.fnl")]
    ;; note the vim.schedule call
    (uv.fs_event_start handle path {} #(vim.schedule build-init))
    ;; close the uv handle when we quit nvim
    (vim.api.nvim_create_autocmd :VimLeavePre {:callback #(uv.close handle)})))

(require :the-rest-of-my-config)
```

Finally, we have to manually run this code *once* to generate the new `init.lua`:

- Open `init.fnl`
- Run `:Fnlfile %` to execute the current file and *enable* the file watcher.
  - Note, this will also run any code that is executed by `(require
    :the-rest-of-my-config)`.
- Save the file with `:w` to *run* the file watcher.
  - *This will overwrite your existing `init.lua`!*
- Open `init.lua` to confirm it contains your fennel, compiled into lua.
- Start neovim in a new terminal to confirm the config loading is functioning
  without any errors.

## Using the API

See [`:h hotpot.api`](doc/hotpot-api.txt) a complete listing.

Note: The API modules can be lazy-accessed from `hotpot` and `hotpot.api`

```fennel
(let [hotpot (require :hotpot)
      eval hotpot.api.eval]
  (eval.eval-selection))

(let [api (require :hotpot.api)
      compile api.compile]
  (compile.compile-buffer 0))
```

**Eval & Compile**

Evaluate or compile the `v` selection, or the entire buffer.

```fennel
(fn pecho [ok? ...]
  "nvim_echo vargs, as DiagnosticHint or DiagnosticError depending on ok?"
  (let [{: nvim_echo} vim.api
        {: view} (require :fennel)
        hl (if ok? :DiagnosticHint :DiagnosticError)
        list [...]
        output []]
    ;; TODO: this can be fcollect in fennel 1.2.0)
    (for [i 1 (select :# ...)]
      (table.insert output (-> (. list i)
                               (#(match (type $1)
                                   :table (view $1)
                                   _ (tostring $1)))
                               (.. "\n"))))
    (nvim_echo (icollect [_ l (ipairs output)] [l hl]) true {})))

(vim.keymap.set :n :heb
                #(let [{: eval-buffer} (require :hotpot.api.eval)]
                  (pecho (eval-buffer 0)))
               {:desc "Evaluate entire buffer"})

(vim.keymap.set :v :hes
                #(let [{: eval-selection} (require :hotpot.api.eval)]
                  (pecho (eval-selection)))
               {:desc "Evaluate selection"})

(vim.keymap.set :n :hcb
                #(let [{: compile-buffer} (require :hotpot.api.compile)]
                  (pecho (compile-buffer 0)))
               {:desc "Compile entire buffer"})

(vim.keymap.set :v :hcs
                #(let [{: compile-selection} (require :hotpot.api.compile)]
                  (pecho (compile-selection)))
               {:desc "Compile selection"})
```

**Cache operations**

Open the matching lua file for the current file.

```fennel
(vim.keymap.set :n :hff
                #(let [{: cache-path-for-fnl-file} (require :hotpot.api.cache)]
                   (match (cache-path-for-fnl-file (vim.fn.expand :%:p))
                     path (vim.cmd (.. ":new " path))
                     nil (vim.api.nvim_echo [["No cache file for current file" :WarningMsg]] true {})))
                {:desc "Open compiled lua file for current file"})
```

or with a Telescope searcher:

```fennel
(let [{: find_files} (require :telescope.builtin)
      {: cache-prefix} (require :hotpot.api.cache)]
  (find_files {:cwd (cache-prefix)
               :hidden true}))
```

Open the matching lua file for an arbitrary module.

```fennel
(vim.keymap.set :n :hfm
                #(let [{: cache-path-for-module} (require :hotpot.api.cache)
                       modname (vim.fn.input "module name: ")]
                   (match (cache-path-for-module modname)
                     path (vim.cmd (.. ":new " path))
                     nil (vim.api.nvim_echo [[(.. "No cache file for " modname) :WarningMsg]] true {})))
                {:desc "Open compiled lua file for module"})
```

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


## Compiler Sandbox

Fennel compiles macros in a restricted environment called a sandbox. In this
environment, common lua tables such as `os`, or in Neovim, `vim` are
unavailable.

> Note: this restriction applies to code *executed in* the macro, not code
> *generated by* the macro.

As an example, imagine we want a function that prints the time *of
compilation*, we may write something like this:

```fennel
;; ts-fn.fnl

(macro fn-with-ts [name args body]
  (let [now (os.date :%s)]
    `(fn ,name ,args
      (do
       (print "code generated at" ,now)
       ,body))))

(fn-with-ts my-func [x]
  (print (* x x)))
```

If we try to build this with the Fennel CLI, we get the following error, because
`os` is unavailable:

```
$ fennel -c ts-fn.fnl
Compile error in ts-fn.fnl:2:13
  unknown identifier in strict mode: os

  (let [now (os.date :%s)]
* Try looking to see if there's a typo.
* Try using the _G table instead, eg. _G.os if you really want a global.
* Try moving this code to somewhere that os is in scope.
* Try binding os as a local in the scope of this code.
```

We can disable the compiler sandbox with `--no-compiler-sandbox`, which will
allow us to compile our code:

```
$ fennel --no-compiler-sandbox -c ts-fn.fnl
local function my_func(x)
  print("code generated at", "1665501877")
  return print((x * x))
end
return my_func
```

With this understanding, we can adjust the macro compilation options we provide
to `hotpot.setup`, and then we can use the function inside Neovim:

```lua
-- ...
macros = {
  env = "_COMPILER",
  compilerEnv = _G,
  allowGlobals = false,
}
-- ...
```

For more information on available options, see Fennels own documentation.

## Compiler Plugins

Fennel supports user provided compiler plugins and Hotpot does too. For more
information on compiler plugins, see Fennels own documentation.

Plugins are specified for both `modules` and `macros` and may be provided as a
table (ie. as described by Fennels documentation) or a module name as a string.

When your plugin requires access to the compiler environment or is
uncomfortable to write in lua (which may be the language your using to define
`setup`'s options), specifying the plugin as a string lets you do that.

Compiler plugins are extremely powerful and can let you add new language
constructs to Fennel or modify existing ones but be aware of the impact you
might have on portability and clarity.

Below are two identical plugins which add 1 to every `(+)` call (so `(+ 1 1)`
becomes `(+ 1 1 1)`.

```fennel
;; .config/nvim/fnl/off_by_one.fnl
(fn call [ast scope ...]
  (match ast
    [[:+]] (table.insert ast 1))
  (values nil))

{:name :add_one_module
 :call call
 :versions [:1.2.1]}
```

```lua
off_by_one = {
  name = "add_one_table",
  call = function (ast, scope)
    if ast[1][1] == "+" then
      table.insert(ast, 1)
    end
    return nil
  end,
  versions = {"1.2.1"}
}

require("hotpot").setup({
  compiler = {
    modules = {
      plugins = {
        "off_by_one",
        off_by_one,
      }
    },
    -- you may also define for macros
    -- macros = {
    --   plugins = {...},
    -- },
  }
})
```

<details>
<summary>F͙̖͍͇̤ͣ̅ͯ̕Ō̝̦͎̣̲͖̬̬̌́R̖̮͈ͭ͊̾̈́͘B̢̮̖̊ͧ̃Į̳̘͇̣͖̔͋D̈̑̅͏̟͓̮̰̼̪͈Ď̡̲̠͇͍͓̔E̥̠̱ͫ̋̈̽͢Ņ̹̠̱̮̖̖̝ͣͯ̌ ̠̰̲̗̝̂͞K̶̩̲̖̦̯͕̜̱̃͆ͯ̾Ṉ͔̠̩̗̅̓̈́͢Ǫ̻̳̜̅W̰̩̰̬ͣ͗̕L̽ͦ̂͑҉͇̠E̫͎̝͖͕̰ͣ͡D̖͎͇̔̂ͬ͡G͇͚̩̱̮̹̈́͠E̱̖̯̫̬̫̞͒ͧ͜</summary>

```fennel
;; plugin.fnl

;; must define as function that returns a list
(fn map-seq-fn [seq f]
  `(icollect [_# v# (ipairs ,seq)] (,f v#)))

(fn call [ast scope ...]
  (match ast
    ;; match against symbol and capture arguments
    [[:map-seq] & other]
    ;; written as do for comment clarity
    (do
      ;; expand our macro as compiler would do, passing in capture arguments
      (local macro-ast (map-seq-fn (unpack other)))
      ;; now expand that ast again (this expands icollect etc, *other* macros)
      (local true-ast (macroexpand macro-ast))
      ;; change ast to match macro ast, note that we must
      ;; **modifiy** the ast, not return a new one, as we're
      ;; actually modifying the ast back in the compiler call-site.
      (each [i ex-ast (ipairs true-ast)]
        (tset ast i ex-ast))))
  ;; nil to continue other plugins
  (values nil))

{:name :magic-map-seq
 :call call
 :versions [:1.2.1]}
```

```fennel
;; file.fnl
(map-seq [1 2 3] #(print $)) ;; works by magic
```

</details>
