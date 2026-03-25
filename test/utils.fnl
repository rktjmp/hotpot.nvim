(fn read-file [path]
  (-> (vim.fn.readfile path)
      (table.concat :\n)))

(fn write-file [path lines]
  (vim.fn.mkdir (vim.fs.dirname path) :p)
  (with-open [fh (assert (io.open path :w) (.. "fs.write-file! io.open failed:" path))]
    (fh:write lines)))

(local results {:passes 0 :fails 0})

(fn OK [message]
  (set results.passes (+ 1 results.passes))
  (print "OK" message))

(fn FAIL [message]
  (set results.fails (+ 1 results.fails))
  (print "FAIL" message))

(fn exit []
  (print "\n")
  (os.exit results.fails))

(fn start-nvim []
  (let [channel (vim.fn.jobstart [:nvim :--embed :--headless] {:rpc true})
        nvim {: channel
              :close (fn [this] (vim.fn.jobstop channel))
              :cmd (fn [this cmd ...]
                     (vim.rpcrequest channel
                                     :nvim_exec2
                                     (string.format cmd ...)
                                     {:output true}))
              :lua (fn [this src]
                     (vim.rpcrequest channel
                                     :nvim_exec2
                                     (table.concat ["lua << EOF" src "EOF"] "\n")
                                     {:output true}))}]
    (nvim:lua "vim.opt.runtimepath:prepend('/home/user/hotpot')")
    (nvim:lua "vim.secure.read = function(path) return table.concat(vim.fn.readfile(path), '\\n') end")
    nvim))

(fn create-file [path content]
  (write-file path content)
  path)

(fn path [in ...]
  (case in
    :cache (vim.fs.joinpath (vim.fn.stdpath :data) :site :pack :hotpot :opt :hotpot-config-cache ...)
    _ (vim.fs.joinpath (vim.fn.stdpath in) ...)))


{: write-file : read-file
 : create-file : path
 : OK : FAIL
 : exit : start-nvim
 :NVIM_APPNAME vim.env.NVIM_APPNAME}
