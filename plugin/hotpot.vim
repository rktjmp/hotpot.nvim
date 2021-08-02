" Inject hotpot system, or no-op if already done
lua require("hotpot")

" Mirrors :lua
command! -nargs=+ Fnl :lua require("hotpot.user.eval")["eval-string"](<q-args>)

" Mirrors :luafile
command! -range=% -nargs=? -complete=file Fnlfile :lua require("hotpot.user.eval").fnlfile(<line1>, <line2>, <q-args>)

" Mirrors :luado
command! -range=% -nargs=? Fnldo :lua require("hotpot.user.eval").fnldo(<line1>, <line2>, <q-args>)

" TODO emergency :HotpotClearCache vim-only command? 

augroup hotpot.nvim
  autocmd!
  autocmd! SourceCmd *.fnl :Fnlfile <afile>
augroup END

nnoremap <Plug>(exec-fennel-operator) :lua require("hotpot.user.eval")["eval-operator-bang"]()<cr>
