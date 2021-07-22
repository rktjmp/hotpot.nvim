(fn require-fennel []
  `(require :hotpot.fennel))

(fn profile-as [name ...]
  `(let [name# ,name
         ta# (_G.vim.loop.hrtime)
         r# ,...
         tb# (_G.vim.loop.hrtime)]
     (print
       (.. "Profile: " name# " "
           (/ (- tb# ta#) 1_000_000) "ms")) r#))

(fn profile-as [name ...] `,...)

{: require-fennel
 : profile-as}
