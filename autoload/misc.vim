function! s:TitleCase(text)
    let l:exceptions = ['a', 'an', 'the', 'and', 'but', 'for', 'nor', 'or', 'so', 'yet', 'aboard', 'about', 'above', 'across', 'after', 'against', 'along', 'amid', 'among', 'around', 'as', 'at', 'atop', 'before', 'behind', 'below', 'beneath', 'beside', 'between', 'beyond', 'by', 'despite', 'down', 'during', 'for', 'from', 'in', 'inside', 'into', 'like', 'near', 'of', 'off', 'on', 'onto', 'out', 'outside', 'over', 'past', 'regarding', 'round', 'since', 'than', 'through', 'throughout', 'till', 'to', 'toward', 'under', 'unlike', 'until', 'up', 'upon', 'vs', 'with', 'within', 'without']
    let l:text = a:text
    let l:text = substitute(l:text, '\n$', '', '')
    "" Make lowercase all letters---too radical: trust existing uppercase
    ""let l:text = tolower(l:text)
    " " Make uppercase all new words, but not changing letters following '{' or '}'
    " let l:text = substitute(l:text, '[{}]\@<!\<.', '\u&', 'g')
    " Make uppercase all characters after spaces or dashes
    let l:text = substitute(l:text, '[ -"(]\zs\S', '\u&', 'g')
    for l:word in l:exceptions
        let l:text = substitute(l:text, '\(^\|[:?.!] \)\@<!\<' . l:word . '\>', '\l&', 'g')
    endfor
    "let l:text = substitute(l:text, '\<.\ze\S*$', '\u&', '')
    let l:text = substitute(l:text, '\S''\zs\S', '\l&', 'g')  " lowercase contractions
    let l:text = substitute(l:text, '{\\textemdash}', '---', 'g')
    let l:text = substitute(l:text, '^{.', '\U&', '')  " capitalize first letter
    call setreg('@', l:text, getregtype('@'))
    return l:text
endfunction

function! misc#TidyBibTeX()
    " Fix quotes
    silent %substitute/{\\textquotesingle}/'/ge
    silent %substitute/\(^\s*abstract.*\)\@<!"\([^"]*\)"/\\mkbibquote{\2}/gie
    silent %substitute/\(^\s*abstract.*\)\@<!{\\textquotedblleft}/\\mkbibquote{/ge
    silent %substitute/\(^\s*abstract.*\)\@<!{\\textquotedblright}/}/ge
    " Fix dashes
    silent %substitute/{\\textemdash}/---/ge
    silent %substitute/{\\textendash}/--/ge
    silent %substitute/\(doi =|url =\)\@<!–/--/ge
    silent %substitute/\(doi =|url =\)\@<!—/---/ge
    " Substitute month numbers for month names
    if search('^\s*month = {')
        silent substitute/jan/1/e
        silent substitute/feb/2/e
        silent substitute/mar/3/e
        silent substitute/apr/4/e
        silent substitute/may/5/e
        silent substitute/jun/6/e
        silent substitute/jul/7/e
        silent substitute/aug/8/e
        silent substitute/sep/9/e
        silent substitute/oct/10/e
        silent substitute/nov/11/e
        silent substitute/dec/12/e
    endif
    " Make sure years are in curly braces
    silent %substitute/year = \(\d\+\),/year = {\1},/ge
    if search('^\s*pages = {')
        " Ensure N-dashes are used between numbers in `pages` field
        silent substitute/\(\d\)-\(\d\)/\1--\2/e
        " Compresss page ranges
        silent substitute/\(\d\+\)\(\d\d\)--\1\(\d\d\)/\1\2--\3/e
    endif
    " Don't have both `doi` and `url` fields when `url` field points to doi
    silent! global/^\s*doi =.*\n\s*url.*doi\.org/+d
    " Delete `publisher` field if it's a journal
    if search('^\s*journal = {', 'n')
        silent! global/^\s*publisher = {/d
    endif
    " Delete ISSN field
    silent! global/^\s*issn = {/d
    " Ensure titlecase for titles
    if search('^\s*title = {')
        let l:title = getline('.')
        let l:title = "\ttitle = " . <SID>TitleCase(l:title[9:])
        silent call setline('.', l:title)
    endif
    " Delete all empty lines, go to top
    silent global/^\s*$/delete_
endfunction
