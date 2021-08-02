" Inject hotpot system, or no-op if already done
lua require("hotpot")

" Execute Fennel expression or range from buffer
command! -range=% -nargs=* Fnl
      \ :lua require("hotpot.api.eval").fnl(<line1>, <line2>, <q-args>)

" Execute file
command! -nargs=1 -complete=file Fnlfile
      \ :lua require("hotpot.api.eval").fnlfile(<q-args>)

" Execute expression over range in buffer
command! -range=% -nargs=? Fnldo 
      \ :lua require("hotpot.api.eval").fnldo(<line1>, <line2>, <q-args>)

augroup hotpot.nvim
  autocmd!
  autocmd! SourceCmd *.fnl :Fnlfile <afile>
augroup END

nnoremap <Plug>(exec-fennel-operator)
      \ :lua require("hotpot.api.eval")["eval-operator-bang"]()<cr>
