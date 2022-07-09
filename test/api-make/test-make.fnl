(local make (require :hotpot.api.make))

(make.build "~/test/api-make/fnl"
            "(.+)/fnl/([ab].+)"
            (fn [root f {: join-path}]
              (join-path root :lua f)))
