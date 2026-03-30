;; Note this file is currently required in every other file for `R`, so keep it
;; light and dont require anything else directly.

(fn pack [...]
  (doto [...]
    (tset :n (select :# ...))))

(λ file-mtime [path]
  (case (vim.uv.fs_stat path)
    {:mtime {: sec : nsec}} {:equal? (fn [this other]
                                       (and (= sec other.sec) (= nsec other.nsec)))
                             :after? (fn [this other]
                                       (or (< other.sec sec)
                                           (and (= other.sec sec) (< other.nsec nsec))))
                             :before? (fn [this other]
                                        (or (< sec other.sec)
                                            (and (= sec other.sec) (< nsec other.nsec))))
                             : path
                             : sec
                             : nsec}
    (nil err) nil))

(λ file-read [path]
  (with-open [fh (assert (io.open path :r) (.. "read io.open failed:" path))]
    (fh:read :*a)))

(λ file-write [path lines]
  (assert (= :string (type lines)) "write file expects string")
  (with-open [fh (assert (io.open path :w) (.. "write io.open failed:" path))]
    (fh:write lines)))

;; Controversial?
;; Provides an interface to `require` via key so we dont have to ...
;; write require a lot? Instead of having `{: y} (require :hotpot.x)`
;; we can just write `{: y} R.x`
;; Since we're also weird and like to name Modules with a capital,
;; we actually make the index lookup case-insensitive for the require call.
;; eg: `{: Context :util {: pack}} R`
(fn nest [t namespace]
  (setmetatable t {:__index (fn [t key]
                              (let [lowkey (string.lower key)]
                                (case (rawget t lowkey)
                                  mod mod
                                  nil (let [modname (.. namespace "." lowkey)
                                            mod (require modname)]
                                        (set (. t lowkey) mod)
                                        (case (type mod)
                                          ;; Fennel is the only vendored lib we have
                                          ;; and we dont want to pollute it
                                          ;; with the meta method.
                                          :table (if (not= "hotpot.fennel" modname)
                                                   (nest mod modname)
                                                   mod)
                                          _ mod)))))}))
(local R (nest {} :hotpot))

;; We vim.schedule these due to behaviour in vim-0.12 where perhaps before ever
;; calling `:messages`, these notifications are not reliably shown, assumingly
;; due to a race between outputting `written <path>`, clearing the cmd line and
;; showing the vim.notify output.
;;
;; Seems reliably reproduced by adding (local x"badwarning") to a file and saving it
;; to trigger a compile (without previously having run :messages)
;; (local x"badwarning")
(λ notify-error [msg ...]
  (let [str (string.format msg ...)]
    (vim.schedule #(vim.notify str vim.log.levels.ERROR))))
(λ notify-warn [msg ...]
  (let [str (string.format msg ...)]
    (vim.schedule #(vim.notify str vim.log.levels.WARN))))
(λ notify-info [msg ...]
  (let [str (string.format msg ...)]
    (vim.schedule #(vim.notify str vim.log.levels.INFO))))

{: notify-error
 : notify-warn
 : notify-info
 : file-read
 : file-write
 : file-mtime
 : pack : R}
