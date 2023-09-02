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

(vim.opt.runtimepath:prepend "/hotpot")
(require :hotpot)

{: write-file : read-file
 : OK : FAIL
 : exit
 :NVIM_APPNAME vim.env.NVIM_APPNAME}
