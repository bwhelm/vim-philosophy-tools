" ============================================================================
" Bibliographical Search Functions
" ============================================================================

command! Doi2Bib :call philpaperssearch#Doi2Bib()
command! -nargs=* PPSearch :call philpaperssearch#PhilpapersSearch(<q-args>)
