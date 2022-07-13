; (fn profile-as [name ...]
;   `(let [name# ,name
;          ta# (_G.vim.loop.hrtime)
;          r# ,...
;          tb# (_G.vim.loop.hrtime)]
;      (
;        (.. "<profile> " name# " " (/ (- tb# ta#) 1_000_000) "ms"))
;      r#))
(fn profile-as [name ...] `,...)

(fn expect [assertion message ...]
  `(when (not ,assertion)
     (let [failed-what# ,(view assertion)
           err# (string.format "%s [failed: %s]" ,message failed-what#)]
       (error (string.format err# ,...) 0))))

{: expect
 : profile-as}
