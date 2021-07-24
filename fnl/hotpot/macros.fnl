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
(fn dinfo [...])

{: require-fennel
 : dinfo
 : profile-as}
