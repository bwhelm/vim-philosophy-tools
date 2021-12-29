" Convert given text to title case
function! s:TitleCase(text) abort  " {{{
    let l:text = a:text
    let l:text = substitute(l:text, '\n$', '', '')

    try
        python3 from titlecase import titlecase
        let l:new = []
        for l:line in split(l:text, '\n')
            call add(l:new, py3eval("titlecase('" . escape(l:line, "'") . "')"))
        endfor
        let l:text = join(l:new, "\r")
    catch  /ImportError/
        echohl WarningMsg
        echom "Can't use python3 ... fallback to vimscript"
        echohl None
        let l:exceptions = ['a', 'an', 'the', 'and', 'but', 'for', 'nor',
                    \ 'or', 'so', 'yet', 'aboard', 'about', 'above', 'across',
                    \ 'after', 'against', 'along', 'amid', 'among', 'around',
                    \ 'as', 'at', 'atop', 'before', 'behind', 'below', 'beneath',
                    \ 'beside', 'between', 'beyond', 'by', 'despite', 'down',
                    \ 'during', 'for', 'from', 'in', 'inside', 'into', 'like',
                    \ 'near', 'of', 'off', 'on', 'onto', 'out', 'outside', 'over',
                    \ 'past', 'regarding', 'round', 'since', 'than', 'through',
                    \ 'throughout', 'till', 'to', 'toward', 'under', 'unlike',
                    \ 'until', 'up', 'upon', 'vs', 'with', 'within', 'without']
        let l:text = tolower(l:text)
        let l:text = substitute(l:text, '\<.', '\u&', 'g')
        for l:word in l:exceptions
            let l:text = substitute(l:text, '\(^\|[:?.!] \)\@<!\<' . l:word . '\>', '\l&', 'g')
        endfor
        let l:text = substitute(l:text, '\<.\ze\S*$', '\u&', '')
        let l:text = substitute(l:text, '\S''\zs\s', '\l&', 'g')
    endtry

    let l:text = substitute(l:text, '{\\textemdash}', '---', 'g')
    call setreg('@', l:text, getregtype('@'))
    return l:text
endfunction
" }}}
" Clean up BibTeX scraped from web
function! misc#TidyBibTeX() abort
    let l:saveSearch = @/
    " Fix quotes
    %substitute/{\\textquotesingle}/'/ge
    silent global/^\s*abstract\s*=\s*{/substitute/"\([^"]*\)"/\\mkbibquote{\1}/gie
    silent global/^\s*abstract\s*=\s*{/substitute/{\\textquotedblleft}/\\mkbibquote{/ge
    silent global/^\s*abstract\s*=\s*{/substitute/{\\textquotedblright}/}/ge
    " Fix dashes
    %substitute/{\\textemdash}/---/ge
    %substitute/{\\textendash}/--/ge
    %substitute/\(doi =|url =\)\@<!–/--/ge
    %substitute/\(doi =|url =\)\@<!—/---/ge
    " Substitute month numbers for month names
    silent global/^\s*month\s*=\s*{/substitute/jan/1/e
    silent global/^\s*month\s*=\s*{/substitute/feb/2/e
    silent global/^\s*month\s*=\s*{/substitute/mar/3/e
    silent global/^\s*month\s*=\s*{/substitute/apr/4/e
    silent global/^\s*month\s*=\s*{/substitute/may/5/e
    silent global/^\s*month\s*=\s*{/substitute/jun/6/e
    silent global/^\s*month\s*=\s*{/substitute/jul/7/e
    silent global/^\s*month\s*=\s*{/substitute/aug/8/e
    silent global/^\s*month\s*=\s*{/substitute/sep/9/e
    silent global/^\s*month\s*=\s*{/substitute/oct/10/e
    silent global/^\s*month\s*=\s*{/substitute/nov/11/e
    silent global/^\s*month\s*=\s*{/substitute/dec/12/e
    " Make sure years are in curly braces
    %substitute/^\s*year = \zs\(\d\+\),/{\1},/ge
    if search('^\s*pages = {', 'w')
        " Ensure N-dashes are used between numbers in `pages` field
        substitute/\(\d\)-\(\d\)/\1--\2/e
        " Compresss page ranges
        substitute/\(\d\+\)\(\d\d\)--\1\(\d\d\)/\1\2--\3/e
    endif
    " Don't have both `doi` and `url` fields when `url` field points to doi
    silent global/^\s*doi =.*\n\s*url.*doi\.org/+d
    " Delete `publisher` field if it's a journal
    if search('^\s*journal = {', 'n')
        silent global/^\s*publisher = {/d
    endif
    " Delete ISSN field
    silent global/^\s*issn = {/d
    " Ensure titlecase for titles
    if search('^\s*title = {')
        let l:title = getline('.')
        let l:title = "\ttitle = " . <SID>TitleCase(l:title[9:])
        silent call setline('.', l:title)
    endif
    " Delete all empty lines and add blank line at bottom
    silent global/^\s*$/delete_
    $put_
    let @/ = l:saveSearch
endfunction
