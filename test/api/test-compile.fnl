(local compile (require :hotpot.api.compile))

(match (compile.compile-string "(+ 1 1)")
  (true "return (1 + 1)") true
  _ (error "compile-string ok failed"))

(match (compile.compile-string "+ 1 1")
  (false _) true
  _ (error "compile-string bad failed"))
