" ============================================================================
" Bibliographical Search Functions
" ============================================================================

let g:PhilPapersSearch#sep_offprint = get(g:, 'PhilPapersSearch#sep_offprint', 'sep-offprint')
let g:PhilPapersSearch#sep_tempfile = get(g:, 'PhilPapersSearch#sep_tempfile', '~/tmp/pandoc/SEP-temp')

command! Doi2Bib :call philpaperssearch#Doi2Bib()
command! -nargs=* PPSearch :call philpaperssearch#PhilpapersSearch(<q-args>)
command! -nargs=* SEPtoMarkdown :call philpaperssearch#SEPtoMarkdown(<q-args>)
