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

(fn ferror [str ...]
  `(error (string.format ,str ,...)))

(fn dprint [...]
  (local body (fcollect [i 1 (select :# ...)] 
                (let [s (. [...] i)]
                  (if (string.match (tostring s) "^&")
                    `(vim.inspect ,(sym (string.sub (tostring s) 2)))
                    `(tostring ,s)))))
  `(let [x# true]
     (macro ex [s#]
       (let [{:filename f# :line l#} s#]
         (string.format "%s#%s:" f# l#)))
     (print (string.format "%s %s"
                           (ex x#)
                           (table.concat ,body " ")))))

{: expect
 : ferror
 : dprint
 : profile-as}
