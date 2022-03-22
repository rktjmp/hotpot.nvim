(fn require-fennel []
  `(require :hotpot.fennel))

(fn dinfo [...]
  `((. (require :hotpot.log) :log-msg)
    (table.concat ["[" (or debug-modname "no-debug-modname-set") "]" ,...] " ")))

(fn profile-as [name ...]
  `(let [name# ,name
         ta# (_G.vim.loop.hrtime)
         r# ,...
         tb# (_G.vim.loop.hrtime)]
     (dinfo
       (.. "<profile> " name# " " (/ (- tb# ta#) 1_000_000) "ms"))
     r#))

(fn profile-as [name ...] `,...)
;;(fn dinfo [...])

(fn expect [assertion message ...]
  `(when (not ,assertion)
     (let [failed-what# ,(view assertion)
           err# (string.format "%s [failed: %s]" ,message failed-what#)]
       (error (string.format err# ,...)))))

(fn pinspect [...]
  `(let [{:inspect inspect#} (require :hotpot.common)]
     (inspect# ,...)))

(fn struct [is-a ...]
  "(struct :my/struct (attr name :my-name mutable show)) ;; can tset, will appear in tostring"
  (let [processed (icollect [_ attr (ipairs [...])]
                    (let [[call name val & flags] attr]
                      (when (not (= :attr (tostring call)))
                        (error "struct only accepts attr call"))
                      {:name name
                       :value val
                       :flags (collect [_ flag (ipairs flags)]
                                (values (tostring flag) true))}))
        attrs (collect [_ {: name : flags} (ipairs processed)]
                (values name flags))
        context (collect [_ {: name : value} (ipairs processed)]
                  (values name value))]
    `(let [common# (require :hotpot.common)
           is-a# ,is-a
           id# (common#.monotonic-id is-a#)
           attrs# ,attrs
           context# ,context
           to-string# (fn [_#]
                        (let [inner# (collect [attr# flags# (pairs attrs#)]
                                       (when (not (. flags# :hidden))
                                         (values attr# (. context# attr#))))]
                          (common#.fmt "(%s %s)" id# (common#.view inner#))))
           mt# {:__tostring to-string#
                :__fennelview to-string#
                :__index (fn [_# key#]
                           (match key#
                             :id id#
                             :is-a is-a#
                             other# (do
                                      (if (= nil (. attrs# key#))
                                          (error (common#.fmt "%s does not have attr %s"
                                                              is-a# key#)))
                                      (. context# key#))))
                :__newindex (fn [_# key# val#]
                              (if (= nil (. attrs# key#))
                                  (error (common#.fmt "%s does not have attr %s"
                                                      is-a# key#)))
                              (if (not (. attrs# key# :mutable))
                                  (error (common#.fmt "%s.%s is not mutable"
                                                      is-a# key#)))
                              (tset context# key# val#))}]
       (setmetatable {} mt#))))

{: require-fennel
 : dinfo
 : expect
 : pinspect
 : struct
 : profile-as}
