" ViM plugin for quick and smart code commenting/uncommenting
" Author: Carlo Baldassi <carlobaldass@gmail.com>
" Licence: GPL 3 or later
" Notes: Key mappings are at the end of this file
"        default ones are Ctrl-C to comment,
"        Ctrl-F to uncomment

function! ResetCommentsData()
	let b:three_comments = []
	let b:line_comments = []
	let b:ternary_comment_index = -10
endfunction

function! ParseComments()
	call ResetCommentsData()
	if exists('&comments')
		let s:split_cstring = split(&comments, ",")
		let s:three_mode = 0
		let s:tc_new = []
		let s:type = "none"
		for s:cdef in s:split_cstring
			let s:split_def = split(s:cdef, ":")
			if len(s:split_def) == 2
				let [ s:cflags, s:ctok ] = s:split_def
			elseif len(s:split_def) == 1
				let s:cflags = ""
				let s:ctok = s:split_def[0]
			else
				echohl WarningMsg | echom "option &comments is malformed" | echohl None
				call ResetCommentsData()
				return
			endif
			if match(s:cflags, "s") > -1
				if s:three_mode != 0
					echohl WarningMsg | echom "option &comments is malformed" | echohl None
					call ResetCommentsData()
					return
				endif
				let s:type = "ternary"
				let s:three_mode = 1
				let s:tc_new += [s:ctok]
			elseif match(s:cflags, "m") > -1
				if s:three_mode != 1
					echohl WarningMsg | echom "option &comments is malformed" | echohl None
					call ResetCommentsData()
					return
				endif
				if s:type != "ternary"
					echohl WarningMsg | echom "option &comments is malformed" | echohl None
					call ResetCommentsData()
					return
				endif
				let s:three_mode = 2
				let s:tc_new += [s:ctok]
			elseif match(s:cflags, "e") > -1
				if s:three_mode != 2
					echohl WarningMsg | echom "option &comments is malformed" | echohl None
					call ResetCommentsData()
					return
				endif
				if s:type != "ternary"
					echohl WarningMsg | echom "option &comments is malformed" | echohl None
					call ResetCommentsData()
					return
				endif
				let s:three_mode = 0
				let s:tc_new += [s:ctok]
				let b:three_comments = b:three_comments + [s:tc_new]
				let s:tc_new = []
			else
				let s:type = "line"
				let b:line_comments = b:line_comments + [s:ctok]
			endif
		endfor
		let b:ternary_comment_index = -2
		let b:line_comment_index = 0
		if exists('&commentstring')
			let s:pos = match(&commentstring, "%s")
			if len(s:pos) == -1
				echohl WarningMsg | echom "option &commentstring is malformed" | echohl None
				call ResetCommentsData()
				return
			endif
			let s:cleft = substitute(&commentstring, "%s.*$", "", "")
			let s:cright = substitute(&commentstring, "^.*%s", "", "")
			let s:t_found = 0
			let s:l_found = 0
			for s:ind in range(len(b:three_comments))
				if b:three_comments[s:ind][0] == s:cleft && b:three_comments[s:ind][2] == s:cright
					let s:t_found = 1
					break
				endif
			endfor
			if s:t_found == 1
				let b:ternary_comment_index = s:ind
			endif

			for s:ind in range(len(b:line_comments))
				if b:line_comments[s:ind] == s:cleft && s:cright == ""
					let s:l_found = 1
					break
				endif
			endfor
			if s:l_found == 1
				let b:line_comment_index = s:ind
				" if s:t_found == 0 ??
				let b:ternary_comment_index = -1
			endif
		else
			let b:ternary_comment_index = -10
		endif
	else
		" echo "var comments not found"
	endif
endfunction

function! ShowCommentVars()
	echo "Line comments:" len(b:line_comments)
	for s:lc in b:line_comments
		echo "  : " string(s:lc)
	endfor
	echo "Ternary comments:" len(b:three_comments)
	for s:tc in b:three_comments
		echo "  : " string(s:tc)
	endfor
	echo "TC index:" b:ternary_comment_index
endfunction

function! SetCommentVars(linec, ternaryc)
	if type(a:linec) != 3 || len(a:linec) != 1
		echohl ErrorMsg | echo "SetCommentVars error: first variable must be a list with one string element" | echohl None
		return
	endif
	if type(a:ternaryc) != 3 || (len(a:ternaryc) != 3 && len(a:ternaryc) != 0)
		echohl ErrorMsg | echo "SetCommentVars error: second variable must be a list of zero or three string elements" | echohl None
		return
	endif
	call ResetCommentsData()
	if type(a:linec[0]) == 1 " is a string
		let b:line_comments = a:linec
	else
		let b:line_comments = [string(a:linec[0])]
	end
	let b:line_comment_index = 0
	if len(a:ternaryc) == 3
		let b:three_comments = [[]]
		for s:itc in a:ternaryc
			if type(s:itc) == 1 " is a string
				let b:three_comments[0] += [s:itc]
			else
				let b:three_comments[0] += [string(s:itc)]
			endif
		endfor
		let b:ternary_comment_index = 0
	endif
	call ShowCommentVars()
endfunction

function! SmartComment(mode) range
	if a:mode == "normal" || b:ternary_comment_index == -1
		exec a:firstline . "," . a:lastline . "call CommentLine()"
	elseif a:mode == "visual"
		exec a:firstline . "," . a:lastline . "call CommentRange()"
	endif
endfunction

function! SmartUnComment(mode) range
	if a:mode == "normal" || b:ternary_comment_index == -1
		exec a:firstline . "," . a:lastline . "call UnCommentLine()"
	elseif a:mode == "visual"
		exec a:firstline . "," . a:lastline . "call UnCommentRange()"
	endif
endfunction

function! CommentLine()
	if &modifiable == 0
		echohl WarningMsg | echo "CommentLine: failed: file is read-only" | echohl None
		return
	endif
	let s:cleft = "/*"
	let s:cright = "*/"
	if len(b:line_comments) > 0
		let s:cleft = b:line_comments[b:line_comment_index]
		let s:cright = ""
	elseif len(b:three_comments) > 0
		let s:ind = b:ternary_comment_index
		if s:ind < 0
			s:ind = 0
		endif
		let s:cleft = b:three_comments[s:ind][0]
		let s:cright = b:three_comments[s:ind][2]
	endif
	let s:lcommand = "I" . s:cleft
	let s:rcommand = "A" . s:cright
	exec "normal " . s:lcommand
	exec "normal " . s:rcommand
	normal ^
endfunction

function! CommentRange() range
	if &modifiable == 0
		echohl WarningMsg | echo "CommentRange: failed: file is read-only" | echohl None
		return
	endif
	let s:report_bk = &report
	let s:cindent_bk = &cindent
	let s:smartindent_bk = &smartindent
	let s:autoindent_bk = &autoindent
	let s:indentexpr_bk = &indentexpr
	let s:comments_bk = &comments
	setlocal report=100000000
	setlocal nocindent
	setlocal nosmartindent
	setlocal noautoindent
	setlocal indentexpr=""
	setlocal comments=""
	if len(b:three_comments) > 0
		let s:ind = b:ternary_comment_index
		if s:ind < 0
			s:ind = 0
		endif
		let s:cleft = b:three_comments[s:ind][0]
		let s:cright = b:three_comments[s:ind][2]

		let s:ecleft = escape(s:cleft, '*@\')
		let s:ecright = escape(s:cright, '*@\')

		"let s:mode = visualmode()

		let s:pos1 = getpos("'<")
		let s:pos2 = getpos("'>")

		if ((s:pos1[1] > s:pos2[1]) || ((s:pos1[1] == s:pos2[1]) && (s:pos1[2] > s:pos2[2])))
			s:tmp = s:pos1
			s:pos1 = s:pos2
			s:pos2 = s:tmp
		endif

		call setpos(".", s:pos1)
		let s:ml1 = searchpos(s:ecright, "c", a:lastline)
		if s:ml1[0] == a:lastline && s:ml1[1] > s:pos2[2]
			let s:ml1 = [0,0]
		endif

		call setpos(".", s:pos2)
		let s:ml2 = searchpos(s:ecright, "cb", a:firstline)
		if s:ml2[0] == a:firstline && s:ml2[1] < s:pos1[2]
			let s:ml2 = [0,0]
		endif

		call setpos(".", s:pos1)
		let s:mr1 = searchpos(s:ecleft, "c", a:lastline)
		if s:mr1[0] == a:lastline && s:mr1[1] > s:pos2[2]
			let s:mr1 = [0,0]
		endif

		call setpos(".", s:pos2)
		let s:mr2 = searchpos(s:ecleft, "cb", a:firstline)
		if s:mr2[0] == a:firstline && s:mr2[1] < s:pos1[2]
			let s:mr2 = [0,0]
		endif

		let s:closeleft = ""
		let s:closeright = ""
		if s:ml1 != [0, 0] && s:mr1 != [0, 0]
			if s:ml1[0] < s:mr1[0] || ( s:ml1[0] == s:mr1[0] && s:ml1[1] < s:mr1[1] )
				let s:closeleft = s:cright
			endif
			if s:ml2[0] < s:mr2[0] || ( s:ml2[0] == s:mr2[0] && s:ml2[1] < s:mr2[1] )
				let s:closeright = s:cleft
			endif
		elseif s:ml1 != [0, 0] && s:mr1 == [0, 0]
			let s:closeleft = s:cright
		elseif s:ml1 == [0, 0] && s:mr1 != [0, 0]
			let s:closeright = s:cleft
		endif

		let s:rcommand = "a\<CR>" . s:cright . s:closeright

		call setpos(".", s:pos2)
		exec "normal " . s:rcommand

		let s:lcommand = "i" . s:closeleft . s:cleft . "\<CR>"

		call setpos(".", s:pos1)
		if (visualmode() == "V")
			normal ^
		endif
		exec "normal " . s:lcommand

		exec (a:firstline + 1) . "," . (a:lastline + 1) . "s@\\(" . s:ecleft . "\\|" . s:ecright . "\\)@" . s:ecright . s:ecleft . "@ge"

		exec ":" . a:firstline
		exec "normal gJ"

		exec ":" . a:lastline
		exec "normal gJ"

	elseif len(b:line_comments) > 0
		let s:cleft = b:line_comments[0]
		let s:lcommand = "I" . s:cleft
		for s:l in range(a:firstline, a:lastline)
			exec ": " . s:l
			exec "normal " . s:lcommand
		endfor
	endif
	exec "setlocal report=" . s:report_bk
	if s:cindent_bk == 1
		setlocal cindent
	endif
	if s:smartindent_bk == 1
		setlocal smartindent
	endif
	if s:autoindent_bk == 1
		setlocal autoindent
	endif
	exec "setlocal indentexpr=" . s:indentexpr_bk
	exec "setlocal comments=" . escape(s:comments_bk, '* -\\|"')
endfunction

function! UnCommentLine()
	if &modifiable == 0
		echohl WarningMsg | echo "UnCommentLine: failed: file is read-only" | echohl None
		return
	endif
	let s:report_bk = &report
	setlocal report=100000000

	let s:cleft = "/*"
	let s:cright = "*/"
	if len(b:line_comments) > 0
		let s:cleft = b:line_comments[b:line_comment_index]
		let s:cright = ""
	elseif len(b:three_comments) > 0
		let s:ind = b:ternary_comment_index
		if s:ind < 0
			s:ind = 0
		endif
		let s:cleft = b:three_comments[s:ind][0]
		let s:cright = b:three_comments[s:ind][2]
	endif

	let s:ecleft = escape(s:cleft, '*@\')
	let s:ecright = escape(s:cright, '*@\')

	exec "s@^\\([[:space:]]*\\)" . s:ecleft . "\\(.*\\)[[:space:]]*" . s:ecright . "[[:space:]]*$@\\1\\2@e"
	exec "setlocal report=" . s:report_bk
endfunction

function! UnCommentRange() range
	if &modifiable == 0
		echohl WarningMsg | echo "UnCommentRange: failed: file is read-only" | echohl None
		return
	endif
	let s:report_bk = &report
	setlocal report=100000000
	let s:cindent_bk = &cindent
	let s:smartindent_bk = &smartindent
	let s:autoindent_bk = &autoindent
	let s:indentexpr_bk = &indentexpr
	let s:comments_bk = &comments
	setlocal report=100000000
	setlocal nocindent
	setlocal nosmartindent
	setlocal noautoindent
	setlocal indentexpr=""
	setlocal comments=""
	let s:cleft = "/*"
	let s:cright = "*/"
	if len(b:three_comments) > 0
		let s:ind = b:ternary_comment_index
		if s:ind < 0
			s:ind = 0
		endif
		let s:cleft = b:three_comments[s:ind][0]
		let s:cright = b:three_comments[s:ind][2]

		let s:ecleft = escape(s:cleft, '*@\')
		let s:ecright = escape(s:cright, '*@\')

		let s:pos1 = getpos("'<")
		let s:pos2 = getpos("'>")

		if ((s:pos1[1] > s:pos2[1]) || ((s:pos1[1] == s:pos2[1]) && (s:pos1[2] > s:pos2[2])))
			s:tmp = s:pos1
			s:pos1 = s:pos2
			s:pos2 = s:tmp
		endif

		call setpos(".", s:pos1)
		let s:ml1 = searchpos(s:ecright, "c", a:lastline)
		if s:ml1[0] == a:lastline && s:ml1[1] > s:pos2[2]
			let s:ml1 = [0,0]
		endif

		call setpos(".", s:pos2)
		let s:ml2 = searchpos(s:ecright, "cb", a:firstline)
		if s:ml2[0] == a:firstline && s:ml2[1] < s:pos1[2]
			let s:ml2 = [0,0]
		endif

		call setpos(".", s:pos1)
		let s:mr1 = searchpos(s:ecleft, "c", a:lastline)
		if s:mr1[0] == a:lastline && s:mr1[1] > s:pos2[2]
			let s:mr1 = [0,0]
		endif

		call setpos(".", s:pos2)
		let s:mr2 = searchpos(s:ecleft, "cb", a:firstline)
		if s:mr2[0] == a:firstline && s:mr2[1] < s:pos1[2]
			let s:mr2 = [0,0]
		endif

		let s:closeleft = ""
		let s:closeright = ""
		if s:ml1 != [0, 0] && s:mr1 != [0, 0]
			if s:ml1[0] < s:mr1[0] || ( s:ml1[0] == s:mr1[0] && s:ml1[1] < s:mr1[1] )
				let s:closeleft = s:cright
			endif
			if s:ml2[0] < s:mr2[0] || ( s:ml2[0] == s:mr2[0] && s:ml2[1] < s:mr2[1] )
				let s:closeright = s:cleft
			endif
		elseif s:ml1 != [0, 0] && s:mr1 == [0, 0]
			let s:closeleft = s:cright
		elseif s:ml1 == [0, 0] && s:mr1 != [0, 0]
			let s:closeright = s:cleft
		endif

		let s:rcommand = "a\<CR>" . s:closeright

		call setpos(".", s:pos2)
		exec "normal " . s:rcommand

		let s:lcommand = "i" . s:closeleft . "\<CR>"

		call setpos(".", s:pos1)
		exec "normal " . s:lcommand

		exec (a:firstline + 1) . "," . (a:lastline + 1) . "s@" . s:ecright . s:ecleft . "@@ge"
		exec (a:firstline + 1) . "," . (a:lastline + 1) . "s@\\(" . s:ecleft . "\\|" . s:ecright . "\\)@@ge"

		exec ":" . a:firstline
		exec "normal gJ"

		exec ":" . a:lastline
		exec "normal gJ"

	elseif len(b:line_comments) > 0
		let s:cleft = b:line_comments[0] . " "
		for s:l in range(a:firstline, a:lastline)
			let s:ecleft = escape(s:cleft, '*@\')

			exec "s@^[[:space:]]*" . s:ecleft . "\\(.*\\)$@\\1@e"
		endfor
	endif
	exec "setlocal report=". s:report_bk
	if s:cindent_bk == 1
		setlocal cindent
	endif
	if s:smartindent_bk == 1
		setlocal smartindent
	endif
	if s:autoindent_bk == 1
		setlocal autoindent
	endif
	exec "setlocal indentexpr=" . s:indentexpr_bk
	exec "setlocal comments=" . escape(s:comments_bk, '* -\\|"')
endfunction

" Key mappings
nmap <C-C> :call SmartComment("normal")<CR>
nmap <C-F> :call SmartUnComment("normal")<CR>
imap <C-C> <Esc>:call SmartComment("normal")<CR>
imap <C-F> <Esc>:call SmartUnComment("normal")<CR>
vmap <C-C> :call SmartComment("visual")<CR>
vmap <C-F> :call SmartUnComment("visual")<CR>

" Autoparse comment strings at any relevant event
if !exists("g:smartcomment_loaded")
	let g:smartcomment_loaded = 0
endif

if g:smartcomment_loaded == 0
	autocmd BufReadPost,FileType,Syntax,EncodingChanged * call ParseComments()
endif
let g:smartcomment_loaded = 1
