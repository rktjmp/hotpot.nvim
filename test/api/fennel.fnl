(let [{: latest} (require :hotpot.api.fennel)]
  (assert latest "api.latest missing")
  (assert (latest) "api.latest() failed"))
