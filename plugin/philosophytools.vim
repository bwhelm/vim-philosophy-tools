" ============================================================================
" Bibliographical Search Functions
" ============================================================================

let g:philosophytools#sep_offprint = get(g:, 'philosophytools#sep_offprint', 'sep-offprint')
let g:philosophytools#sep_tempfile = get(g:, 'philosophytools#sep_tempfile', '~/tmp/SEP/SEP-temp')

command! -nargs=* Doi2Bib :call bibsearch#Doi2Bib(<q-args>)
command! -nargs=* JStor2Bib :call bibsearch#GetJStor(<q-args>)
command! -nargs=* PPSearch :call bibsearch#ppsearch(<q-args>)
command! -nargs=1 SEPtoMarkdown :call SEPscrape#SEPtoMarkdown(<q-args>)
