" Inject hotpot system, or no-op if already done
lua require("hotpot")

" Execute Fennel expression or range from buffer
command! -range=% -nargs=* Fnl
      \ :lua require("hotpot.api.command").fnl(<line1>, <line2>, <q-args>, <range>)

" Execute file
command! -nargs=1 -complete=file Fnlfile
      \ :lua require("hotpot.api.command").fnlfile(<q-args>)

" Execute expression over range in buffer
command! -range=% -nargs=? Fnldo
      \ :lua require("hotpot.api.command").fnldo(<line1>, <line2>, <q-args>)

command! -nargs=1 -complete=file Fnlsource
      \ :lua require("hotpot.api.source").source(<q-args>)

augroup hotpot_nvim
  autocmd!
  " need a command so we can actually use <afile>, :lua won't expand
  autocmd! SourceCmd *.fnl :Fnlsource <afile>:p
augroup END

nnoremap <Plug>(hotpot-operator-eval)
      \ :lua require("hotpot.api.command")["eval-operator-bang"]()<cr>
