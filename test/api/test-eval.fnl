(local eval (require :hotpot.api.eval))

(match (eval.eval-string "(+ 1 1)")
  2 true
  _ (error "eval-string ok failed"))

(match (pcall eval.eval-string "+ 1 1")
  (false _) true
  _ (error "eval-string bad failed"))
