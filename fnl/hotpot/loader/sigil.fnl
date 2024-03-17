(local {:format fmt} string)
(local SIGIL_FILE :.hotpot.lua)

;; Sigils are special configuration files written in lua to adjust some runtime
;; flags. In this case they alter how or where we compile to.
(fn load [path]
  (let [defaults {:schema "hotpot/1"
                  :build false
                  :clean false
                  :compiler {}}
        valid? (fn [sigil]
                 (case (icollect [key _val (pairs sigil)]
                         (case (. defaults key)
                           nil key))
                   [nil] true
                   invalid-keys (let [e (fmt "invalid keys in sigil %s: %s. The valid keys are: %s."
                                             path
                                             (table.concat invalid-keys ", ")
                                             (-> (vim.tbl_keys defaults) (table.concat ", ")))]
                                  (values false e))))]
    ;; TODO: Should we disable require in env or are users at fault if they create a loop?
    (case-try
      (loadfile path) sigil-fn
      (pcall sigil-fn) (where (true sigil) (= :table (type sigil)))
      (valid? sigil) true
      (values sigil)
      (catch
        (true nil) (do
                     ;; A sigil file may return nil intentionally, such as
                     ;; a blank or all commented out to disable options,
                     ;; etc. Catch these cases and act as if it didnt exist.
                     (vim.notify_once (fmt "Hotpot sigil was exists but returned nil, %s" path)
                                      vim.log.levels.WARN)
                     (values nil))
        (true x) (do
                   (vim.notify (table.concat ["Hotpot sigil failed to load due to an input error."
                                              (fmt "Sigil path: %s" path)
                                              (fmt "Sigil returned %s instead of table" (type x))] "\n")
                               vim.log.levels.ERROR)
                   (error "Hotpot refusing to continue to avoid unintentional side effects." 0))
        (nil e) (do
                  (vim.notify (table.concat ["Hotpot sigil failed to load due to a syntax error."
                                             (fmt "Sigil path: %s" path)
                                             e] "\n")
                              vim.log.levels.ERROR)
                  (error "Hotpot refusing to continue to avoid unintentional side effects." 0))
        (false e) (do
                    ;; for now we'll hard exit on a poorly constructed file but
                    ;; might relax this in the future, esp 
                    (vim.notify_once (fmt "hotpot sigil was invalid, %s\n%s" path e)
                                     vim.log.levels.ERROR)
                    (error "hotpot refusing to continue to avoid unintentional side effects." 0))))))

{: load : SIGIL_FILE}
