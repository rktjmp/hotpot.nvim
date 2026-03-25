(λ ui-select-sync [choices options callback]
  (var selected? false)
  (vim.ui.select choices options (fn [choice index]
                                  (set selected? true)
                                  (callback choice index)))
  (vim.wait math.huge #selected?))

{: ui-select-sync}
