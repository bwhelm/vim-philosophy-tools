" ============================================================================
" Bibliographical Search Functions
" ============================================================================

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
	let s:htmlText = execute('!curl -s "https://philpapers.org/s/' . s:query . '"')
	let s:htmlText = substitute(s:htmlText, '\_.*\(<ol.\{-}<\/ol>\)\_.*', '\1', '')
	let s:htmlText = substitute(s:htmlText, '', '', 'g')
	let s:htmlText = substitute(s:htmlText, '<li id=\_[^>]*>', '<li>', 'g')
	let s:htmlText = substitute(s:htmlText, '<\/\?span[^>]*>', '', 'g')
	let s:htmlText = substitute(s:htmlText, ' (...)', '', 'g')
	let s:htmlText = substitute(s:htmlText, ' (shrink)', '', 'g')
	let s:htmlText = substitute(s:htmlText, '<div class="abstract">\(.\{-}\)</div>', '%%%Abstract: \1%%%', 'g')
	let s:htmlText = substitute(s:htmlText, '<\/\?div[^>]*>', '', 'g')
	let s:htmlText = substitute(s:htmlText, '<a[^>]*href=''\/.\{-}<\/a>', '', 'g')
	let s:htmlText = substitute(s:htmlText, '<a class=''discreet''[^>]*>\(.\{-}\)<\/a>', '---\1', 'g')
	let s:htmlText = substitute(s:htmlText, '<a\s*rel="nofollow"[^\n]*dx\.doi\.org%2F\([^"]*\)"[^\n]*<\/a>', '%%%DOI: \1%%%', 'g')
	let s:htmlText = substitute(s:htmlText, '<a\s*rel="nofollow"[^\n]*www\.jstor\.org%2F\([^"]*\)"[^\n]*<\/a>', '%%%J-Stor: http://www.jstor.org/\1%%%', 'g')
	let s:htmlText = substitute(s:htmlText, '<a\s*target=''_blank''[^>]*>\(.\{-}\)<\/a>', '\1', 'g')
	let @o = s:htmlText
	silent put o
	silent 0,$!pandoc -f html -t markdown --wrap=none
	silent g/^\d\+\./normal! o
	silent g/%%%DOI:/s/%%%DOI: \(.\{-}\)%%%.*/\r\t\r\tDOI:\r\t:\t\1\r\r/g
	silent g/%%%J-Stor:/s/%%%J-Stor: \(.\{-}\)%%%.*/\r\t\r\tJ-Stor:\r\t:\t\1\r\r/g
	silent g/^\t:\t/s/%2F/\//g
	silent g/%%%Abstract: /s/^\(.\{-}\)%%%Abstract: \(.\{-}\)%%%.*/\1\r\t\r\tAbstract:\r\t:\t\2\r\r
	try
		silent %s/\n\n\n/\r/g
		silent %s/\.details.*/./g
		silent %s/\*\*//g
	catch /^Vim\%((\a\+)\)\=:E486/
	endtry
	normal! gg
	silent set filetype=bibsearch
	silent set syntax=pandoc
endfunction
