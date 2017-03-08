" ============================================================================
" Bibliographical Search Functions
" ============================================================================

let s:pythonPath = expand('<sfile>:p:h:h') . '/python/bibsearch.py'

" Download bibtex citation info from DOI
function! bibsearch#Doi2Bib()
	let s:doi = input("DOI: ")
	let s:doi = matchstr(s:doi, '^\s*\zs\S*\ze\s*$')  " Strip off spaces
	execute 'silent read !curl -s "http://api.crossref.org/works/' . s:doi . '/transform/application/x-bibtex"'
endfunction

" Search philpapers.org, and return structured list of items.
function! bibsearch#BibSearch( ... )
	let s:query = join(a:000, '+')
	if s:query == ''
		let s:query = input("Search Query: ")
		let s:query = matchstr(s:query, '^\s*\zs.\{-}\ze\s*$')  " Strip off spaces
		if s:query == ''
			echohl Comment
			echom 'Search canceled.'
			echohl None
			return
		endif
	endif
	let s:query = substitute(s:query, '\s\+', '\\%20', 'g')
	let s:formattedText = system('python ' . s:pythonPath . ' ' . s:query)
	let s:formattedList = split(s:formattedText, '\n')
	let s:null = append(0, s:formattedList)
	normal! gg
	silent set filetype=bibsearch
	silent set syntax=pandoc
endfunction
