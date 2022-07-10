# Make.fnl

**Table of contents**

- [`build`](#build)
- [`check`](#check)

## `build`
Function signature:

```
(build ...)
```

Build fennel code found inside a directory, according to user defined rules.
  Files are only built if the output file is missing or if the source file is
  newer.

  Returns `[result<ok> ...] [result<err> ...]`

  Usage example:

  ```
  ;; build all fnl files inside config dir
  (build "/home/user/.config/.nvim"
        ;; config/fnl/*.fnl -> config/lua/*.lua
        "(~/%.config/nvim/)fnl/(.+)" (fn [root path]
                                         ;; ignore our own macro file
                                         (if (not (string.match path "my-macros%.fnl$"))
                                           (join-path root :lua path)))
        ;; config/ftplugins/*.fnl -> config/ftplugins/*.lua
        "(~/.config/nvim/ftplugins/.+)" (fn [whole-path] (values whole-path)))
  ```

  Arguments are as given,

  `source-dir`

  Directory to recursively search inside for `*.fnl` files. Any file named
  `init-macros.fnl` is ignored, as macros do not compile to lua. Any leading
  `~` is expanded via `os.getenv :HOME`, if the expansion fails an error is
  raised. Paths may be relative to the current working directory with a leading
  `.`.

  `options-table` (may be omitted)

  ```
  {:atomic true
   :verbosity 1
   :compiler {:modules {...}
              :macros {...}}}
  ```

  The options table may contain the following keys:

  `atomic`: When true, if there is any compilation error, no files are written
            to disk. Defaults to true.

  `verbosity`: Adjusts information output. Errors are always output.
               - `0`: No output
               - `1`: Outputs compilation messages and nothing-to-do message
               Defaults to 1.

  `force`: Force compilation, even if output is not stale.

  `compiler`: The compiler table has the same form and function as would be
              given to `hotpot.setup`. If the table is not given, the
              `compiler` options given to `hotpot.setup` are used.

  `pattern`

  A string that each found file path will be tested against.

  Ex: `"(.+)/fnl/health/(.+)"`

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

  Ex: (fn [source-dir path-inside-health-dir {: join-path}
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
  directory scope if searching is unreasonably long.

## `check`
Function signature:

```
(check ...)
```

Functionally identical to [`build`](#build) but wont output any files. [`check`](#check) is always verbose.
   Returns `[result<ok> ...] [result<err> ...]`


<!-- Generated with Fenneldoc v0.1.9
     https://gitlab.com/andreyorst/fenneldoc -->
