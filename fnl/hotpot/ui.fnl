(λ ui-select-sync [choices options callback]
  "Wraps vim.ui.select to behave synchronously"
  (var selected? false)
  (var return-val nil)
  (vim.ui.select choices options (fn [choice index]
                                  (set selected? true)
                                  (set return-val (callback choice index))))
  (vim.wait math.huge #selected?)
  (values return-val))

{: ui-select-sync}
