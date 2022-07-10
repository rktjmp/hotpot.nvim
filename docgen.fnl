(fn string.split [s by]
  (local result [])
  (var from 1)
  (var (d-from d-to) (string.find s by from))
  (while d-from
    (table.insert result (string.sub s from (- d-from 1)))
    (set from (+ d-from 1))
    (set (d-from d-to) (string.find s by from)))
  (table.insert result (string.sub s from))
  (values result))

(fn text-with-lead-fill [fill text]
  (let [n (- 79 (length text))]
    (.. (string.rep fill n) text)))

(fn text-with-mid-fill [text-a fill text-b]
  (let [n (- 79 (length text-a) (length text-b))]
    (.. text-a (string.rep fill n) text-b)))

(fn dump-fn [modname fname f]
  (let [fennel (require :fennel)
        sig (-> (. fennel.metadata f :fnl/arglist)
                (#(accumulate [t (.. "(" fname) _ n (ipairs $1)]
                              (.. t " " n)))
                (#(.. $1 ")")))
        doc (-> (. fennel.metadata f :fnl/docstring)
               (#(string.split (or $1 "undocumented") "\n"))
               ;; 1. remove two leading spaces from each line due to in-code indentation.
               (#(icollect [_ l (ipairs $1)]
                   (if (string.find l "^  ")
                     (string.sub l 3 -1)
                     (values l))))
               ;; 2. turn ``` ... ``` into > ... <
               (#(do
                   (var in-code false)
                   (icollect [_ l (ipairs $1)]
                     (match [in-code (string.find l "^```")]
                       [false not-nil] (do
                                         (set in-code true)
                                         (values ">"))
                       [true not-nil] (do
                                        (set in-code false)
                                        (values "<"))
                       [true nil] (values (.. "  " l))
                       [false nil] (values l))))))]
    (let [tag (.. " *" modname "." fname "*")
          fill (- 79 (length tag))
          line (.. (string.rep "-" fill) tag)]
      (table.insert doc 1 (.. "`" sig "`\n"))
      (table.insert doc 1 "")
      (table.insert doc 1 (text-with-lead-fill "-" (.. " *" modname "." fname "*")))
      (table.insert doc 1 "")
      (table.concat doc "\n"))))

(fn dump-mod [modname]
  (let [{: eval-module} (require :hotpot.api.eval)
        mod (eval-module modname {:useMetadata true})]
    (-> mod
        (#(icollect [fname f (pairs $1)] [fname f]))
        (#(doto $1 (table.sort (fn [[a _] [b _]] (<= a b)))))
        (#(icollect [_ [fname f] (ipairs $1)]
            {:modname modname :fname fname :doc (dump-fn modname fname f)})))))

(local preamble-text "The Hotpot API~

The Hotpot API provides tools for compiling and evaluating fennel code inside
neovim, as well as performing ahead-of-time compiliation to disk - compared to
Hotpots normal on-demand behaviour.

The API is proxied and may be accessed in a few ways:
>
  (let [hotpot (require :hotpot)]
    (hotpot.api.compile-string ...))

  (let [api (require :hotpot.api)]
    (api.compile-string ...))

  (let [{: compile-string} (require :hotpot.api.compile)]
    (compile-string ...))

All position arguments are \"linewise\", starting at 1, 1 for line 1, column 1.
Ranges are end-inclusive.")
(local index [["The Hotpot API" "|hotpot.api|"]])
(local mods [{:modname "hotpot.api.make"
              :title "Make API"
              :desc "
Tools to compile Fennel code ahead of time."}
             {:modname "hotpot.api.compile"
              :title "Compile API"
              :desc "
Tools to compile Fennel code in-editor. All functions return `true code` or
`false err`. To compile fennel code to disk, see |hotpot.api.make|.

Every `compile-*` function returns `true, luacode` or `false, errors` .

Note: The compiled code is _not_ saved anywhere, nor is it placed in Hotp
      cache. To compile into cache, use `require(\"modname\")`."}
             {:modname "hotpot.api.eval"
              :title "Eval API"
              :desc "Tools to evaluate Fennel code in-editor.

Available in the `hotpot.api.eval` module.

Every `eval-*` function has the potential to raise an error, by:

  - bad arguments
  - compile errors
  - evaluated code errors

Handling these errors is left to the user.

Note: If your Fennel code does not output anything, running these functions by
      themselves will not show any output! You may wish to wrap them in a
      `(print (eval-* ...))` expression for a simple REPL."}
             {:modname "hotpot.api.cache"
              :title "Cache API"
              :desc "Tools to interact with Hotpots cache and index, such as
getting paths to cached lua files or clearing index entries.

You can manually interact with the cache at `~/.cache/nvim/hotpot`.

The cache will automatically refresh when required, but note: removing the
cache file is not enough to force recompilation in a running session. The
loaded module must be removed from Lua's `package.loaded` table, then
re-required.
>
  (tset package.loaded :my_module nil) ;; Does NOT unload my_module.child

(Hint: You can iterate `package.loaded` and match the key for `\"^my_module\"`.)

Note: Some of these functions are destructive, Hotpot bears no responsibility for
      any unfortunate events."}])

(each [_ mod (ipairs mods)]
  (let [docs (dump-mod mod.modname)]
    (table.insert index [mod.title (.. "|" mod.modname "|")])
    (each [_ {: fname} (ipairs docs)]
      (table.insert index [(.. "  " fname) (.. "|" mod.modname "." fname "|")]))
    (tset mod :docs docs)))

(#(with-open [fout (io.open "doc/hotpot-api.txt" :w)]
    (fout:write "*hotpot-api*\n\n")
    ;; write index
    (fout:write (.. (text-with-lead-fill "=" " *hotpot-api-toc*") "\n\n"))
    (each [_ [name tag] (ipairs index)]
      (fout:write (.. (text-with-mid-fill name "." tag) "\n")))
    (fout:write "\n")
    ;; write lead text
    (fout:write (.. (text-with-lead-fill "=" " *hotpot.api*") "\n\n"))
    (fout:write preamble-text)
    (fout:write "\n")
    (fout:write "\n")
    ;; write docstrings
    (each [_ {: modname : title : desc : docs} (ipairs mods)]
      (fout:write (.. (text-with-lead-fill "=" (.. " *" modname "*") "\n\n")))
      (fout:write (.. "\n\n" title  "~\n\n"))
      (fout:write (.. desc "\n"))
      (each [_ {: modname : fname : doc} (ipairs docs)]
        (fout:write doc)
        (fout:write "\n")
        (fout:write "\n")))))
