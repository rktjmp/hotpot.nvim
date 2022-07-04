(local {: set-lazy-proxy} (require :hotpot.common))

(local lookup {:eval :hotpot.api.eval
               :compile :hotpot.api.compile
               :cache :hotpot.api.cache
               :fennel :hotpot.api.fennel})

(set-lazy-proxy {} lookup)
