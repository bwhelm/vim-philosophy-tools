scriptencoding utf-8
" ============================================================================
" Bibliographical Search Functions
" ============================================================================

" Path to python file that scrapes search data from philpapers.org
let s:pythonPath = expand('<sfile>:p:h:h') . '/python/ppsearch.py'

" Download bibtex citation info from DOI
function! bibsearch#Doi2Bib( ... ) abort
    new
    setlocal buftype=nofile bufhidden=hide noswapfile filetype=bib
    let l:saveSearch = @/
    let l:doi = join(a:000, '\\%20')
    if l:doi ==# ''
        let l:doi = input('DOI: ')
    endif
    let l:doi = trim(l:doi)  " Strip off spaces
    execute 'silent read !curl -sL "https://api.crossref.org/works/' . l:doi . '/transform/application/x-bibtex"'
    " Because we need the year in curly braces....
    %substitute/year\s*=\s*\zs\(\d\+\),/{\1},/ge
    if !search('doi\s*=\s*', 'w')  " Make sure we have a DOI line
        call append(1, "\tdoi = {" . l:doi . "},% I added this!")
    endif
    " Tidy BibTeX
    call misc#TidyBibTeX()
    silent 0,$yank *
    0
    let @/ = l:saveSearch
endfunction

" Search philpapers.org, and return structured list of items.
function! bibsearch#ppsearch( ... ) abort
    let l:saveSearch = @/
    let l:query = join(a:000, '\\%20')
    if l:query ==# ''
        let l:query = input('Search Query: ')
        let l:query = matchstr(l:query, '^\s*\zs.\{-}\ze\s*$')  " Strip off spaces
        if l:query ==# ''
            echohl Comment
            echom 'Search canceled.'
            echohl None
            return
        endif
    endif
    let l:query = substitute(l:query, '\s\+', '\\%20', 'g')
    let l:query = substitute(l:query, '[''"]', '', 'g')
    let l:formattedText = system('python3 "' . s:pythonPath . '" ' . l:query)
    let l:formattedList = split(l:formattedText, '\n')
    call append(0, l:formattedList)
    %substitute/\$/\\$/ge
    0
    silent set filetype=ppsearch
    silent set syntax=pandoc
    let @/ = l:saveSearch
endfunction
