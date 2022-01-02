" vim: set fdm=marker:
" ============================================================================

scriptencoding utf-8

nnoremap <silent><buffer> <CR> :call bibsearch#GetBibTeX()<CR>
nnoremap <silent><buffer> <C-n> /^\d\+\.\s<CR>zz
nnoremap <silent><buffer> <C-p> ?^\d\+\.\s<CR>zz
