" vim: set fdm=marker:
" ============================================================================

scriptencoding utf-8

function! s:getAbstract(abstractLine) abort  "{{{
    " This will pull the abstract from the current item.
    if getline(a:abstractLine) =~# '\*\*Abstract:'
        return getline(a:abstractLine)[15:]
    else
        return ''
    endif
endfunction
"}}}
function! s:OpenUrl() abort  "{{{
    " This will search current buffer for a `doi` or `URL` field and then open
    " a browser to the relevant web address.
    if search('^\s*doi = {')
        let l:doi = getline('.')[8:-3]
        silent execute '!open http://doi.org/' . l:doi
    elseif search('^\s*url = {')
        let l:url = getline('.')[8:-3]
        echom l:url
        silent execute '!open "' . l:url . '"'
    endif
endfunction
"}}}
function! s:DisplayBibTeX(text, abstract) abort  "{{{
    let l:saveSearch = @/
    pedit BibTeX.bib
    wincmd P
    resize 13
    setlocal buftype=nofile
    setlocal nowrap
    let l:textList = split(a:text, '\n')
    silent call append(0, l:textList)
    0
    " Add abstract from philpapers.org only if there is not one already
    if a:abstract !=# '' && !search('^\s*abstract = {', 'n')
        call append(1, "\tabstract = {" . a:abstract . '},')
    endif
    " Break undo sequence
    execute "normal! i\<C-G>u\<Esc>"
    " Consistent indentation
    silent %substitute/^\s\+/\t/e
    " Tidy BibTeX
    call misc#TidyBibTeX()
    silent 0,$yank *
    0
    " Set up mapping for BibTeX preview window to jump to url
    nnoremap <silent><buffer> gx :call <SID>OpenUrl()<CR>
    nnoremap <silent><buffer> q :quit!<CR>
    let @/ = l:saveSearch
endfunction
"}}}
function! s:GetBibTeX() abort  "{{{
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
    " Note: J-Stor seems to require a real web browser. I'm working around
    " this by spoofing headers with l:curlOpt. (Adding this into DOI/PP/URL
    " searches as well, just in case they change.)
    let l:curlOpt = '-sL '
                \ . '-H "user-agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_7_5)" '
                \ . '-H "accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8" '
                \ . '-H "accept-charset: ISO-8859-1,utf-8;q=0.7,*;q=0.3" '
                \ . '-H "accept-language: en-US,en;q=0.8" '
    if l:jstorLine > 0 && l:jstorLine < l:nextItem
        let l:abstract = s:getAbstract(l:jstorLine - 1)
        let l:jstorUrl = getline(l:jstorLine)[14:-2]
        let l:jstorContent = system('curl ' . l:curlOpt . ' "' . l:jstorUrl . '"')
        let l:jstorDoi = matchstr(l:jstorContent, 'data-doi="\zs[^"]*\ze"')
        let l:url = 'http://www.jstor.org/citation/text/' . l:jstorDoi
        let l:text = system('curl ' . l:curlOpt . ' "' . l:url . '"')
        call s:DisplayBibTeX(l:text, l:abstract)
    elseif l:doiLine > 0 && l:doiLine < l:nextItem
        let l:abstract = s:getAbstract(l:doiLine - 1)
        let l:doi = getline(l:doiLine)[10:]
        let l:url = 'http://api.crossref.org/works/' . l:doi . '/transform/application/x-bibtex'
        let l:text = system('curl ' . l:curlOpt . ' "' . l:url . '"')
        call s:DisplayBibTeX(l:text, l:abstract)
    elseif l:ppLine > 0 && l:ppLine < l:nextItem
        let l:abstract = s:getAbstract(l:ppLine - 1)
        let l:ppUrl = getline(l:ppLine)[10:-2]
        let l:text = system('curl ' . l:curlOpt . ' "' . l:ppUrl . '"')
        let l:text = substitute(l:text, '.*<pre class=''export''>\(@.*\)\n</pre>\_.*', '\1', '')
        call s:DisplayBibTeX(l:text, l:abstract)
    elseif l:urlLine > 0 && l:urlLine < l:nextItem
        let l:url = getline(l:urlLine)[11:-2]
        let l:url = substitute(l:url, '%3f', '?', 'g')
        let l:url = substitute(l:url, '%3d', '=', 'g')
        let l:url = substitute(l:url, '%26', '\&', 'g')
        execute('silent !open "' . l:url . '"')
    else
        echohl WarningMsg
        echom 'No data found.'
        echohl None
        return
    endif
endfunction
"}}}
function! s:SortDate() abort  "{{{
    %substitute/$/#@!MyEoLsTrInG/
    global/^\w/s/^/\r/
    1move $
    global/^\w/,/^$/-1join!
    global/^$/d_
    sort! /.\{-}(/
    %substitute/#@!MyEoLsTrInG/\r/g
    %substitute/\n\n\n/\r\r/
    1
endfunction
"}}}
nnoremap <silent><buffer> <CR> :call <SID>GetBibTeX()<CR>
nnoremap <silent><buffer> <C-n> /^\d\+\.\s<CR>zz
nnoremap <silent><buffer> <C-p> ?^\d\+\.\s<CR>zz
command! -buffer SortDate :silent call <SID>SortDate()<CR>
