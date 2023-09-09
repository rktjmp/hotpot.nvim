# Hotpot Cookbook

<!-- panvimdoc-ignore-start -->

## I want to...

- [Include some common functions, macros or prelude in all files.](#preprocessing)
- [Write a plugin in fennel.](#writing-a-plugin)
- [Compile into the `lua/` directory.](#compiling-to-lua)
- [Use a `.hotpot.lua` file.](#using-dot-hotpot)
- [Write `init.lua` as `init.fnl`.](#writing-confignviminitlua-in-fennel)
- [Write an config `ftplugin`.](#write-an-ftplugin)
- [View compiled lua output.](#cache-operations)

<!--

- See the output of
  - a fennel file or,
  - some arbitary fennel code.
-->

<!-- panvimdoc-ignore-end -->


## Preprocessing

You may set the `hotpot.setup({preprocessing = ...})` option to a function that
receives the source code to be compiled and returns it with any alterations.

The function receives the following arguments:

- The fennel source code to be compiled, as a string.
- A table containing:
  - `path`: the path of the file being compiled,
  - `modname`: the name of the module being compiled and
  - `macro?`: a boolean indicating whether the file is being compiled as a macro or not.

The function must return the source code to compile.

Note that in some contexts, `path` and `modname` may be nil, such as when
running fennel code via the API. It's recommended you check the path strictly.

Ex.

```fennel
(fn [src {: path : modname : macro?}]
  (if (and path modname (path:match "config/nvim"))
    (let [head (-> (table.concat ["(import-macros {: defmodule} :my.macros)"
                                  "(defmodule %s"] :\n)
                   (string.format modname))
          tail ")"]
      (.. head src tail))
    ;; remember to return the source in other cases
    (values src)))
```

## Writing a plugin

Assuming that you wish to distribute your plugin without requiring a Fennel
loader as a dependency, you can use [a `.hotpot.lua` file](#using-dot-hotpot)
to build your plugin.

Most plugins will only need to enable the default `build` and `clean` values,
which will automatically convert all `fnl/` files to `lua/` except when they
have "macro" in their filename.

Be aware that any settings passed to `setup()` are *not* inherited in the
project directory and must respecified in the `.hotpot.lua` file.

```lua
-- ~/projects/plugin.nvim/.hotpot.lua
return {
  build = true,
  -- clean = true
}
```

By default, Fennels compiler wont show an error if you try to reference unknown
symbols. You may prefer to enforce a known list so your builds get "hard
errors":

```lua
local allowed_globals = {}
for key, _ in pairs(_G) do
  table.insert(allowed_globals, key)
end

return {
  compiler = {
    modules = {
      allowedGlobals = allowed_globals
    }
  },
  -- ...
}
```

For more details, see [Using `.hotpot.lua`](#using-dot-hotpot).

## Compiling to `lua/`

See both [using a `.hotpot.lua` file](#using-dot-hotpot) and [writing a
plugin](#writing-a-plugin) for automated processing, or `:h hotpot.api.make`
for manual control.

## Using Dot Hotpot

Hotpot can optionally be configured per-project/directory by a `.hotpot.lua`
file.

This adds support for:

  - Defining fennel to lua build rules via glob patterns.
  - Automatically building and cleaning lua targets on save.
  - Alternative compiler settings per project than those passed to `setup()`.

<!-- panvimdoc-ignore-start -->

`.hotpot.lua` wraps functionality exposed by
[`hotpot.api.make`](API.md#hotpotapimake), you can also manually invoke the
automake system by calling [`
hotpot.api.make.auto.build`](API.md#hotpotapimakeautobuild).

<!-- panvimdoc-ignore-end -->

<!-- panvimdoc-include-comment

`.hotpot.lua` wraps functionality exposed by `:h hotpot.api.make`, you can also
manually invoke the automake system by calling `:h
hotpot.api.make.auto.build`.

-->

> `.hotpot.lua` is intended for plugin developers, but you can apply the same
> practices to your main Neovim config if you want to generate `lua/` files
> or others such as `colors/` etc. See also [how to write an
> init.fnl](#writing-confignviminitlua-in-fennel).

The user:

- Must name the file `.hotpot.lua`.
- Must place `.hotpot.lua` in the same directory as the `fnl/` directory.
- `.hotpot.lua` must return a lua table, don't forget the `return` keyword!

The presence of a valid `.hotpot.lua` file -- *even an empty table* -- will
override all hotpot settings passed to `setup()` back to their default values,
for fennel files in that directory.

```lua
-- ~/projects/my-plugin.nvim/.hotpot.lua
return {
  -- build = ...
  -- clean = ...
  -- compiler = { ... }
}
```

*Note: for performance reasons, the file is lua instead of fennel. You can use
the auto-build feature to compile `.hotpot.fnl` to `.hotpot.lua` by adding a
`{".hotpot.fnl", true}` value to the `build` list.*

### Supported Options

#### `build`

Specify auto-build instructions for the `.hotpot.lua` directory. When present,
hotpot will build all fennel files in a project when a fennel file is saved.

<!-- panvimdoc-ignore-start -->

See also [`:h hotpot.api.make.build`](API.md#htopotapimakebuild) for more
details and the underlying API.

See also [`:h
hotpot.api.make.auto.build`](API.md#hotpotapimakeautobuild) to manually
invoke the build rules without opening and saving a file.

<!-- panvimdoc-ignore-end -->

<!-- panvimdoc-include-comment

See also `:h hotpot.api.make.build` for more details and the underlying API.

See also `:h hotpot.api.make.auto.build` to manually invoke the build rules
without opening and saving a file.

-->

Supported values are:

**`build = false`** or **`build = nil`** or the key is omitted

Disable auto-building.

**`build = true`**

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

**`build = {{glob_pattern, boolean_or_function}, ...}`** or **`build = {{options}, {glob_pattern, boolean_or_function}, ...}`**

Each glob pattern is expanded in order and if the boolean value is true, the
file will be compiled, if false, the file will be ignored.

If given a function, the absolute path is passed to the function, the function
should return the desired lua path as a string (the extension will be
automatically converted from `.fnl` to `.lua`), or false.

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

#### `clean`

Specify auto-clean instructions for the `.hotpot.lua` directory. When present
Hotpot will remove any unknown files matching the given glob pattern after it
runs an auto-build.

Auto-clean will only run after an auto-build. Auto-clean will not run if the
`dryrun = true` option was given to `build`, or if `atomic = true` was given
and compilation errors occurred.

Supported values are:

**`clean = false`** or **`clean = nil`** or the key is omitted

Disable auto-cleaning.

**`clean = true`**

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

**`clean = {{glob_pattern, boolean}, ...}`**

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

#### `compiler`

The compiler key supports the same values as the `compiler` options you may
pass to `setup()`. See `:h hotpot-setup`.

```lua
compiler = {
  modules = { ... },
  macros = { ... },
  preprocessor = function ... end
}
```

## Writing `~/.config/nvim/init.lua` in Fennel

**Using autocommands and `hotpot.api.make`**

We can use a combination of the Make API and autocommands to write our main
`init.lua` in Fennel and automatically compile it to loadable lua on save.

```fennel
;; ~/.config/nvim/init.fnl

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

  (fn rebuild-on-save [{: buf}]
    (let [{: build} (require :hotpot.api.make)
          au-config {:buffer buf
                     :callback #(build (vim.fn.stdpath :config)
                                       {:verbose true :atomic true
                                        ;; Enforce hard errors when unknown symbols are encountered.
                                        :compiler {:modules {:allowedGlobals (icollect [n _ (pairs _G)] n)}}}
                                       [["init.fnl" true]])}]
      (vim.api.nvim_create_autocmd :BufWritePost au-config)))

  ;; watch file opens, attach builder if we open the config
  (vim.api.nvim_create_autocmd :BufRead
                               {:pattern (-> (.. (vim.fn.stdpath :config) :/init.fnl)
                                             ;; call realpath if you have some symlink setup
                                             ;; (vim.loop.fs_realpath)
                                             (vim.fs.normalize))
                                :callback rebuild-on-save}))

(require :the-rest-of-my-config)
```

Finally, we have to manually run this code *once* to generate the new `init.lua`:

- Open `init.fnl`
- Run `:Fnlfile %` to execute the current file and *enable* the autocommand.
  - Note, this will also run any code that is executed by `(require
    :the-rest-of-my-config)`.
  - You could also use `:Fnl` with the appropriate code selected.
- Run `:e` to re-open the buffer and *attach* the autocommand.
- Save the file with `:w` to *run* the autocommand.
  - *This will overwrite your existing `init.lua`!*
- Open `init.lua` to confirm it contains your fennel, compiled into lua.
- Start neovim in a new terminal to confirm the config loading is functioning
  without any errors.

**Using `.hotpot.lua`**

You can also configure a `.hotpot.lua` file to build `init.fnl`, see [using
`.hotpot.lua`](#using-dot-hotpot) for more information.

You should be aware that the presence of a `.hotpot.lua` file will disable any
`compiler` options you pass to setup, so you should instead move them into the
`.hotpot.lua` file.

Your build instructions can be as broad or slim as you want:

```lua
-- ~/.config/nvim/.hotpot.lua

return {
  build = {
    {verbose = true},
    -- This will only compile init.fnl, all other fnl/ files will behave as normal.
    {"init.fnl", true},
    -- Or you could enable other patterns too,
    -- {"colors/*.fnl", true},
    -- {"fnl/**/*.fnl", true},
  }
}
```

## Write an ftplugin

Put your code in `~/.config/nvim/ftplugin` as you would any lua ftplugin.

Ex.

```fennel
;;~/.config/nvim/ftplugin/fennel.fnl
(print (vim.fn.expand :<afile>)) ;; print name of fennel file
(vim.opt.formatoptions:append :j)
```

> ftplugins are put in the cache, irrespective of any colocation setting. This is
> to avoid any module precedence issues.

## Using Hotpot Reflect

<!-- panvimdoc-ignore-start -->

<div align="center">
<p align="center">
  <img style="width: 80%" src="images/reflect.svg">
</p>
</div>

<!-- panvimdoc-ignore-end -->

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

Open the cache directory with Telescope searcher:

```fennel
(let [{: find_files} (require :telescope.builtin)
      {: cache-prefix} (require :hotpot.api.cache)]
  (find_files {:cwd (cache-prefix)
               :hidden true}))
```

See also `:h hotpot.api.cache`.

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

<!-- panvimdoc-ignore-start -->

<details>
<summary>F͙̖͍͇̤ͣ̅ͯ̕Ō̝̦͎̣̲͖̬̬̌́R̖̮͈ͭ͊̾̈́͘B̢̮̖̊ͧ̃Į̳̘͇̣͖̔͋D̈̑̅͏̟͓̮̰̼̪͈Ď̡̲̠͇͍͓̔E̥̠̱ͫ̋̈̽͢Ņ̹̠̱̮̖̖̝ͣͯ̌ ̠̰̲̗̝̂͞K̶̩̲̖̦̯͕̜̱̃͆ͯ̾Ṉ͔̠̩̗̅̓̈́͢Ǫ̻̳̜̅W̰̩̰̬ͣ͗̕L̽ͦ̂͑҉͇̠E̫͎̝͖͕̰ͣ͡D̖͎͇̔̂ͬ͡G͇͚̩̱̮̹̈́͠E̱̖̯̫̬̫̞͒ͧ͜</summary>

<!-- panvimdoc-ignore-end -->

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

<!-- panvimdoc-ignore-start -->

</details>

<!-- panvimdoc-ignore-end -->
