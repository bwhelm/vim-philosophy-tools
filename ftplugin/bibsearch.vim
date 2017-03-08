function! s:getAbstract(abstractLine)
	" This will pull the abstract from the current item.
	if getline(a:abstractLine) =~ '\*\*Abstract:'
		return getline(a:abstractLine)[15:]
	else
		return ''
	endif
endfunction

function! s:DisplayBibTeX(url, abstract)
    split
    enew
    resize 14
    setlocal nowrap
	setlocal buftype=nofile
	setlocal bufhidden=wipe
    execute 'read !curl -sL "' . a:url . '"'
	silent normal! ggdd
	if a:abstract != ''
		call append(1, '    abstract = {' . a:abstract . '},')
	endif
	try
		%s/{\\textquotesingle}/'/g
		%s/"\([^"]*\)"/\\mkbibquote{\1}/g
	catch /^Vim\%((\a\+)\)\=:E486/
	endtry
	silent set filetype=tex
	silent normal! yG
endfunction

function! s:GetBibTeX()
	" TODO: Perhaps I also want to delete the `url` field (as redundant when
	" there's a `doi` field), and automatically clean up other fields such as
	" `month` (converting month to number).
	" TODO: Make sure the abstract field isn't being duplicated!
	let s:nextItem = search('^\d\+\.\s', 'Wn')
	normal! 2-
	if s:nextItem == 0
		let s:nextItem = 9999
	endif
	let s:jstorLine = search('^\s*\*\*J-Stor:\*\*', 'Wn')
	let s:doiLine = search('^\s*\*\*DOI:', 'Wn')
	let s:urlLine = search('^\s*\*\*URL:', 'Wn')
	normal! 2+
	if s:jstorLine > 0 && s:jstorLine < s:nextItem
		let s:abstract = s:getAbstract(s:jstorLine - 1)
		let s:jstorUrl = getline(s:jstorLine)[14:-2]
		let s:jstorContent = execute('!curl -sL ' . s:jstorUrl)
		let s:jstorDoi = matchstr(s:jstorContent, 'data-doi="\zs[^"]*\ze"')
        let s:url = 'http://www.jstor.org/citation/text/' . s:jstorDoi
		call s:DisplayBibTeX(s:url, s:abstract)
	elseif s:doiLine > 0 && s:doiLine < s:nextItem
		let s:abstract = s:getAbstract(s:doiLine - 1)
		let s:doi = getline(s:doiLine)[10:]
		let s:url = 'http://api.crossref.org/works/' . s:doi . '/transform/application/x-bibtex'
		"execute 'read !curl -sL "http://api.crossref.org/works/' . s:doi . '/transform/application/x-bibtex"'
		call s:DisplayBibTeX(s:url, s:abstract)
	elseif s:urlLine > 0 && s:urlLine < s:nextItem
		let s:url = getline(s:urlLine)[11:-2]
		execute('silent !open ' . s:url)
	else
		echohl WarningMsg
		echom 'No data found.'
		echohl None
		return
	endif
endfunction

nnoremap <silent> <buffer> <CR> :call <SID>GetBibTeX()<CR>
nnoremap <buffer> <C-n> /^\d\+\.\s<CR>zz
nnoremap <buffer> <C-p> ?^\d\+\.\s<CR>zz
