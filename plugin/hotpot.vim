lua require("hotpot")

command! -range=% -nargs=? -complete=file Fnlfile :lua require("hotpot.user.eval").fnlfile(<line1>, <line2>, <q-args>)
command! -nargs=+ Fnl :lua require("hotpot.user.eval")["eval-string"](<q-args>)

augroup hotpot.nvim
  autocmd!
  autocmd! SourceCmd *.fnl :Fnlfile <afile>
augroup END

nnoremap <Plug>(exec-fennel-operator) :lua require("hotpot.user.eval")["eval-operator-bang"]()<cr>
