scriptencoding utf-8

function! s:TitleCase(text)
	let l:exceptions = ['a', 'an', 'the', 'and', 'but', 'for', 'nor', 'or', 'so', 'yet', 'aboard', 'about', 'above', 'across', 'after', 'against', 'along', 'amid', 'among', 'around', 'as', 'at', 'atop', 'before', 'behind', 'below', 'beneath', 'beside', 'between', 'beyond', 'by', 'despite', 'down', 'during', 'for', 'from', 'in', 'inside', 'into', 'like', 'near', 'of', 'off', 'on', 'onto', 'out', 'outside', 'over', 'past', 'regarding', 'round', 'since', 'than', 'through', 'throughout', 'till', 'to', 'toward', 'under', 'unlike', 'until', 'up', 'upon', 'with', 'within', 'without']
	let l:text = a:text
	let l:text = substitute(l:text, '\n$', '', '')
	let l:text = tolower(l:text)
	let l:text = substitute(l:text, '\<.', '\u&', 'g')
	for l:word in l:exceptions
		let l:text = substitute(l:text, '\(^\|[:?.!] \)\@<!\<' . l:word . '\>', '\l&', 'g')
	endfor
	let l:text = substitute(l:text, '\<.\ze\S*$', '\u&', '')
	let l:text = substitute(l:text, '''\zs\S', '\l&', 'g')
	call setreg('@', l:text, getregtype('@'))
	return l:text
endfunction

function! s:getAbstract(abstractLine)
	" This will pull the abstract from the current item.
	if getline(a:abstractLine) =~# '\*\*Abstract:'
		return getline(a:abstractLine)[15:]
	else
		return ''
	endif
endfunction

function! s:OpenUrl()
	" This will search current buffer for a `doi` or `URL` field and then open
	" a browser to the relevant web address.
	if search('^\s*doi = {')
		let l:doi = getline('.')[8:-3]
		silent execute '!open http://doi.org/' . l:doi
	elseif search('^\s*url = {')
		let l:url = getline('.')[8:-3]
		silent execute '!open ' . l:url
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
	" Add abstract from philpapers.org only if there is not one already
	if a:abstract !=# '' && !search('^\s*abstract = {', 'n')
		call append(1, "\tabstract = {" . a:abstract . '},')
	endif
	silent set filetype=tex
	" Break undo sequence
	execute "normal! i\<C-G>u\<Esc>"
	" Consistent indentation
	silent! %s/^\s\+/\t/
	" Fix quotes
	silent! %s/{\\textquotesingle}/'/g
	silent! %s/"\([^"]*\)"/\\mkbibquote{\1}/g
	silent! %substitute/\(^\s*abstract.*\)\@<!{\\textquotedblleft}/\\makebibquote{/g
	silent! %substitute/\(^\s*abstract.*\)\@<!{\\textquotedblright}/}/g
	" Fix dashes
	silent! %substitute/\(doi =|url =\)\@<!–/--/g
	silent! %substitute/\(doi =|url =\)\@<!—/---/g
	" Substitute month numbers for month names
	if search('^\s*month = {')
		silent! substitute/jan/1/
		silent! substitute/feb/2/
		silent! substitute/mar/3/
		silent! substitute/apr/4/
		silent! substitute/may/5/
		silent! substitute/jun/6/
		silent! substitute/jul/7/
		silent! substitute/aug/8/
		silent! substitute/sep/9/
		silent! substitute/oct/10/
		silent! substitute/nov/11/
		silent! substitute/dec/12/
	endif
	" Ensure N-dashes are used between numbers in `pages` field
	if search('^\s*pages = {')
		silent! substitute/\(\d\)-\(\d\)/\1--\2/
	endif
	" Don't have both `doi` and `url` fields when `url` field points to doi
	silent! g/^\s*doi =.*\n\s*url.*doi\.org/+d
	" Delete `publisher` field if it's a journal
	if search('^\s*journal = {', 'n')
		silent! g/^\s*publisher = {/d
	endif
	" Delete ISSN field
	silent! g/^\s*issn = {/d
	" Ensure titlecase for titles
	if search('^\s*title = {')
		let l:title = getline('.')
		echom l:title[9:]
		let l:title = "\ttitle = " . <SID>TitleCase(l:title[9:])
		call setline('.', l:title)
	endif
	" Go to top and yank all text
	silent normal! ggyG
	" Set up mapping for BibTeX preview window to jump to url
	nnoremap <buffer> <C-b> :call <SID>OpenUrl()<CR>
endfunction

function! s:GetBibTeX()
	let l:nextItem = search('^\d\+\.\s', 'Wn')
	normal! 2-
	if l:nextItem == 0
		let l:nextItem = 9999
	endif
	let l:jstorLine = search('^\s*\*\*J-Stor:\*\*', 'Wn')
	let l:doiLine = search('^\s*\*\*DOI:', 'Wn')
	let l:urlLine = search('^\s*\*\*URL:', 'Wn')
	normal! 2+
	if l:jstorLine > 0 && l:jstorLine < l:nextItem
		let l:abstract = s:getAbstract(l:jstorLine - 1)
		let l:jstorUrl = getline(l:jstorLine)[14:-2]
		let l:jstorContent = system('curl -sL ' . l:jstorUrl)
		let l:jstorDoi = matchstr(l:jstorContent, 'data-doi="\zs[^"]*\ze"')
        let l:url = 'http://www.jstor.org/citation/text/' . l:jstorDoi
		call s:DisplayBibTeX(l:url, l:abstract)
	elseif l:doiLine > 0 && l:doiLine < l:nextItem
		let l:abstract = s:getAbstract(l:doiLine - 1)
		let l:doi = getline(l:doiLine)[10:]
		let l:url = 'http://api.crossref.org/works/' . l:doi . '/transform/application/x-bibtex'
		"execute 'read !curl -sL "http://api.crossref.org/works/' . l:doi . '/transform/application/x-bibtex"'
		call s:DisplayBibTeX(l:url, l:abstract)
	elseif l:urlLine > 0 && l:urlLine < l:nextItem
		let l:url = getline(l:urlLine)[11:-2]
		execute('silent !open ' . l:url)
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
