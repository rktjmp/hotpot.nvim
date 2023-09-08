(import-macros {: dprint} :hotpot.macros)

(fn slash-modname [modname]
  (string.gsub modname "%." :/))

(fn globsearch-runtime-path [spec]
  (let [{: all? : glob : path} spec
        limit (if all? -1 1)]
    (accumulate [matches []
                 _ path (ipairs (vim.fn.globpath path glob true true))
                 &until (= limit (length matches))]
      (doto matches (table.insert
                      (vim.fs.normalize path {:expand_env false}))))))

(fn modsearch-runtime-path [spec]
  "Search Neovim RTP for given spec, returns a list of results which may
  contain at most one or many results depending on all? option."
  (let [{: join-path} (require :hotpot.fs)
        {: all? : modnames : prefix : extension} spec
        paths (icollect [_ modname (ipairs modnames)]
                (join-path prefix (.. (slash-modname modname) :. extension)))
        limit (if all? -1 1)]
    (accumulate [matches [] _ possible-path (ipairs paths) &until (= limit (length matches))]
      (case (vim.api.nvim_get_runtime_file possible-path all?)
        paths (icollect [_ path (ipairs paths) &into matches]
                (vim.fs.normalize path {:expand_env false}))
        _ matches))))

(fn modsearch-package-path [spec]
  "Search lua package.path for fnl files, returns a list but will only ever find at most one match."
  (let [{: file-exists?} (require :hotpot.fs)
        {: modnames : extension} spec
        modnames (icollect [_ modname (ipairs modnames)] (slash-modname modname))
        ;; append ; so regex is simpler
        templates (string.gmatch (.. package.path ";") "(.-);")
        build-path-with  (fn [modname] #(.. $1 modname $2 :. extension))
        result (accumulate [template-match nil template templates &until template-match]
                 (accumulate [mod-match nil _ modname (ipairs modnames) &until mod-match]
                   (case (string.gsub template "(.*)%?(.*)%.lua$" (build-path-with modname))
                     (where (path 1) (file-exists? path)) (vim.fs.normalize path {:expand_env false}))))]
  [result]))

(λ mod-search [spec]
  "Searches RTP and then package.path for file(s) that satisfiy the given
  search specifications. Returns a list with 0, 1 or many absolute paths to
  files that match the given mod names.

  The spec must contain the following keys:

  modnames: A list of modnames to search for, in preference order, ex:
    [:hotpot.init :hotpot]

  extension: A file extension to match with, ex: :fnl

  prefix: A directory to search inside of when performing RTP searches. Does
    not effect package.path searches. Ex: :fnl

  The spec may contain:

  all?: true or false dictating whether to return more than the first match.
    Does not effect package.path searches.

  runtime-path?: search the RTP, defaults to true.

  package-path?: search the package.path, defaults to true."

  (let [defaults {:all? false
                  :runtime-path? true
                  :package-path? true}
        spec (vim.tbl_extend :keep spec defaults)]
    (each [_ key (ipairs [:modnames :extension :prefix])]
      (assert (. spec key) (.. "search spec must have " key " field")))
    (case-try
      (if spec.runtime-path? (modsearch-runtime-path spec) []) [nil]
      (if spec.package-path? (modsearch-package-path spec) []) [nil]
      (values []))))

(λ glob-search [spec]
  "Searches the RTP for files that match the given glob pattern. Returns a list
  with 0, 1 or many absolute paths to files that were found.

  The spec must contain the following keys:

  glob: glob pattern to match on

  The spec may contain the following keys:

  all?: true or false, return all matches or only the first. Defaults to false.

  path: string, defaults to vim.go.rtp."
  (let [defaults {:all? false
                  :path vim.go.rtp}
        spec (vim.tbl_extend :keep spec defaults)]
    (each [_ key (ipairs [:glob])]
      (assert (. spec key) (.. "glob-search spec must have " key " field")))
    (globsearch-runtime-path spec)))

{: mod-search
 : glob-search}
