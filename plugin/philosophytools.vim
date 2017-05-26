" ============================================================================
" Bibliographical Search Functions
" ============================================================================

let g:philosophytools#sep_offprint = get(g:, 'philosophytools#sep_offprint', 'sep-offprint')
let g:philosophytools#sep_tempfile = get(g:, 'philosophytools#sep_tempfile', '~/tmp/SEP/SEP-temp')

command! Doi2Bib :call philosophytools#Doi2Bib()
command! -nargs=* PPSearch :call philosophytools#ppsearch(<q-args>)
command! -nargs=1 SEPtoMarkdown :call philosophytools#SEPtoMarkdown(<q-args>)
