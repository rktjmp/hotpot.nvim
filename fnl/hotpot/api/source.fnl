;;;; WARNING
;;;; THIS FILE IS ***UNDOCUMENTED*** and created specifically for
;;;; https://github.com/rktjmp/hotpot.nvim/issues/43
;;;; DO NOT RELY ON ITS FUTURE EXISTENCE

(fn split-path [path]
  (let [sep (string.sub package.config 1 1)]
    (icollect [v (string.gmatch path (.. "[^" sep "]+"))] v)))

(fn find-module-name-parts [path-parts acc]
  (let [[head & rest] path-parts]
    (match [head (length rest)]
      ; init.fnl means use parent as module name
      ["init.fnl" 0] (values acc)
      ; no more path parts, so this just be the file, use as module name
      [file 0] (let [last (string.gsub file "%.fnl$" "")]
                 (table.insert acc last)
                 (values acc))
      ; just a dir, keep drilling
      [dir _] (do
                (table.insert acc dir)
                (find-module-name-parts rest acc)))))

(fn find-fnl-folder [path-parts]
  (let [[head & rest] path-parts]
    (match head
      nil (values nil)
      "fnl" (find-module-name-parts rest [])
      other (find-fnl-folder rest))))

(fn guess-module-name [full-path]
  ; given /home/some/config/fnl/my/module/path.fnl
  ; find "fnl" folder and nest down assuming that the module name should be
  ; my.module.path
  ; my/path/init.fnl -> my.path
  ; my/path/here.fnl -> my.path.here
  (let [path (split-path full-path)
        mod (find-fnl-folder path)]
    (match mod
      nil (let [modname nil]
            (values modname))
      list (let [modname (table.concat list ".")]
             (values modname)))))

(fn source-file [full-path]
  ; check that we can find the module name for given file
  (let [modname (guess-module-name full-path)]
    (match modname
      nil (print (.. "could not find module path for require "
                     "command (not decendant of a 'fnl' dir?)"))
      any (do
            ; TODO: would be nice if checked if the require would actually work
            ;       or at least cache the was-loaded module and re-insert it if
            ;       the require fails.
            ; unload module
            (tset package.loaded modname nil)
            ; rebuild and require
            (require modname)))))

{:source source-file}
