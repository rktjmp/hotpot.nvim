" Inject hotpot system, or no-op if already done
lua require("hotpot")

" Execute Fennel expression
command! -range=% -nargs=* Fnl
      \ :lua require("hotpot.user.eval").fnl(<line1>, <line2>, <q-args>)

command! -nargs=1 -complete=file Fnlfile
      \ :lua require("hotpot.user.eval").fnlfile(<q-args>)

" Mirrors :luado
command! -range=% -nargs=? Fnldo 
      \ :lua require("hotpot.user.eval").fnldo(<line1>, <line2>, <q-args>)

" TODO emergency :HotpotClearCache vim-only command? 

augroup hotpot.nvim
  autocmd!
  autocmd! SourceCmd *.fnl :Fnlfile <afile>
augroup END

nnoremap <Plug>(exec-fennel-operator) :lua require("hotpot.user.eval")["eval-operator-bang"]()<cr>
