(macro arg-err-msg [str]
  `(.. "hotpot.api.build argument error: " ,str))

(local M {})

;; Result type
(local R {})
(fn R.unit [...] (match ... (where r (R.result? r)) r (nil err) [:err err] _ [:ok ...]))
(fn R.bind [mx f] (match mx [:ok & x] (f (unpack x)) _ mx))
(fn R.validate [v p e] (R.bind v (fn [x] (if (p x) (R.unit x) (R.unit nil e)))))
(fn R.unwrap [mx] (match mx [_ & x] (values (unpack x))))
(fn R.unwrap! [mx] (if (R.ok? mx) (R.unwrap mx) (error (R.unwrap mx))))
(fn R.result? [mx] (or (R.err? mx) (R.ok? mx)))
(fn R.map [mx of ef] (if (R.ok? mx) (R.unit (of (R.unwrap mx))) (R.unit ((or ef #(values nil $...)) (R.unwrap mx)))))
(fn R.err? [mx] (= :err (. mx 1)))
(fn R.ok? [mx] (= :ok (. mx 1)))

(fn prepare-options [opts]
  "Accepts user options, validate type and shape and merge those options with
  the defaults. Returns result<options>."
  (fn table? [x] (= :table (type x)))
  (fn default-options []
    {:compiler nil ;; will be proxied
     :force? false
     :verbosity 1
     :atomic? true})
  (fn proxy-options [user-options]
    ;; !! This function has side effects on the given options but copying all
    ;; !! the keys and all that is boring af. Probably it wont matter.
    ;;
    ;; user options can be given sparsely, so we need to fall back to defaults
    ;; when an option is unspecified.
    (let [{: config} (require :hotpot.runtime)]
      ;; proxy most options directly to the defaults
      (setmetatable user-options {:__index (default-options)})
      ;; the user may give a compiler.modules value, but no macros value which
      ;; means we should proxy macros, so we have to also setup the fallback
      ;; indexing for the compiler table itself.
      (-> (or user-options.compiler {})
          (setmetatable {:__index config.compiler})
          (#(tset user-options :compiler $1)))
      ;; we never want to use hotpot traceback when making as we wont have to
      ;; strip stacktraces, nor prefix with our own messages.
      (set user-options.compiler.traceback :fennel)
      (R.unit user-options)))

  (-> (R.unit opts)
      (R.validate table? (arg-err-msg "options must be a table"))
      (R.bind proxy-options)))

(fn prepare-patterns-handlers [pfs]
  "Check that pattern-handlers are given in pairs of string-function, and
  return a seq of result<[[pat-fn] ...]>."
  (fn into-pairs [t]
    ;; TODO fcollect 1.20
    (let [x []]
      (for [i 1 (length t) 2]
        (table.insert x [(. t i) (. t (+ i 1))]))
      (R.unit x)))
  (fn validate-pairs [t]
    (accumulate [ok? (R.unit t) _ [pat han] (ipairs t) :until (R.err? ok?)]
      (match [(type pat) (type han)]
        [:string :function] (R.unit t)
        _ (R.unit nil (arg-err-msg "patterns-handlers must be string-function pairs")))))

  (-> (R.unit pfs)
      (R.validate #(<= 2 (length $1))
                  (arg-err-msg "requires at least one pattern-handler pair"))
      (R.validate #(= 0 (% (length $1) 2))
                  (arg-err-msg "pattern-handler must be given in pairs"))
      (R.bind into-pairs)
      (R.bind validate-pairs)))

(fn prepare-source-path [path]
  "Process source path by expanding ~ and making sure the file or dir exists.
  Returns result<path>."
  (fn expand-tilde [path]
    (fn get-home []
      (let [emsg (arg-err-msg "os.getenv HOME returned nil, unable to expand ~ in path")]
        (or (os.getenv :HOME) (values nil emsg))))
    (if (string.match path "^~")
      (-> (R.unit (get-home))
          (R.bind #(R.unit (pick-values 1 (string.gsub path "^~" $1)))))
      (R.unit path)))
  (fn validate-resolve [path]
    (let [uv vim.loop
          stats (R.unit (uv.fs_stat path))]
      (match stats
        [:ok {:type :directory}] (values (R.unit path :directory))
        [:ok {:type :file}] (values (R.unit path :file))
        _ (R.unit nil (arg-err-msg (string.format "source-path %q was not a directory or file" path))))))
  (-> (R.unit path)
      (R.bind expand-tilde)
      (R.bind validate-resolve)))

(fn match-target [path patterns-handlers]
  "Given a path, check it against all patterns. If a pattern matches, execute
  the handler. Returns a destination path, or nil if no pattern matched. Note
  that if a handler returns nil, the proceeding handlers are also checked."
  (accumulate [target nil _ [p f] (ipairs patterns-handlers) :until (not (= nil target))]
    (match [(string.match path p)]
      ;; no match for this pattern, but we will keep looking
      [nil] (values nil)
      ;; pattern did match, see if the handler has an output.
      ;; the handler may return nil, which is effectively a "didn't
      ;; really match" and we continue checking other patterns. We act
      ;; this way both for simpler code here and to avoid any "over
      ;; matches stopping future matches". Basically it's assumed that
      ;; checking will be cheap enough that we can check everything
      ;; against everything and it removes complexity from this *and* from
      ;; the patterns *and* the pattern ordering.
      ;; For "heavy" folders, simply split the build into multiple build calls with
      ;; more focused source directories, if benchmarking proves it matters.
      captures (let [{: join-path} (require :hotpot.fs)
                     _ (table.insert captures {: join-path})]
                 (-?> (f (unpack captures))
                      (string.gsub "%.fnl$" ".lua")
                      (#[path $1]))))))

(fn validate-target-extensions [list]
  (accumulate [acc (R.unit list) _ [_ target-file] (ipairs list) :until (R.err? acc)]
    (if (string.match target-file "%.lua$")
      (values acc)
      (let [msg (string.format (.. "compile target must end in .lua, got %q. "
                                   "(.fnl extensions will be automatically adjusted.)")
                               target-file)]
        (R.unit nil msg)))))

(fn find-source-target-pairs [source-path source-type options patterns-handlers]
  "Check source-path exists and iterate it for *.fnl files if its a dir, or just
  return [source-path] if its a file."
  (let [uv vim.loop
        {: join-path} (require :hotpot.fs)]
    (fn collect-files [dir patterns-handlers so-far]
      (let [scanner (uv.fs_scandir dir)]
        (accumulate [acc so-far name kind #(uv.fs_scandir_next scanner)]
          (let [full-path (join-path dir name)]
            (match kind
              "directory" (collect-files full-path patterns-handlers acc)
              "file" (match name
                      ;; never compile macro file
                      "init-macros.fnl" (values acc)
                      ;; only test .fnl files
                      (where name (string.match name "%.fnl$"))
                      (doto acc (table.insert (match-target full-path patterns-handlers)))
                      _ (values acc))
              _ (values acc))))))
    (match source-type
      :directory (-> (R.unit (collect-files source-path patterns-handlers {}))
                     (R.bind validate-target-extensions))
      :file (-> (R.unit [(match-target source-path patterns-handlers)])
                (R.bind validate-target-extensions)))))

(fn compile [fnl-file opts]
  "Compile fnl-file with given options. Returns result<code>."
  ;; We want to run the compilation with our given options, so for now we will
  ;; save the currrent hotpot config, replace it with our given options do the
  ;; compile then restore the old config.
  ;; TODO: Ideally we can wrap an execution context in a coroutine or similar
  ;;       and just swap them out as needed.
  (let [{: compile-file} (require :hotpot.api.compile)
        {: path-separator} (require :hotpot.fs)
        {: set-config :config previous-config} (require :hotpot.runtime)
        ;; the config is only the compiler subset
        _ (set-config {:compiler opts.compiler})
        ;; For relative requires, we need to have a known module name.
        ;; since we can be pretty sure we're operating in nvim, where
        ;; fnl/ will be our "root", we can sniff the module name if
        ;; that is present.
        ;; This *may* have false positives for strange setups but
        ;; it would also depend on the compiled file trying to access ... at
        ;; compilation time for it to be impactful.
        options (match (string.match fnl-file (.. "fnl" (path-separator) "(.+)$"))
                  nil (?. opts :compiler :modules)
                  path (let [modname (-> path
                                         (string.gsub (path-separator) ".")
                                         (string.gsub "%.fnl$" "")
                                         (string.gsub "%.init$" ""))]
                         (doto (or (?. opts :compiler :modules) {})
                           (tset :module-name modname))))
        result (match (compile-file fnl-file options)
                 (true lua-code) (R.unit lua-code)
                 (false err) (R.unit nil err))
        _ (set options.module-name nil)
        _ (set-config previous-config)]
    (values result)))

(fn do-make [source-path ...]
  ;; `...` may be `opts pat fn ...` or `pat fn pat fn`, so first we'll detect
  ;; what arguments we were given and validate those arguments before passing
  ;; off do do-build to ... do ... the building.
  (let [(raw-opts raw-patterns-handlers) (match [...]
                                           (where [opts & patterns-handlers] (= :table (type opts)))
                                           (values opts patterns-handlers)
                                           _no-options-given
                                           (values {} [...]))
        options (-> (prepare-options raw-opts)
                    (R.unwrap!))
        patterns-handlers (-> (prepare-patterns-handlers raw-patterns-handlers)
                              (R.unwrap!))
        (source-path source-type) (-> (prepare-source-path source-path)
                                      (R.unwrap!))
        source-target-pairs (-> (find-source-target-pairs source-path source-type options patterns-handlers)
                                (R.unwrap!))
        compiled (icollect [_ [fnl-file lua-file] (ipairs source-target-pairs)]
                   (let [{: file-mtime : file-missing?} (require :hotpot.fs)]
                     (if (or (= true options.force?)
                             (file-missing? lua-file)
                             (< (file-mtime lua-file) (file-mtime fnl-file)))
                       [fnl-file lua-file (compile fnl-file options)])))
        (oks errs) (accumulate [(oks errs) (values [] []) _ x (ipairs compiled)]
                    (match x
                      (where [_ _ r] (R.ok? r)) (values [x (unpack oks)] errs)
                      (where [_ _ r] (R.err? r)) (values oks [x (unpack errs)])))]
    (values options oks errs)))

(fn M.build [...]
  "Build fennel code found inside a directory (or single file), according to
  user defined rules. Files are only built if the output file is missing or if
  the source file is newer.

  `build` accepts a `source-path`, an optional `options` table and then a set of
  `pattern function` argument pairs. If `source-path` is a directory, each
  `*.fnl` file in `source-path` is checked against each `pattern` given, and if
  any match the `function` is called with the pattern captures as arguments.
  The function should return a path to save the compiled file to, or `nil`
  (`.fnl` extensions are automatically converted to `.lua` for QOL). If
  `source-path` is a file, it acts similar as for a directory but only for the
  file-path given.

  You may want to use this to build plugins written in Fennel or to compile
  small sections of your configuration that are never loaded via lua's
  `require` function. An example of these are `ftplugins/*.lua` or
  `colors/*.lua` files which are directly interpreted via Neovim and never
  loaded \"as modules\".

  Note: Regular Hotpot operation will track staleness due to dependency
  changes, a file will be \"stale\" if a macro it uses was changed, even if the
  file itself was not updated. Because `make.build` operates outside of Hotpots
  regular infrastructure, it does not currently track stale-ness to this level
  and only compares the source file vs the target file. See the `force?` option.

  Returns `[[src, dest, result<ok>] ...] [[src, dest, result<err>] ...]`

  Usage example:

  ```fennel
  ;; build all fnl files inside config dir
  (build \"~/.config/nvim\"
         ;; ~/.config/nvim/fnl/*.fnl -> ~/.config/nvim/lua/*.lua
         \"(.+)/fnl/(.+)\" 
         (fn [root path {: join-path}] ;; root is the first match, path is the second
           ;; ignore our own macro file (init-macros.fnl is ignored by default)
           (if (not (string.match path \"my-macros%.fnl$\"))
             ;; join-path automatically uses the os-appropriate path separator
             (join-path root :lua path)))
         ;; config/ftplugins/*.fnl -> config/ftplugins/*.lua
         \"(~/.config/nvim/ftplugins/.+)\"
         (fn [whole-path] (values whole-path)))
  ```

  Arguments are as given,

  `source-path`

  Directory to recursively search inside for `*.fnl` files or a direct path to
  a `.fnl` file. Direct paths are accepted as given but when recursing a
  directory any file named `init-macros.fnl` is ignored, as macros do not
  compile to lua. Any leading `~` is expanded via `os.getenv :HOME`, if the
  expansion fails an error is raised. Paths may be relative to the current
  working directory with a leading `.`.

  `options-table` (may be omitted)

  ```fennel
  {:atomic? true
   :verbosity 1
   :compiler {:modules {...}
              :macros {...}}}
  ```

  The options table may contain the following keys:

  `atomic?`: When true, if there is any compilation error, no files are written
            to disk. Defaults to true.

  `verbosity`: Adjusts information output. Errors are always output.
               - `0`: No output
               - `1`: Outputs compilation messages and nothing-to-do message
               Defaults to 1.

  `force?`: Force compilation, even if output is not stale.

  `compiler`: The compiler table has the same form and function as would be
              given to `hotpot.setup`. If the table is not given, the
              `compiler` options given to `hotpot.setup` are used.

  `pattern`

  A string that each found file path will be tested against.

  Ex: `\"(.+)/fnl/health/(.+)\"`

  `function`

  A function that's called if a file path matched the pattern. The function
  should return the output path, ending in .fnl or .lua.

  The extension must be `.lua` or `.fnl`. A `.lua` file is always output, but
  the extension must be present in the return value.

  `~` expansion is *not* applied to this path.

  If the function returns nil, the file will be checked against the remaining
  patterns, if all patterns return nil, the file is ignored and not compiled.

  The function is called with each capture group in its associated pattern and
  a final table containing helper functions.

  Ex: (fn [source-path path-inside-health-dir {: join-path}
           (join-path some-dir :lua path-inside-health-dir))

  Helpers: `join-path` joins all arguments with platform-specific separator.

  You can provide any number of patterns function pairs. Patterns are checked
  in the order given and match will stop future checks.

  Notes:

  Each time you run your build function, the directory must be recursively
  iterated for matching files. Configurations with thousands of files and
  hundreds of match-function pairs may suffer negative performance impacts.

  Even with no changes to the source files, the directory must be iterated and
  *checked* for changes each time the build function is run. This check is
  reasonably fast as we only have to check a few bytes of filesystem metadata
  but it *is* a non-zero cost.

  When in doubt, benchmark your build time and potentially limit its source
  directory scope if searching is unreasonably long."

  ;; `...` may be `opts pat fn ...` or `pat fn pat fn`, so first we'll detect
  ;; what arguments we were given and validate those arguments before passing
  ;; off do do-build to ... do ... the building.
  (let [(options oks errs) (do-make ...)]
    ;; log errors first, we might not do anything else
    (when (< 0 (length errs))
      (let [text []]
        (if options.atomic?
          (table.insert text [(.. "*** Compilation errors occured while in atomic mode, "
                                  "refusing to write any files! ***\n") :ErrorMsg])
          (table.insert text ["*** Compilation errors occured! ***\n" :ErrorMsg]))
        (table.insert text [" \n" :Normal]) ;; force line break
        (each [_ [_ _ [_ e]] (ipairs errs)]
          (do
            (table.insert text [e :DiagnosticError])
            (table.insert text [" \n" :Normal])))
        (table.insert text [" \n" :Normal]) ;; force line break
        (vim.api.nvim_echo text true {})))

    ;; write files if we're allowed
    (match [options.atomic? (length oks) (length errs)]
      ;; atomic and non-zero errors, dont proceed
      (where [true _ n] (< 0 n))
      (values nil)
      ;; no code, no errors, nothing to do
      (where [_ 0 0] (<= 1 options.verbosity))
      (vim.api.nvim_echo [["Nothing to compile!\n" :DiagnosticInfo]] true {})
      ;; either we're not atomic, or we are but had zero errors, write files
      _otherwise
      (let [text []
            {: dirname} (require :hotpot.fs)]
        (each [_ [fnl-file lua-file [_ code]] (ipairs oks)]
          (do
            ;; TODO error handling here is ... not yet written
            (vim.fn.mkdir (dirname lua-file) :p)
            (with-open [fout (io.open lua-file :w)]
                       (fout:write code))
            (table.insert text [(string.format "OK %s\n-> %s\n" fnl-file lua-file) :DiagnosticInfo])))
        (if (<= 1 options.verbosity)
          (vim.api.nvim_echo text true {}))))
    (values oks errs)))

(fn M.check [...]
  "Functionally identical to `build' but wont output any files. `check' is
  always verbose. Returns `[[src, dest, result<ok>] ...] [[src, dest, result<err>] ...]`"
  (let [(options oks errs) (do-make ...)
        err-text (accumulate [text [] _ [fnl-file _ [_ msg]] (ipairs errs)]
                   (doto text
                     (table.insert [(string.format "XX %s\n" fnl-file) :DiagnosticWarn])
                     (table.insert [(string.format "%s\n" msg) :DiagnosticError])))
        ok-text (accumulate [text [] _ [fnl-file _ [_ msg]] (ipairs oks)]
                  (doto text
                    (table.insert [(string.format "OK %s\n" fnl-file) :DiagnosticInfo])))]
    (vim.api.nvim_echo err-text true {})
    (vim.api.nvim_echo ok-text true {})
    (values oks errs)))

(values M)
