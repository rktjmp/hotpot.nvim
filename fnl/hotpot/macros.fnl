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

{: require-fennel
 : dinfo
 : expect
 : profile-as}
