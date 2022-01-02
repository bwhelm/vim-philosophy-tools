function! misc#OpenUrl() abort  "{{{
    " This will search current buffer for a `doi` or `URL` field and then open
    " a browser to the relevant web address.
    if search('^\s*doi\s*=\s*{')
        let l:doi = matchstr(getline('.'), '=\s*{\zs.*\ze}')
        silent execute '!open http://doi.org/' . l:doi
    elseif search('^\s*url = {')
        let l:url = getline('.')[8:-3]
        echom l:url
        silent execute '!open "' . l:url . '"'
    endif
endfunction
"}}}
