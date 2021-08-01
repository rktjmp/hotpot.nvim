(fn get_range_lines [line1 line2]
  "
    Get buffer lines from range line1 - line2
    line1 & line2 can either be line number or position line [row, col]
  "
  (var retval [])
  (if (= (type line1) "number")
      (set retval (vim.api.nvim_buf_get_lines 0 (- line1 1) line2 false))
    (= (type line1) "table")
      (let [[line1_row line1_col] line1
            [line2_row line2_col] line2
            buf (vim.api.nvim_buf_get_lines 0 (- line1_row 1) line2_row false)]
          (when (> (length buf) 0)
            (tset buf 1 (string.sub (. buf 1) line1_col + 1))
            (tset buf (length buf) (string.sub (. buf (length buf)) 1 (+ line2_col 1)))
            (set retval buf))))
  retval)

(fn exec_fennel_str [...]
  "Executes input strings as fennel code"
  (var retval nil)
  (let [buf (table.concat [...] " ")
        (success? compiled-str) ((. (require "hotpot") "compile_string") buf {})]
    (if success?
      (let [(success? loaded-func) (pcall loadstring compiled-str)]
        (if success?
           (set retval (loaded-func))
           (vim.api.nvim_echo [[loaded-func "ErrorMsg"]] true {})))
      (vim.api.nvim_echo [[compiled-str "ErrorMsg"]] true {})))
  retval)

(fn exec_fennel_range [line1 line2]
  "Execute range from line1 - line2"
  (let [lines (table.concat (get_range_lines line1 line2) "\n")]
     (exec_fennel_str lines)))

(fn exec_fennel_file [fname]
  "Execute file fname"
  (local fname (vim.fn.expand fname))
  (local file (io.open fname))
  (if file
    (let [buf (file:read "*a")]
      (file:close)
      (exec_fennel_str buf))
    (print "File not found")))

(fn exec_fennel [line1 line2 fname]
  "Executes range line1 - line2 when fname isn't provided.
   When fname is provided executes the file.
   Used by :FennelFile command
  "
  (if (= fname "")
    (exec_fennel_range line1 line2)
    (exec_fennel_file fname)))

(fn fennel_operator_eval []
  "Executes range from mark '[ to mark '] set by 'opfunc'"
  (let [line1 (vim.api.nvim_buf_get_mark 0 "[")
        line2 (vim.api.nvim_buf_get_mark 0 "]")]
     (exec_fennel_range line1 line2))
  (if (. (require "hotpot.exec_fennel") "opfunc_backup")
    (tset vim.go "operatorfunc" (. (require "hotpot.exec_fennel") "opfunc_backup"))
    (tset (require "hotpot.exec_fennel") "opfunc_backup"  "")
  ))

(fn exec_fennel_operator []
  "Sets fennel_operator_eval as 'opfunc' and trigures oppending mode"
  (tset (require "hotpot.exec_fennel") "opfunc_backup" vim.go.operatorfunc)
  (tset vim.go "operatorfunc" "v:lua.require'hotpot.exec_fennel'.fennel_operator_eval")
  (vim.api.nvim_feedkeys "g@" "n" false))

(fn define_commands []
  "Defines vimL api"
  (vim.cmd "
   command! -range=% -nargs=? -complete=file FnlFile :lua require'hotpot.exec_fennel'.exec_fennel(<line1>, <line2>, <q-args>)
   command! -nargs=+ Fnl :lua require'hotpot.exec_fennel'.exec_fennel_str(<q-args>)
   au SourceCmd *.fnl :FennelFile <afile>
   nnoremap <Plug>(exec-fennel-operator) :lua require'hotpot.exec_fennel'.exec_fennel_operator()<cr>
   "))

{ : define_commands
  : exec_fennel
  : exec_fennel_str
  : exec_fennel_operator
  : fennel_operator_eval
  :opfunc_backup "" }
