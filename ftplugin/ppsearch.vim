" vim: set fdm=marker:
" ============================================================================

scriptencoding utf-8

nnoremap <silent><buffer> <CR> :call bibsearch#GetBibTeX()<CR>
nnoremap <silent><buffer> <C-n> /^\d\+\.\s<CR>zz
nnoremap <silent><buffer> <C-p> ?^\d\+\.\s<CR>zz
nnoremap <silent><buffer> <LocalLeader>d :call <SID>sortParagraphs('sort! r /(\d\+)/')<CR>
nnoremap <silent><buffer> <LocalLeader>n :call <SID>sortParagraphs('sort /\d\+\./')<CR>
nnoremap <silent><buffer> <LocalLeader>o :call <SID>sortParagraphs('sort n')<CR>

function! s:sortParagraphs(sort) abort  " {{{
    let l:saveLine = getline('.')
    let l:saveCol = col('.')
    1

    " Combine paragraphs into single lines
    global/./normal! ALINEBREAK
    silent %substitute/LINEBREAK\n/LINEBREAK/e

    " Execute the sort
    execute a:sort

    " Back to paragraphs and find former line/position
    silent %substitute/LINEBREAK/\r/ge
    call search('\M' . l:saveLine[:-1], '')
    call cursor('.', l:saveCol)
endfunction " }}}
