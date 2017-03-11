" ============================================================================
" Bibliographical Search Functions
" ============================================================================

" Path to python file that scrapes search data from philpapers.org
let s:pythonPath = expand('<sfile>:p:h:h') . '/python/bibsearch.py'

" Download bibtex citation info from DOI
function! bibsearch#Doi2Bib()
	let l:doi = input('DOI: ')
	let l:doi = matchstr(l:doi, '^\s*\zs\S*\ze\s*$')  " Strip off spaces
	execute 'silent read !curl -s "http://api.crossref.org/works/' . l:doi . '/transform/application/x-bibtex"'
endfunction

" Search philpapers.org, and return structured list of items.
function! bibsearch#BibSearch( ... )
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
	normal! gg
	silent set filetype=bibsearch
	silent set syntax=pandoc
endfunction
