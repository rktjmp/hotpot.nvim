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


(fn vimdoc-dump-fn [modname fname f]
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
      (table.insert doc 1 (.. fname "~\n"))
      (table.insert doc 1 "")
      (table.insert doc 1 (text-with-lead-fill "-" (.. " *" modname "." fname "*")))
      (table.insert doc 1 "")
      (table.concat doc "\n"))))

(fn mddoc-dump-fn [modname fname f]
  (let [fennel (require :fennel)
        sig (-> (. fennel.metadata f :fnl/arglist)
                (#(accumulate [t (.. "(" fname) _ n (ipairs $1)]
                              (.. t " " n)))
                (#(.. $1 ")")))
        doc (-> (. fennel.metadata f :fnl/docstring)
               (#(string.split (or $1 "undocumented") "\n"))
               ;; 1. remove two leading spaces from each line due to in-code indentation.
               (#(let [[l1 l2] $1
                       strip-n (if l2
                                 (let [strip (-> (string.match l2 "^([%s]*)")
                                                 (length))]
                                   0))]
                   (icollect [i l (ipairs $1)]
                     (if (= i 1)
                       l
                       (string.sub l strip-n -1)))))
               ;; 2. turn ``` ... ``` into > ... <
               ; (#(do
               ;     (var in-code false)
               ;     (icollect [_ l (ipairs $1)]
               ;       (match [in-code (string.find l "^```")]
               ;         [false not-nil] (do
               ;                           (set in-code true)
               ;                           (values ">"))
               ;         [true not-nil] (do
               ;                          (set in-code false)
               ;                          (values "<"))
               ;         [true nil] (values (.. "  " l))
               ;         [false nil] (values l)))))
               )]
    (table.insert doc 1 (.. "`" sig "`\n"))
    (table.insert doc 1 (.. "### " (.. "`" modname "." fname "`") "\n"))
    (table.insert doc 1 "")
    (table.insert doc 1 "")
    (table.concat doc "\n")))


(fn dump-mod [modname]
  (let [{: eval-module} (require :hotpot.api.eval)
        (_ mod) (eval-module modname {:useMetadata true})]
    (-> mod
        (#(if (= :hotpot.api.make modname)
            (doto $1
              (tset :automake.build mod.automake.build))
            $1))
        (#(icollect [fname f (pairs $1)] [fname f]))
        (#(doto $1 (table.sort (fn [[a _] [b _]]
                                 (< a b)))))
        (#(icollect [_ [fname f] (ipairs $1)]
            (case (type f)
              :function {:modname modname
                         :fname fname
                         :vimdoc (vimdoc-dump-fn modname fname f)
                         :mddoc (mddoc-dump-fn modname fname f)}))))))

(local preamble-text "The Hotpot API~

The Hotpot API provides tools for compiling and evaluating fennel code inside
Neovim, as well as performing ahead-of-time compilation to disk - compared to
Hotpots normal on-demand behaviour.

The API is proxied and may be accessed in a few ways:
>
  (let [hotpot (require :hotpot)]
    (hotpot.api.compile-string ...))

  (let [api (require :hotpot.api)]
    (api.compile-string ...))

  (let [{: compile-string} (require :hotpot.api.compile)]
    (compile-string ...))
<
All position arguments are \"linewise\", starting at 1, 1 for line 1, column 1.
Ranges are end-inclusive.")

(local index [["The Hotpot API" "|hotpot.api|"]])

(local mod-diagnostic
  {:modname "hotpot.api.diagnostics"
   :title "Diagnostics API"
   :desc "Framework for rendering compiler diagnostics inside Neovim.

The diagnostics framework is enabled by default for the `fennel` FileType
autocommand, see `hotpot.setup` for instructions on disabling it. You can
manually attach to buffers by calling `attach`.

The diagnostic is limited to one sentence (as provided by Fennel), but the
entire error, including hints can be accessed via the `user_data` field of the
diagnostic, or via `error-for-buf`."})

(local mod-reflect
  {:modname "hotpot.api.reflect"
   :title "Reflect API"
   :desc "A REPL-like toolkit.

!! The Reflect API is experimental and its shape may change, particularly around
accepting ranges instead of requiring a visual selection and some API terms
such as what a `session` is. !!

!! Do NOT run dangerous code inside an evaluation block! You could cause
massive damage to your system! !!

!! Some plugins (Parinfer) can be quite destructive to the buffer and can cause
marks to be lost or damaged. In this event you can just reselect your range. !!

Reflect API acts similarly to a REPL environment but instead of entering
statements in a conversational manner, you mark sections of your code and the
API will \"reflect\" the result to you and update itself as you change your
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

>
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
                                                 (api.nvim_command \"botright vnew\")
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
<
"})

(local mod-make
  {:modname "hotpot.api.make"
   :title "Make API"
   :desc "Tools to compile Fennel code ahead of time."})

(local mod-eval
  {:modname "hotpot.api.eval"
   :title "Eval API"
   :desc "Tools to evaluate Fennel code in-editor. All functions return
   `true result ...` or `false err`.

   Note: If your Fennel code does not output anything, running these functions by
   themselves will not show any output! You may wish to wrap them in a
   `(print (eval-* ...))` expression for a simple REPL."})

(local mod-compile
  {:modname "hotpot.api.compile"
   :title "Compile API"
   :desc "
   Tools to compile Fennel code in-editor. All functions return `true code` or
   `false err`. To compile fennel code to disk, see |hotpot.api.make|.

   Every `compile-*` function returns `true, luacode` or `false, errors` .

   Note: The compiled code is _not_ saved anywhere, nor is it placed in Hotp
   cache. To compile into cache, use `require(\"modname\")`."})

(local mod-cache
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
<
   (Hint: You can iterate `package.loaded` and match the key for `\"^my_module\"`.)

   Note: Some of these functions are destructive, Hotpot bears no responsibility for
   any unfortunate events."})

(local mods [mod-diagnostic mod-reflect mod-make mod-eval mod-compile mod-cache])

(each [_ mod (ipairs mods)]
  (let [docs (dump-mod mod.modname)]
    (table.insert index [mod.title (.. "|" mod.modname "|")])
    (each [_ {: fname} (ipairs docs)]
      (table.insert index [(.. "  " fname) (.. "|" mod.modname "." fname "|")]))
    (tset mod :docs docs)))

(with-open [fout (io.open "doc/hotpot-api.txt" :w)]
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
    (each [_ {: modname : fname : vimdoc} (ipairs docs)]
      (fout:write vimdoc)
      (fout:write "\n")
      (fout:write "\n"))))

(with-open [fout (io.open "API.md" :w)]
  (fout:write "# hotpot-api\n\n")
  ;; write index
  (fout:write (.. "## Table of Contents" "\n\n"))
  (each [_ [name tag] (ipairs index)]
    (let [(pre name) (name:match "^([%s]*)(.+)")
          link (tag:match "|(.+)|")]
      (fout:write (.. pre "- [" name "](#" (if (= :hotpot.api link)
                                             "the-hotpot-api"
                                             (link:gsub "%." "")) ")") "\n")))
  (fout:write "\n")
  ;; write lead text
  (let [text (-> (string.gsub preamble-text ">" "```fennel")
                 (string.gsub "<" "```")
                 (string.gsub "~\n" "")
                 )]
    (fout:write (.. "## " text)))
  (fout:write "\n")
  (fout:write "\n")
  ;; write docstrings
  (each [_ {: modname : title : desc : docs} (ipairs mods)]
    (fout:write (.. "## " modname "\n\n"))
    (fout:write (.. "\n\n" "### " title  "\n\n"))
    (fout:write (.. (-> (string.gsub desc ">" "```fennel")
                        (string.gsub "<" "```")) "\n"))
    (each [_ {: modname : fname : mddoc} (ipairs docs)]
      (fout:write mddoc)
      (fout:write "\n")
      (fout:write "\n"))))
