(local {:format fmt} string)
(local {: file-exists? : file-missing? : file-stat : rm-file } (require :hotpot.fs))
(local SIGIL_FILE :.hotpot.lua)

;; Sigils are special configuration files written in lua to adjust some runtime
;; flags. In this case they alter how or where we compile to.
(fn load [path]
  (let [defaults {:schema "hotpot/1"
                  :colocate false}
        valid? (fn [sigil]
                 (case (icollect [key _val (pairs sigil)]
                         (case (. defaults key)
                           nil key))
                   [nil] true
                   keys (values false (fmt "invalid keys in sigil %s: %s. The valid keys are: %s."
                                           path
                                           (table.concat keys ", ")
                                           (-> (vim.tbl_keys defaults) (table.concat ", "))))))]
    ;; TODO: Should be disable require or are users at fault if they create a loop?
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
                    (vim.notify_once (fmt "hotpot sigil was empty, %s" path)
                                     vim.log.levels.error)
                    (error "hotpot refusing to continue to avoid unintentional side effects." 0))))))

(fn wants-colocation? [sigil-path]
  "Does the given record have a sigil file and does it request colocation?
  Returns true | false | nil error when the sigil was unparseable"
  (if (and sigil-path (file-exists? sigil-path))
    (case (load sigil-path)
      {: colocate} colocate
      _ (error "sigil loaded but did not enforce colocate key"))
    ;; We implicity deny colocation to "prefer lua" when present
    (values false)))

{: load : wants-colocation? : SIGIL_FILE}
