(local M {})

(local PID (vim.fn.getpid))
(local *path* (-> (string.format "%s/%s" (vim.fn.stdpath :log) "hotpot.log")
                  (vim.fs.normalize)))
(fn view [x]
  (case (pcall require :fennel)
    (true {: view}) (view x)
    (false _) (vim.inspect x)))

(var *log-fd* nil)
(fn open [path]
  (when (not *log-fd*)
    (case (io.open path :a)
      fd (do
           (fd:setvbuf :line)
           (set *log-fd* fd))
      (nil e) (error e)))
  *log-fd*)

(fn write [...]
  (let [fd (open (*path*))]
    (fd:write ...)
    nil))

(fn expand-string [msg ...]
  (let [vargs [...]
        n (select :# ...)
        details (fcollect [i 1 n]
                  (let [v (. vargs i)]
                    (case (type v)
                      :string v
                      _ (view v))))]
    (string.format msg (unpack details))))

(fn msg->logline [msg]
  (.. "(" PID ") " (os.date "%FT%T%z") ": " msg "\n"))

(fn M.path [] *path*)

(fn M.info [msg ...]
  (let [msg (case (type msg)
              :string (expand-string msg ...)
              _ (view msg))]
    (write (msg->logline msg))))

; (fn table-pack [...] (doto [...] (tset :n (select :# ...))))
; (fn table-unpack [packed] (unpack packed 1 packed.n))

; (macro log-info [...]
;   `(when (or true (?. _G :hotpot :__debug))
;      (let [{:info info#} (require :hotpot.logger)]
;        (info# ,...))))

; (macro telemetry-span [context body ?rest]
;   (assert-compile (and (table? context) context.title) "must give context.title" context)
;   (assert-compile (list? body) "must give body" body)
;   (assert-compile (= nil ?rest) "must only have one body expression" ?rest)
;   (let [{: title} context
;         location (case-try
;                    body.filename fname
;                    (type fname) :string
;                    (string.gsub fname "^fnl/hotpot/" "") fname
;                    (.. fname ":" (or body.line "?"))
;                    (catch
;                      _ (or body.filename "?:?")))
;         title `(.. ,location " " ,title)
;         after context.after
;         tail `(fn [timing# vals#]
;                 (log-info (.. ,title " (%.3fms) %s")
;                           timing#.total-ms
;                           ,(if after `(,after (table-unpack vals#))))
;                 (table-unpack vals#))]
;     (if (or true (?. _G :__hotpot_build_flags :telemetry))
;       `(let [uv# (or vim.uv vim.loop)
;              start-t# (uv#.hrtime)
;              _# (log-info (.. ,title " start"))
;              vals# (table-pack (do ,body))
;              end-t# (uv#.hrtime)
;              timing# {:total-ns (- end-t# start-t#)
;                       :total-ms (/ (- end-t# start-t#) 1_000_000)}]
;          (,tail timing# vals#))
;       body)))

M
