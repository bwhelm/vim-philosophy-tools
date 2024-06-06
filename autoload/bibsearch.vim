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
    execute 'silent 0read !curl -sL "https://api.crossref.org/works/' . l:doi . '/transform/application/x-bibtex"'
    " Because we need the year in curly braces....
    %substitute/year\s*=\s*\zs\(\d\+\),/{\1},/ge
    if !search('doi\s*=\s*', 'w')  " Make sure we have a DOI line
        call append(1, "\tdoi = {" . l:doi . "},")
    endif
    " Get rid of initial spaces
    %substitute/^\s\+@/@/e
    " Spread out entry across multiple lines if needed
    %substitute/,\s*\(\w*\)\s*=\s*/,\r  \1 = /ge
    1
    silent 1,$yank *
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
    let l:pipenv = executable('pipenv') ? "pipenv run " : ""
    let l:formattedText = system(l:pipenv . 'python3 "' . s:ppSearchPath . '" ' . l:query)
    let l:formattedList = split(l:formattedText, '\n')
    call append(0, l:formattedList)
    %substitute/\$/\\$/ge
    1
    silent set filetype=ppsearch
    silent set syntax=pandoc
    let @/ = l:saveSearch
endfunction  "}}}

function! s:getAuthorTitle() abort  " {{{
    call search('^\d\+\.\s*', 'bcW')
    let l:bibline = getline('.')  " Should be the line with author, title data in it.
    let l:author = matchstr(l:bibline, '^\d\+\.\s*\zs.\{-}\ze(\d\+)\.')
    let l:title = matchstr(l:bibline, '(\d\+)\. \zs[^.]*')
    return [l:author, l:title]
endfunction " }}}
function! s:getAbstract(abstractLine) abort  "{{{
    " This will pull the abstract from the current item.
    if getline(a:abstractLine) =~# '    ABSTRACT:'
        return getline(a:abstractLine)[14:]
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
    let l:text = trim(a:text, ' ')
    " HTML codes -> LaTeX
    let l:text = substitute(l:text, '&amp;', '\\\&', 'g')

    let l:text = substitute(l:text, '} }\n\?$', '}}', '')  " Clean end of entry
    let l:text = substitute(l:text, '}\n$', '}', '')  " Clean it also if only on final '}'
    let l:textList = split(l:text, '\n')
    if len(l:textList) == 1  " Failed to split, so it's all on one line
        let l:textList = split(l:text, '\ze\s\+[A-z]\+=')     " Split into lines
    endif
    " " Tidy up the list?
    " call map(l:textList, {key, val -> substitute(val, '^ \+', '  ', '')})
    " call map(l:textList, {key, val -> substitute(val, '={', ' = {', '')})
    silent call append(0, l:textList)
    " Add abstract from philpapers.org only if there is not one already
    if a:abstract !=# '' && !search('^\s*abstract = {', 'n')
        call append(1, " abstract = {" . a:abstract . '},')
    endif
    silent 1,$yank *
    1
    nnoremap <silent><buffer> q :quit!<CR>
    let @/ = l:saveSearch
endfunction  "}}}
"}}}
function! bibsearch#GetJStor(args) abort  "{{{
    if a:args !=# ""
        let l:jstorUrl = trim(a:args)
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
    let l:jstorLine = search('^    J-STOR:', 'Wn')
    let l:doiLine = search('^    DOI:', 'Wn')
    let l:ppLine = search('^    PP:', 'Wn')
    let l:urlLine = search('^    URL:', 'Wn')
    let l:ppidLine = search('^    PP_ID:', 'Wn')
    silent! +2
    if l:jstorLine > 0 && l:jstorLine < l:nextItem
        let l:abstract = s:getAbstract(l:jstorLine - 1)
        let l:jstorUrl = getline(l:jstorLine)[13:-2]
        let l:text = <SID>getJStor(l:jstorUrl)
        call s:DisplayBibTeX(l:text, l:abstract)
    elseif l:doiLine > 0 && l:doiLine < l:nextItem
        let l:abstract = s:getAbstract(l:doiLine - 1)
        let l:doi = getline(l:doiLine)[9:]
        let l:url = 'http://api.crossref.org/works/' . l:doi . '/transform/application/x-bibtex'
        let l:text = system('curl ' . s:curlOpt . ' "' . l:url . '"')
        call s:DisplayBibTeX(l:text, l:abstract)
    elseif l:ppLine > 0 && l:ppLine < l:nextItem
        let l:abstract = s:getAbstract(l:ppLine - 1)
        let l:ppUrl = getline(l:ppLine)[9:-2]
        let l:text = system('curl ' . s:curlOpt . ' "' . l:ppUrl . '"')
        let l:text = substitute(l:text, '\_.*<meta name="citation_format_bib" content="\(@\_.*\)\n">\_.*', '\1', '')
        call s:DisplayBibTeX(l:text, l:abstract)
    elseif l:urlLine > 0 && l:urlLine < l:nextItem
        let l:url = getline(l:urlLine)[10:-2]
        let l:url = substitute(l:url, '%3f', '?', 'g')
        let l:url = substitute(l:url, '%3d', '=', 'g')
        let l:url = substitute(l:url, '%26', '\&', 'g')
        let l:url = substitute(l:url, '%', '\\%', 'g')
        execute('silent !open "' . l:url . '"')
    elseif l:ppidLine > 0 && l:ppidLine < l:nextItem
        let l:ppid = getline(l:ppidLine)[11:]
        let l:abstract = s:getAbstract(l:ppidLine - 1)
        let l:text = system('curl ' . s:curlOpt . ' "https://philpapers.org/export.html?__format=bib&eIds=' . l:ppid . '&formatName=BibTeX"')
        let l:text = substitute(l:text, '.*<pre class="export">\(@.*\)\n</pre>\_.*', '\1', '')
        call s:DisplayBibTeX(l:text, l:abstract)
    else
        echohl WarningMsg
        echo 'No data found. Trying Citoid ...'
        echohl None
        let [l:author, l:title] = <SID>getAuthorTitle()
        let l:author = escape(<SID>urlEncode(l:author), '%')
        let l:title = escape(<SID>urlEncode(l:title), '%')
        let l:abstract = <SID>getAbstract(line('.') + 1)
        let l:text = system("curl -sLX 'GET' 'https://en.wikipedia.org/api/rest_v1/data/citation/bibtex/" . l:author . l:title . "' -H 'accept: application/json; charset=utf-8;'")
        call s:DisplayBibTeX(l:text, l:abstract)
        return
    endif
endfunction  "}}}
" The following two functions are slightly modified from: {{{
" http://www.danielbigham.ca/cgi-bin/document.pl?mode=Display&DocumentID=1053
function! s:urlEncode(string)
    " URL encode a string. ie. Percent-encode characters as necessary.
    let result = ""
    let characters = split(a:string, '.\zs')
    for character in characters
        if <SID>characterRequiresUrlEncoding(character)
            let i = 0
            while i < strlen(character)
                let byte = strpart(character, i, 1)
                let decimal = char2nr(byte)
                let result = result . "%" . printf("%02x", decimal)
                let i += 1
            endwhile
        else
            let result = result . character
        endif
    endfor
    return result
endfunction
function! s:characterRequiresUrlEncoding(character)
    " Returns 1 if the given character should be percent-encoded in a URL encoded string.
    let ascii_code = char2nr(a:character)
    if ascii_code >= 48 && ascii_code <= 57
        return 0
    elseif ascii_code >= 65 && ascii_code <= 90
        return 0
    elseif ascii_code >= 97 && ascii_code <= 122
        return 0
    elseif a:character == "-" || a:character == "_" || a:character == "." || a:character == "~"
        return 0
    endif
    return 1
endfunction
"}}}
