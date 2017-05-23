scriptencoding utf-8
" ============================================================================
" Bibliographical Search Functions
" ============================================================================

" Path to python file that scrapes search data from philpapers.org
let s:pythonPath = expand('<sfile>:p:h:h') . '/python/philpaperssearch.py'

" Download bibtex citation info from DOI
function! philpaperssearch#Doi2Bib()
	let l:doi = input('DOI: ')
	let l:doi = matchstr(l:doi, '^\s*\zs\S*\ze\s*$')  " Strip off spaces
	execute 'silent read !curl -s "http://api.crossref.org/works/' . l:doi . '/transform/application/x-bibtex"'
	" Because we need the year in curly braces....
	%substitute/year = \(\d\+\),/year = {\1},/ge
endfunction

" Search philpapers.org, and return structured list of items.
function! philpaperssearch#PhilpapersSearch( ... )
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
	let l:formattedText = system('python ' . s:pythonPath . ' ' . l:query)
	let l:formattedList = split(l:formattedText, '\n')
	call append(0, l:formattedList)
	0
	silent set filetype=ppsearch
	silent set syntax=pandoc
endfunction

" Get markdown file from SEP
function! philpaperssearch#SEPtoMarkdown( ... )
	let l:entry = join(a:000, '')
	let l:file = fnamemodify(g:PhilPapersSearch#sep_tempfile, ':p')
	execute '!' . g:PhilPapersSearch#sep_offprint . ' --output ' . l:file . ' --md ' . l:entry
	execute 'edit ' . l:file . '.md'
	let l:text = join(getline(0, line('$')), "\n")
	let l:date = getline(search('^<div id="pubinfo">$', 'nW') + 2)
	let l:author = getline(search('^\[Copyright © \d\+\]', 'nW') + 1)
	let l:author = substitute(l:author, '&lt;', '', 'g')
	let l:author = substitute(l:author, '&gt;', '', 'g')
	let l:title = getline(search('^<div id="aueditable">', 'nW') + 2)[2:]
	let l:abstract = getline(search('^<div id="preamble">', 'nW') + 2)
	call search('^<div id="main-text">')
	silent 0,delete_
	call search('^<\/div>\n\n<div id="bibliography">')
	silent ,+2delete_
	call search('^<\/div>')
	silent ,$delete_
	execute "normal! ggO---\<CR>title: \"" . l:title . "\"\<CR>author: \"" . l:author . "\"\<CR>date: \"" . l:date . "\"\<CR>abstract: |\<CR>\t" . l:abstract . "\<CR>\<BS>lualatex: true\<CR>fancyhdr: fancy\<CR>fontsize: 11pt\<CR>geometry: ipad\<CR>numbersections: true\<CR>---\<CR>"
	silent! %substitute/^#\(#*\) \[[0-9.]\+ \([^]]*\)\].*/\1 \2 /g
	call search('^## \[Bibliography')
	normal! cc# Bibliography {-}
	normal! gg
	write
endfunction
