" ============================================================================
" Bibliographical Search Functions
" ============================================================================

command! Doi2Bib :call bibsearch#Doi2Bib()
command! -nargs=* BibSearch :call bibsearch#BibSearch(<q-args>)
