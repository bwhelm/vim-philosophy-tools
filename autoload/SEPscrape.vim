scriptencoding utf-8
" ============================================================================
" Get SEP article (to convert to .pdf)
" ============================================================================

function! s:GetSEPFiles(entry,tempDir) abort
    silent execute 'cd ' . a:tempDir
    silent call system('rm *')
    silent execute 'read !wget -r --no-parent --no-directories --no-verbose "https://plato.stanford.edu/entries/' . a:entry . '/"'
    silent global!/->/delete_
    silent! %substitute/.*-> "\([^"]*\)".*/\1/g
    silent global/^robots.txt$/delete_
    silent global/\.\d$/delete_
    let l:notes = getline(search('notes\.html'))
    return [getline(0, '$'), l:notes]
endfunction

function! s:PrepareHTML() abort
    let l:line = search('\n<div id="article">', 'nW') 
    silent execute '1,' . l:line . 'delete_'
    silent call search('^<\/div> <!-- End article -->\n\n', 'e')
    silent ,$delete_
    silent call search('<div id="academic-tools">')
    let l:line = search('<div id="other-internet-resources">', 'n') - 1
    silent execute ',' . l:line . 'delete_'
    silent write
endfunction

function! s:StripHTMLHeaderFooter(htmlFileList) abort
    " Strip header and footer from all but the main file
    for l:fileName in a:htmlFileList
        silent execute 'edit! ' . l:fileName
        silent call search('<!--DO NOT MODIFY THIS LINE AND ABOVE-->')
        silent 1,delete_
        silent call search('<!--DO NOT MODIFY THIS LINE AND BELOW-->')
        silent ,$delete_
        silent! global/^<\/\?div/delete_
        silent write
    endfor
endfunction

function! s:ShowBibTeX(entry, abstract) abort
    " Scrape bibliographic data from SEP website
    let l:bibscrape = system('curl -sL "https://plato.stanford.edu/cgi-bin/encyclopedia/archinfo.cgi?entry=' . a:entry . '"')
    let l:bibtex = matchstr(l:bibscrape, '<pre>\zs@InCollection\_.*\ze<\/pre>')
    let l:bibtex = substitute(l:bibtex, "\\t", '    ', 'g')
    pedit BibTeX.bib
    wincmd P
    resize 13
    setlocal buftype=nofile
    setlocal nowrap
    silent call append(0, split(l:bibtex, '\n'))
    silent call append(3, '    abstract     =  {' . a:abstract . '},')
    silent 0,$yank *
    0
    nnoremap <silent><buffer> q :quit!<CR>
endfunction

function! s:PrepareMarkdown(htmlFileList, notes, entry) abort
    " Create markdown file compiled from all .html files, with index.html first
    " and notes.html (if any) last.
    silent execute '%!pandoc -t markdown+table_captions-simple_tables-multiline_tables+grid_tables+pipe_tables+line_blocks-fancy_lists+definition_lists+example_lists-fenced_divs --wrap=none --atx-headers --standalone index.html ' . join(a:htmlFileList, ' ') . ' ' . a:notes . ' -o index.md'
    silent edit! index.md
    " Scrape article metadata
    1
    silent call search('^# ')
    let l:title = getline('.')[2:]
    silent call search('<div id="pubinfo">\n\n\*', 'e')
    let l:date = getline('.')
    let l:date = substitute(l:date, '\**\(.\{-}\)\**$', '\1', '')
    let l:author = getline(search('^\[Copyright © \d\+\]', 'nW') + 1)
    let l:author = substitute(l:author, '\\<', '', 'g')
    let l:author = substitute(l:author, '\\>', '', 'g')
    " Strip header
    silent call search('^<div id="preamble">')
    silent 1,delete_
    " Take first paragraph of preamble as abstract
    +1
    let l:abstract = getline('.')
    " Strip TOC
    silent call search('^<div id="toc">')
    let l:line = search('^<div id="main-text">', 'n')
    execute 'silent ,' . l:line . 'delete_'
    " Remove unwanted <div> and </div>
    silent global/^<\/\?div/d
    " Add new YAML header
    silent execute "normal! ggO---\<CR>title: \"" . l:title . "\"\<CR>author: \"" . l:author . "\"\<CR>date: \"" . l:date . "\"\<CR>lualatex: true\<CR>fancyhdr: headings\<CR>fontsize: 11pt\<CR>geometry: ipad\<CR>numbersections: true\<CR>toc: true\<CR>---\<CR>"
    " Fix (sub)sections
    silent! %substitute/^#\(#*\) \[[0-9.]\+ \([^]]*\)\].*/\1 \2/g
    silent call search('^## \[Bibliography')
    normal! cc# Bibliography {-}
    " Set off copyright; strip references to SEP tools, etc.
    +1
    silent! ,$substitute/^#\(#*\)\( .*\)/\1\2 {-}/g
    silent call search('^[Copyright')
    -2
    silent normal! 76i-
    silent execute "normal! o\<CR>::: center\<CR>"
    +5
    silent execute "normal! o:::\<CR>\<CR>"
    silent normal! 76i-
    silent execute "normal! \<CR>\<CR>"
    normal! d/^##
    " Handle footnotes
    silent! %substitute/\^\\\[\[\(\d\+\)\](notes.html[^^]*\^/[^\1]/g
    silent! %substitute/^\[\(\d\+\)\.\](index.html[^}]*}/[^\1]: /g
    silent global/^# Notes to \[[^]]*\](index.html)/delete_
    " Fix links
    silent! %substitute/](\.\./](https:\/\/plato.stanford.edu\/entries/g
    silent write
    normal! gg
    call <SID>ShowBibTeX(a:entry, l:abstract)
endfunction

" Get markdown file from SEP
function! SEPscrape#SEPtoMarkdown(entry) abort
    let l:tempDir = fnamemodify('~/tmp/SEP', ':p')
    let [l:fileList, l:notes] = <SID>GetSEPFiles(a:entry, l:tempDir)
    let l:htmlFileList = filter(l:fileList, 'v:val =~ "\.html"')
    call filter(l:htmlFileList, 'v:val !~ "index\."')
    let l:htmlFileList = filter(l:htmlFileList, 'v:val !~ "\(index\|notes\).html"')
    call <SID>StripHTMLHeaderFooter(l:htmlFileList)
    silent edit! index.html
    call <SID>PrepareHTML()
    call filter(l:htmlFileList, 'v:val !~ "notes\."')
    call <SID>PrepareMarkdown(l:htmlFileList, l:notes, a:entry)
endfunction
