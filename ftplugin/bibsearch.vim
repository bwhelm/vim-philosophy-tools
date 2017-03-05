function! s:getAbstract(abstractLine)
	" This will pull the abstract from the current item.
	if getline(a:abstractLine) =~ 'Abstract:'
		return getline(a:abstractLine + 1)[3:]
	else
		return ''
	endif
endfunction

function! s:GetDOI()
	" TODO: Perhaps I also want to delete the `url` field (as redundant when
	" there's a `doi` field), and automatically clean up other fields such as
	" `month` (converting month to number).
	" TODO: Make sure the abstract field isn't being duplicated!
	let s:nextItem = search('^\d\+\.', 'Wn')
	normal! 2-
	if s:nextItem == 0
		let s:nextItem = 9999
	endif
	let s:jstorLine = search('^\s*J-Stor:', 'Wn')
	messages clear
	let s:doiLine = search('^\s*DOI:', 'Wn')
	normal! 2+
	if s:jstorLine > 0 && s:jstorLine < s:nextItem
		let s:abstract = s:getAbstract(s:jstorLine - 3)
		let s:jstorUrl = getline(s:jstorLine + 1)[3:]
		"let s:jstorUrl = matchstr(getline(s:jstorLine + 1), '^\s:\s\zs.*')
		let s:jstorContent = execute('!curl -sL ' . s:jstorUrl)
		let s:jstorDoi = matchstr(s:jstorContent, 'data-doi="\zs[^"]*\ze"')
		split
		enew
		execute 'silent read !curl -sL "http://www.jstor.org/citation/text/' . s:jstorDoi . '"'
	elseif s:doiLine > 0 && s:doiLine < s:nextItem
		let s:abstract = s:getAbstract(s:doiLine - 3)
		let s:doi = matchstr(getline(s:doiLine + 1), ':\s*\zs\S*')
		split
		enew
		execute 'silent read !curl -sL "http://api.crossref.org/works/' . s:doi . '/transform/application/x-bibtex"'
	else
		echohl WarningMsg
		echom 'No data found.'
		echohl None
		return
	endif
	if s:abstract != ''
		normal! gg+
		let @o = '    abstract = {' . s:abstract . '},'
		put o
	endif
	try
		%s/{\\textquotesingle}/'/g
		%s/"\([^"]*\)"/\\mkbibquote{\1}/g
	catch /^Vim\%((\a\+)\)\=:E486/
	endtry
	silent normal! ggddyG
	silent set filetype=tex
endfunction

command! GetDOI :call <SID>GetDOI()
nnoremap <buffer> <CR> :GetDOI<CR>
