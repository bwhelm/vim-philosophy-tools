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
		echom l:url
		silent execute '!open "' . l:url . '"'
	endif
endfunction

function! s:DisplayBibTeX(text, abstract)
	pedit BibTeX.bib
	wincmd P
	resize 13
	setlocal buftype=nofile
    setlocal nowrap
	let l:textList = split(a:text, '\n')
	call append(0, l:textList)
	silent normal! gg
	" Add abstract from philpapers.org only if there is not one already
	if a:abstract !=# '' && !search('^\s*abstract = {', 'n')
		call append(1, "\tabstract = {" . a:abstract . '},')
	endif
	" Break undo sequence
	execute "normal! i\<C-G>u\<Esc>"
	" Consistent indentation
	%substitute/^\s\+/\t/e
	" Fix quotes
	%substitute/{\\textquotesingle}/'/ge
	%substitute/\(^\s*abstract.*\)\@<!"\([^"]*\)"/\\mkbibquote{\2}/gie
	%substitute/\(^\s*abstract.*\)\@<!{\\textquotedblleft}/\\mkbibquote{/ge
	%substitute/\(^\s*abstract.*\)\@<!{\\textquotedblright}/}/ge
	" Fix dashes
	%substitute/\(doi =|url =\)\@<!–/--/ge
	%substitute/\(doi =|url =\)\@<!—/---/ge
	" Substitute month numbers for month names
	if search('^\s*month = {')
		substitute/jan/1/e
		substitute/feb/2/e
		substitute/mar/3/e
		substitute/apr/4/e
		substitute/may/5/e
		substitute/jun/6/e
		substitute/jul/7/e
		substitute/aug/8/e
		substitute/sep/9/e
		substitute/oct/10/e
		substitute/nov/11/e
		substitute/dec/12/e
	endif
	" Ensure N-dashes are used between numbers in `pages` field
	if search('^\s*pages = {')
		substitute/\(\d\)-\(\d\)/\1--\2/e
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
		let l:title = "\ttitle = " . <SID>TitleCase(l:title[9:])
		call setline('.', l:title)
	endif
	" Delete last (empty) line, go to top, and yank all text
	silent normal! GddggyG
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
	let l:ppLine = search('^\s*\*\*PP:\*\*', 'Wn')
	let l:urlLine = search('^\s*\*\*URL:', 'Wn')
	normal! 2+
	if l:jstorLine > 0 && l:jstorLine < l:nextItem
		let l:abstract = s:getAbstract(l:jstorLine - 1)
		let l:jstorUrl = getline(l:jstorLine)[14:-2]
		let l:jstorContent = system('curl -sL ' . l:jstorUrl)
		let l:jstorDoi = matchstr(l:jstorContent, 'data-doi="\zs[^"]*\ze"')
        let l:url = 'http://www.jstor.org/citation/text/' . l:jstorDoi
		let l:text = system('curl -sL "' . l:url . '"')
		call s:DisplayBibTeX(l:text, l:abstract)
	elseif l:doiLine > 0 && l:doiLine < l:nextItem
		let l:abstract = s:getAbstract(l:doiLine - 1)
		let l:doi = getline(l:doiLine)[10:]
		let l:url = 'http://api.crossref.org/works/' . l:doi . '/transform/application/x-bibtex'
		let l:text = system('curl -sL "' . l:url . '"')
		call s:DisplayBibTeX(l:text, l:abstract)
	elseif l:ppLine > 0 && l:ppLine < l:nextItem
		let l:abstract = s:getAbstract(l:ppLine - 1)
		let l:ppUrl = getline(l:ppLine)[10:-2]
		let l:text = system('curl -sL "' . l:ppUrl . '"')
		let l:text = substitute(l:text, '.*<pre class=''export''>\(@.*\)\n</pre>\_.*', '\1', '')
		call s:DisplayBibTeX(l:text, l:abstract)
	elseif l:urlLine > 0 && l:urlLine < l:nextItem
		let l:url = getline(l:urlLine)[11:-2]
		let l:url = substitute(l:url, '%3f', '?', 'g')
		let l:url = substitute(l:url, '%3d', '=', 'g')
		let l:url = substitute(l:url, '%26', '\&', 'g')
		execute('silent !open "' . l:url . '"')
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
