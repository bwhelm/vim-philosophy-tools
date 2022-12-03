scriptencoding utf-8
" ============================================================================
" Bibliographical Search Functions
" ============================================================================

" Path to python file that scrapes search data from philpapers.org
let s:pythonPath = expand('<sfile>:p:h:h')
let s:ppSearchPath = s:pythonPath . '/python/ppsearch.py'

" Note: J-Stor seems to require a real web browser. I'm working around
" this by spoofing headers with s:curlOpt. (Adding this into DOI/PP/URL
" searches as well, just in case they change.)
let s:curlOpt = '-sL '
            \ . '-H "user-agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_7_5)" '
            \ . '-H "accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8" '
            \ . '-H "accept-charset: ISO-8859-1,utf-8;q=0.7,*;q=0.3" '
            \ . '-H "accept-language: en-US,en;q=0.8" '

" Download bibtex citation info from DOI
function! bibsearch#Doi2Bib( ... ) abort  "{{{
    new
    setlocal buftype=nofile bufhidden=hide noswapfile filetype=bib
    let l:saveSearch = @/
    let l:doi = join(a:000, '\\%20')
    if l:doi ==# ''
        let l:doi = input('DOI: ')
    endif
    let l:doi = trim(l:doi)  " Strip off spaces
    if l:doi =~ '^https:\/\/doi.org\/'  " If url, strip off first part
        let l:doi = l:doi[16:]
    endif
    execute 'silent read !curl -sL "https://api.crossref.org/works/' . l:doi . '/transform/application/x-bibtex"'
    " Because we need the year in curly braces....
    %substitute/year\s*=\s*\zs\(\d\+\),/{\1},/ge
    if !search('doi\s*=\s*', 'w')  " Make sure we have a DOI line
        call append(1, "\tdoi = {" . l:doi . "},")
    endif
    silent 0,$yank *
    2
    nnoremap <silent><buffer> q :quit!<CR>
    let @/ = l:saveSearch
endfunction  "}}}

" Search philpapers.org, and return structured list of items.
function! bibsearch#ppsearch( ... ) abort  "{{{
    " Open a new buffer only if current buffer is named or modified
    if bufname() != '' || &modified == 1
        new
    endif
    let l:saveSearch = @/
    let l:query = join(a:000, '\\%20')
    if l:query ==# ''
        let l:query = input('Search Query: ')
        let l:query = trim(l:query)  " Strip off spaces
        if l:query ==# ''
            echohl Comment
            echo 'Search canceled.'
            echohl None
            return
        endif
    endif
    let l:query = substitute(l:query, '\s\+', '\\%20', 'g')
    let l:query = substitute(l:query, '[''"]', '', 'g')
    let l:formattedText = system('python3 "' . s:ppSearchPath . '" ' . l:query)
    let l:formattedList = split(l:formattedText, '\n')
    call append(0, l:formattedList)
    %substitute/\$/\\$/ge
    0
    silent set filetype=ppsearch
    silent set syntax=pandoc
    let @/ = l:saveSearch
endfunction  "}}}

function! s:getAbstract(abstractLine) abort  "{{{
    " This will pull the abstract from the current item.
    if getline(a:abstractLine) =~# '\*\*Abstract:'
        return getline(a:abstractLine)[15:]
    else
        return ''
    endif
endfunction  "}}}
"}}}
function! s:DisplayBibTeX(text, abstract) abort  "{{{
    let l:saveSearch = @/
    pedit BibTeX.bib
    wincmd P
    resize 13
    setlocal buftype=nofile filetype=bib
    setlocal nowrap
    let l:textList = split(a:text, '\n')
    silent call append(0, l:textList)
    0
    " Add abstract from philpapers.org only if there is not one already
    if a:abstract !=# '' && !search('^\s*abstract = {', 'n')
        call append(1, "\tabstract = {" . a:abstract . '},')
    endif
    silent 0,$yank *
    0
    nnoremap <silent><buffer> q :quit!<CR>
    let @/ = l:saveSearch
endfunction  "}}}
"}}}
function! bibsearch#GetJStor(args) abort  "{{{
    if a:args !=# ""
        let l:jstorUrl = trim(join(a:000, ' '))
    else
        let l:jstorUrl = input('J-Stor URL: ')
        let l:jstorUrl = trim(l:jstorUrl)
        if l:jstorUrl ==# ''
            echohl Comment
            echo 'Search canceled.'
            echohl None
            return
        endif
    endif
    let l:text = <SID>getJStor(l:jstorUrl)
    call s:DisplayBibTeX(l:text, '')
endfunction  "}}}
function! s:getJStor(jstorUrl) abort  "{{{
    let l:jstorContent = system('curl ' . s:curlOpt . ' "' . a:jstorUrl . '"')
    let l:jstorDoi = matchstr(l:jstorContent, '"objectDOI"\s*:\s*"\zs[^"]*\ze"')
    let l:url = 'http://www.jstor.org/citation/text/' . l:jstorDoi
    let l:text = system('curl ' . s:curlOpt . ' "' . l:url . '"')
    return l:text
endfunction  "}}}
function! bibsearch#GetBibTeX() abort  "{{{
    " Move to top of current item and retrieve bibliographical data
    normal! {j
    if line('.') == 2
        -1
    endif
    let l:bibLine = matchstr(getline('.'), '\d\+\. \zs.*')
    " Find beginning line of next item
    let l:nextItem = search('^\d\+\.\s', 'Wn')
    silent! -2
    if l:nextItem == 0
        let l:nextItem = 9999
    endif
    let l:jstorLine = search('^\s*\*\*J-Stor:\*\*', 'Wn')
    let l:doiLine = search('^\s*\*\*DOI:', 'Wn')
    let l:ppLine = search('^\s*\*\*PP:\*\*', 'Wn')
    let l:urlLine = search('^\s*\*\*URL:', 'Wn')
    silent! +2
    if l:jstorLine > 0 && l:jstorLine < l:nextItem
        let l:abstract = s:getAbstract(l:jstorLine - 1)
        let l:jstorUrl = getline(l:jstorLine)[14:-2]
        let l:text = <SID>getJStor(l:jstorUrl)
        call s:DisplayBibTeX(l:text, l:abstract)
    elseif l:doiLine > 0 && l:doiLine < l:nextItem
        let l:abstract = s:getAbstract(l:doiLine - 1)
        let l:doi = getline(l:doiLine)[10:]
        let l:url = 'http://api.crossref.org/works/' . l:doi . '/transform/application/x-bibtex'
        let l:text = system('curl ' . s:curlOpt . ' "' . l:url . '"')
        call s:DisplayBibTeX(l:text, l:abstract)
    elseif l:ppLine > 0 && l:ppLine < l:nextItem
        let l:abstract = s:getAbstract(l:ppLine - 1)
        let l:ppUrl = getline(l:ppLine)[10:-2]
        let l:text = system('curl ' . s:curlOpt . ' "' . l:ppUrl . '"')
        let l:text = substitute(l:text, '.*<pre class=''export''>\(@.*\)\n</pre>\_.*', '\1', '')
        call s:DisplayBibTeX(l:text, l:abstract)
    elseif l:urlLine > 0 && l:urlLine < l:nextItem
        let l:url = getline(l:urlLine)[11:-2]
        let l:url = substitute(l:url, '%3f', '?', 'g')
        let l:url = substitute(l:url, '%3d', '=', 'g')
        let l:url = substitute(l:url, '%26', '\&', 'g')
        execute('silent !open "' . l:url . '"')
    else
        call s:DisplayBibTeX('', '')
        echohl WarningMsg
        echo 'No data found. Trying http://glottotopia.org/doc2tex/doc2bib ...'
        echohl None
        let @* = l:bibLine
        silent !open http://glottotopia.org/doc2tex/doc2bib
        return
    endif
endfunction  "}}}
"}}}
