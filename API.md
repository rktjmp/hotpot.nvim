# hotpot-api

## Table of Contents

- [The Hotpot API](#the-hotpot-api)
- [Diagnostics API](#hotpotapidiagnostics)
  - [attach](#hotpotapidiagnosticsattach)
  - [detach](#hotpotapidiagnosticsdetach)
  - [disable](#hotpotapidiagnosticsdisable)
  - [enable](#hotpotapidiagnosticsenable)
  - [error-for-buf](#hotpotapidiagnosticserror-for-buf)
- [Reflect API](#hotpotapireflect)
  - [attach-input](#hotpotapireflectattach-input)
  - [attach-output](#hotpotapireflectattach-output)
  - [detach-input](#hotpotapireflectdetach-input)
  - [set-mode](#hotpotapireflectset-mode)
- [Make API](#hotpotapimake)
  - [auto.build](#hotpotapimakeautobuild)
  - [build](#hotpotapimakebuild)
  - [check](#hotpotapimakecheck)
- [Eval API](#hotpotapieval)
  - [eval-buffer](#hotpotapievaleval-buffer)
  - [eval-file](#hotpotapievaleval-file)
  - [eval-module](#hotpotapievaleval-module)
  - [eval-range](#hotpotapievaleval-range)
  - [eval-selection](#hotpotapievaleval-selection)
  - [eval-string](#hotpotapievaleval-string)
- [Compile API](#hotpotapicompile)
  - [compile-buffer](#hotpotapicompilecompile-buffer)
  - [compile-file](#hotpotapicompilecompile-file)
  - [compile-range](#hotpotapicompilecompile-range)
  - [compile-selection](#hotpotapicompilecompile-selection)
  - [compile-string](#hotpotapicompilecompile-string)
- [Cache API](#hotpotapicache)
  - [cache-prefix](#hotpotapicachecache-prefix)
  - [clear-cache](#hotpotapicacheclear-cache)
  - [open-cache](#hotpotapicacheopen-cache)

## The Hotpot API
The Hotpot API provides tools for compiling and evaluating fennel code inside
Neovim, as well as performing ahead-of-time compilation to disk - compared to
Hotpots normal on-demand behaviour.

The API is proxied and may be accessed in a few ways:
```fennel
  (let [hotpot (require :hotpot)]
    (hotpot.api.compile-string ...))

  (let [api (require :hotpot.api)]
    (api.compile-string ...))

  (let [{: compile-string} (require :hotpot.api.compile)]
    (compile-string ...))
```
All position arguments are "linewise", starting at 1, 1 for line 1, column 1.
Ranges are end-inclusive.

## hotpot.api.diagnostics



### Diagnostics API

Framework for rendering compiler diagnostics inside Neovim.

The diagnostics framework is enabled by default for the `fennel` FileType
autocommand, see `hotpot.setup` for instructions on disabling it. You can
manually attach to buffers by calling `attach`.

The diagnostic is limited to one sentence (as provided by Fennel), but the
entire error, including hints can be accessed via the `user_data` field of the
diagnostic, or via `error-for-buf`.


### `hotpot.api.diagnostics.attach`

`(attach user-buf)`

Attach handler to buffer which will render compilation errors as diagnostics.

Buf can be 0 for current buffer, or any valid buffer number.

Returns the buffer-id which can be used to `detach` or get `error-for-buf`,
when given 0, this id will be the 'real' buffer id, otherwise it will match
the original `buf` argument.



### `hotpot.api.diagnostics.detach`

`(detach user-buf ?opts)`

Remove hotpot-diagnostic instance from buffer.



### `hotpot.api.diagnostics.disable`

`(disable)`

Disables filetype autocommand and detaches any attached buffers



### `hotpot.api.diagnostics.enable`

`(enable)`

Enables autocommand to attach diagnostics to Fennel filetype buffers



### `hotpot.api.diagnostics.error-for-buf`

`(error-for-buf user-buf)`

Get current error for buffer (includes all Fennel hints) or nil if no error.
The raw fennel error is also attached to the `user_data` field of the
diagnostic structure returned by Neovim.

## hotpot.api.reflect



### Reflect API

A REPL-like toolkit.

!! The Reflect API is experimental and its shape may change, particularly around
accepting ranges instead of requiring a visual selection and some API terms
such as what a `session` is. !!

!! Do NOT run dangerous code inside an evaluation block! You could cause
massive damage to your system! !!

!! Some plugins (Parinfer) can be quite destructive to the buffer and can cause
marks to be lost or damaged. In this event you can just reselect your range. !!

Reflect API acts similarly to a REPL environment but instead of entering
statements in a conversational manner, you mark sections of your code and the
API will "reflect" the result to you and update itself as you change your
code.

The basic usage of the API is:

1. Get an output buffer pass it to `attach-output`. A `session-id` is returned.

2. Visually select a region of code and call `attach-input session-id ```buf```fennel`
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



### `hotpot.api.reflect.attach-input`

`(attach-input session-id given-buf-id ?compiler-options)`

Attach given buffer to session. This will detach any existing attachment first.

Accepts session-id buffer-id and optional compiler options as you would
define in hotpot.setup If no compiler-options are given, the appropriate
compiler-options are resolved from any local .hotpot.lua file, or those given
to setup(). Whe providing custom options you must provide a modules and
macros table and a preprocessor function.

Returns session-id



### `hotpot.api.reflect.attach-output`

`(attach-output given-buf-id)`

Configures a new Hotpot reflect session. Accepts a buffer id. Assumes the
buffer is already in a window that was configured by the caller (float,
split, etc). The contents of this buffer should be treated as ephemeral,
do not pass an important buffer in!

Returns `session-id {: attach : detach}` where `attach` and `detach`
act as the module level `attach` and `detach` with the session-id
argument already filled.



### `hotpot.api.reflect.detach-input`

`(detach-input session-id)`

Detach buffer from session, which removes marks and autocmds.

Returns session-id



### `hotpot.api.reflect.set-mode`

`(set-mode session-id mode)`

Set session to eval or compile mode

## hotpot.api.make



### Make API

Tools to compile Fennel code ahead of time.


### `hotpot.api.make.auto.build`

`(auto.build file-dir-or-dot-hotpot ?opts)`

Finds any .hotpot.lua file nearest to given `file-dir-or-dot-hotpot`
path and builds accordingly.

If `build = false | nil` in the .hotpot.lua file, proceeds as if
it were `build = true`.

Optionally accepts an options table which may contain the same keys as
described for `api.make.build`. By default, `force = true` and
`verbose = true`.

Note: this function is under `(. (require :hotpot.api.make) :auto :build)`
NOT `(. (require :hotpot.api.make.auto) :build)`.



### `hotpot.api.make.build`

`(build ...)`

Build fennel files found inside a directory that match a given set of glob
patterns.

```
(build :some/dir
       {:verbose true}
       [[:fnl/**/*macro*.fnl false]
        [:fnl/**/*.fnl true]
        [:colors/*.fnl (fn [path] (string.gsub path :fnl$ :lua))]])
```

Build accepts a `root-directory` to work in, an optional `options` table and
a list of pairs, where each pair is a glob string and boolean value or a
function. A true value indicates a matching file should be compiled, and
false indicates the file should be ignored. Functions are passed the globbed
file path (which may or may not be absolute depending on the root directory).
and should return false or a string for the lua destination path.

The options table may contain the following keys:

- `atomic`, boolean, default false. When true, if there are any errors during
   compilation, no files are written to disk. Defaults to false.

- `force`, boolean, default false. When true, all matched files are built, when
  false, only changed files are build.

- `dryrun`, boolean, default false. When true, no biles are written to disk.

- `verbose`, boolean, default false. When true, all compile events are logged,
  when false, only errors are logged.

- `compiler`, table, default nil. A table containing modules, macros and preprocessor
  options to pass to the compiler. See :h hotpot-setup.

(Note the keys are in 'lua style', without dashes or question marks.)

Glob patterns that begin with `fnl/` are automatically compiled to to `lua/`,
other patterns are compiled in place or should be constructing explicitly by a
function.

Glob patterns are checked in the order they are given, so generally 'ignore' patterns
should be given first so things like 'macro modules' are not compiled to
their own files.



### `hotpot.api.make.check`

`(check ...)`

Deprecated, see dryrun option for build

## hotpot.api.eval



### Eval API

Tools to evaluate Fennel code in-editor. All functions return
`true result ...` or `false err`.

Note: If your Fennel code does not output anything, running these functions by
themselves will not show any output! You may wish to wrap them in a
`(print (eval-* ...))` expression for a simple REPL.


### `hotpot.api.eval.eval-buffer`

`(eval-buffer buf ?options)`

Evaluate the given `buf`, returns `true result ...` or `false error`.
Accepts an optional `options` table as described by Fennels API
documentation.



### `hotpot.api.eval.eval-file`

`(eval-file fnl-file ?options)`

Read contents of `fnl-path` and evaluate the contents, returns `true
result ...` or `false error`. Accepts an optional `options` table as
described by Fennels API documentation.



### `hotpot.api.eval.eval-module`

`(eval-module modname ?options)`

Use hotpots module searcher to find the file for `modname`, load and
evaluate its contents, returns `true result ...` or `false error`..
Accepts an optional `options` table as described by Fennels API
documentation.



### `hotpot.api.eval.eval-range`

`(eval-range buf start-pos stop-pos ?options)`

Evaluate `buf` from `start-pos` to `end-pos`, returns `true result
...` or `false error`. Positions can be `line` or `line col`. Accepts
an optional `options` table as described by Fennels API
documentation.



### `hotpot.api.eval.eval-selection`

`(eval-selection ?options)`

Evaluate the current selection, returns `true result ...` or `false
error`. Accepts an optional `options` table as described by Fennels
API documentation.



### `hotpot.api.eval.eval-string`

`(eval-string code ?options)`

Evaluate given fennel `code`, returns `true result ...` or `false
error`. Accepts an optional `options` table as described by Fennels
API documentation.

## hotpot.api.compile



### Compile API


Tools to compile Fennel code in-editor. All functions return `true code` or
`false err`. To compile fennel code to disk, see |hotpot.api.make|.

Every `compile-*` function returns `true, luacode` or `false, errors` .

Note: The compiled code is _not_ saved anywhere, nor is it placed in Hotp
cache. To compile into cache, use `require("modname")`.


### `hotpot.api.compile.compile-buffer`

`(compile-buffer buf compiler-options)`

Read the contents of `buf` and compile into lua, returns `true lua` or
`false error`.

Accepts an options table as described by Fennels API documentation.



### `hotpot.api.compile.compile-file`

`(compile-file fnl-path compiler-options)`

Read contents of `fnl-path` and compile into lua, returns `true lua` or
`false error`. Will raise if file does not exist.

Accepts an options table as described by Fennels API documentation.



### `hotpot.api.compile.compile-range`

`(compile-range buf start-pos stop-pos compiler-options)`

Read `buf` from `start-pos` to `end-pos` and compile into lua, returns `true
lua` or `false error`. Positions can be `line-nr` or `[line-nr col]`.

Accepts an options table as described by Fennels API documentation.



### `hotpot.api.compile.compile-selection`

`(compile-selection compiler-options)`

Read the current selection and compile into lua, returns `true lua` or
`false error`.

Accepts an options table as described by Fennels API documentation.



### `hotpot.api.compile.compile-string`

`(compile-string str compiler-options)`

Compile given `str` into lua, returns `true lua` or `false error`.

Accepts an options table as described by Fennels API documentation.

## hotpot.api.cache



### Cache API

Tools to interact with Hotpots cache and index, such as
getting paths to cached lua files or clearing index entries.

You can manually interact with the cache at `~/.cache/nvim/hotpot`.

The cache will automatically refresh when required, but note: removing the
cache file is not enough to force recompilation in a running session. The
loaded module must be removed from Lua's `package.loaded` table, then
re-required.

(tset package.loaded :my_module nil) ;; Does NOT unload my_module.child

(Hint: You can iterate `package.loaded` and match the key for `"^my_module"`.)

Note: Some of these functions are destructive, Hotpot bears no responsibility for
any unfortunate events.


### `hotpot.api.cache.cache-prefix`

`(cache-prefix)`

Returns the path to Hotpots lua cache



### `hotpot.api.cache.clear-cache`

`(clear-cache ?opts)`

Clear all lua cache files.

Accepts an optional table of options which may specify {silent=true} to disable prompt.



### `hotpot.api.cache.open-cache`

`(open-cache ?cb)`

Open the cache directory in a vsplit or calls `cb` function with cache path

