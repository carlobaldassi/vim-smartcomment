" ViM plugin for quick and smart code commenting/uncommenting
" Author: Carlo Baldassi <carlobaldass@gmail.com>
" Licence: GPL 3 or later
" Notes: Key mappings are at the end of this file
"        default ones are Ctrl-C to comment,
"        Ctrl-F to uncomment

function! ResetCommentsData()
    let b:range_comments = []
    let b:line_comments = ""
endfunction

function! GetCommentsData()
    call ResetCommentsData()
    if exists('&commentstring')
        let s:pos = match(&commentstring, "%s")
        if len(s:pos) == -1
            echohl WarningMsg | echom "option &commentstring is malformed" | echohl None
            call ResetCommentsData()
            return
        endif
        let s:cleft = substitute(&commentstring, "%s.*$", "", "")
        let s:cright = substitute(&commentstring, "^.*%s", "", "")
        let b:range_comments = [s:cleft, s:cright]
        if len(s:cright) == 0
            let b:line_comments = s:cleft
        endif
    endif
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
                if s:three_mode != 1 || s:type != "ternary"
                    echohl WarningMsg | echom "option &comments is malformed" | echohl None
                    call ResetCommentsData()
                    return
                endif
                let s:three_mode = 2
                "let s:tc_new += [s:ctok]
            elseif match(s:cflags, "e") > -1
                if s:three_mode != 2 || s:type != "ternary"
                    echohl WarningMsg | echom "option &comments is malformed" | echohl None
                    call ResetCommentsData()
                    return
                endif
                let s:three_mode = 0
                let s:tc_new += [s:ctok]
                if len(b:range_comments) == 0
                    let b:range_comments == s:tc_new
                end
                let s:tc_new = []
            else
                let s:type = "line"
                if len(b:line_comments) == 0
                    let b:line_comments = s:ctok
                end
            endif
        endfor
    endif
endfunction

function! ShowCommentVars()
    if len(b:line_comments) > 0
        echo "Line comments:" b:line_comments
    else
        echo "No line comments"
    endif
    if len(b:range_comments) > 0
        echo "Range comments:" string(b:range_comments[0]) ":" string(b:range_comments[1])
    else
        echo "No range comments"
    endif
endfunction

function! SetCommentVars(linec, rangec)
    if type(a:linec) != 1
        echohl ErrorMsg | echo "SetCommentVars error: first variable must be a string" | echohl None
        return
    endif
    if type(a:ternaryc) != 3 || (len(a:ternaryc) != 2 && len(a:ternaryc) != 0)
        echohl ErrorMsg | echo "SetCommentVars error: second variable must be a list of zero or two strings" | echohl None
        return
    endif
    call ResetCommentsData()
    let b:line_comments = string(a:linec)
    if len(a:ternaryc) == 2
        let b:range_comments = [string(a:rangec[0]), string(a:rangec[1])]
    end
    call ShowCommentVars()
endfunction

function! SmartComment(mode) range
    if len(b:line_comments) == 0 && len(b:range_comments) == 0
        return
    end
    let force_linemode = a:mode == "visual" && get(b:, "smartcomment_force_linemode", 0) && visualmode() == "V"
    let save_cur = getpos('.')
    if a:mode == "normal" || force_linemode || len(b:range_comments) == 0 || len(b:range_comments[1]) == 0
        exec a:firstline . "," . a:lastline . "call CommentLine()"
    elseif a:mode == "visual"
        exec a:firstline . "," . a:lastline . "call CommentRange()"
    endif
    call setpos('.', save_cur)
    return ''
endfunction

function! SmartUnComment(mode) range
    if len(b:line_comments) == 0 && len(b:range_comments) == 0
        return
    end
    let force_linemode = a:mode == "visual" && get(b:, "smartcomment_force_linemode", 0) && visualmode() == "V"
    let save_cur = getpos('.')
    if a:mode == "normal" || force_linemode || len(b:range_comments) == 0 || len(b:range_comments[1]) == 0
        exec a:firstline . "," . a:lastline . "call UnCommentLine()"
    elseif a:mode == "visual"
        exec a:firstline . "," . a:lastline . "call UnCommentRange()"
    endif
    call setpos('.', save_cur)
    return ''
endfunction

function! CommentLine() range
    if &modifiable == 0
        echohl WarningMsg | echo "CommentLine: failed: file is read-only" | echohl None
        return
    endif
    let cleft = "/*"
    let cright = "*/"
    if len(b:line_comments) > 0
        let cleft = b:line_comments
        let cright = ""
    elseif len(b:range_comments) > 0
        let cleft = b:range_comments[0]
        let cright = b:range_comments[1]
    endif
    let rspace = cright == "" ? "" : " "
    let leading_s = 1000
    for line in range(a:firstline, a:lastline)
        call setpos('.', [0, line, 1, 0])
        if match(getline('.'), '\S') == -1
            continue
        endif
        normal ^
        let leading_s = min([leading_s, getpos('.')[2]])
    endfor
    if leading_s == 1000
        let leading_s = 1
    endif
    for line in range(a:firstline, a:lastline)
        call setpos('.', [0, line, leading_s, 0])
        if match(getline('.'), '\S') == -1
            call setline('.', repeat(' ', leading_s - 1) . cleft . (cright != '' ? ' ' . cright : ''))
            continue
        endif
        exec 'normal! i' . cleft . " \<Esc>"
        if cright != ""
            exec 'normal! A ' . cright . "\<Esc>"
        endif
        "call setline('.', substitute(getline('.'), '^\(\s*\)\(.*\)\(\s*\)$', '\1' . cleft . '\2' . cright . '\3', ''))
    endfor
endfunction

function! s:isincomment(l, c, delim)
    if match(getline(a:l), a:delim) != -1
        return 0
    endif
    let stack = synstack(a:l, max([a:c,1]))
    for s in stack
        if synIDattr(s, 'name') =~? 'comment'
            return 1
        endif
    endfor
    return 0
endfunction

function! CommentRange() range
    if &modifiable == 0
        echohl WarningMsg | echo "CommentRange: failed: file is read-only" | echohl None
        return
    endif

    if len(b:range_comments) > 0
        let cleft = b:range_comments[0]
        let cright = b:range_comments[1]

        let ecleft = escape(cleft, '*\.^$')
        let ecright = escape(cright, '*\.^$')

        let pos1 = getpos("'<")
        let pos2 = getpos("'>")

        if ((pos1[1] > pos2[1]) || ((pos1[1] == pos2[1]) && (pos1[2] > pos2[2])))
            tmp = pos1
            pos1 = pos2
            pos2 = tmp
        endif

        if pos1[1] != a:firstline
            echohl ErrorMsg | echo "CommentRange: failed: firstline=" . a:firstline . " pos1=" . pos1[1] | echohl None
            return
        endif
        if pos2[1] != a:lastline
            echohl ErrorMsg | echo "CommentRange: failed: lastline=" . a:lastline . " pos2=" . pos2[1] | echohl None
            return
        endif

        let fa = getline(a:firstline)
        let la = getline(a:lastline)

        let pos2[2] = min([pos2[2], len(la)])

        if a:firstline == a:lastline
            if match(fa, '\%' . pos1[2] . 'c\s*\%' . (pos2[2]+1) . 'c') == -1
                let pos1[2] = match(fa, '\%' . pos1[2] . 'c\s*\zs.*\%' . (pos2[2]+1) . 'c') + 1
                let pos2[2] = match(la, '\%' . pos1[2] . 'c.*\zs\s*\%' . (pos2[2]+1) . 'c')
            endif
        else
            if match(fa, '\%' . pos1[2] . 'c\s*$') == -1
                let pos1[2] = match(fa, '\%' . pos1[2] . 'c\s*\zs') + 1
            endif
            if match(la, '^\s*\%' . (pos2[2]+1) . 'c') == -1
                let pos2[2] = match(la, '\s*\%' . (pos2[2]+1) . 'c')
            end
        endif

        let ecl = '\%' . pos1[2] . 'c'
        let ecr = '\%' . (pos2[2]+1) . 'c'

        let isincommentl = s:isincomment(pos1[1], pos1[2], ecl . ecleft)
        let isincommentr = s:isincomment(pos2[1], pos2[2], ecright . ecr)

        if !isincommentl
            let cl = cleft
        else
            let cl = cright . cleft
        endif
        if !isincommentr
            let cr = cright
        else
            let cr = cright . cleft
        endif

        if a:firstline == a:lastline
            let la = getline(a:firstline)
            if pos1[2] >= 2
                let ll = la[0 : pos1[2]-2]
            else
                let ll = ''
            endif
            let lc = la[pos1[2]-1 : pos2[2]-1]
            let lr = la[pos2[2] : -1]

            let lc = substitute(lc, '\(' . ecleft . '\|' . ecright . '\)', cright . cleft, 'g')

            call setline(a:firstline, ll . cl . lc . cr . lr)
        else
            let la = getline(a:firstline)
            if pos1[2] >= 2
                let ll = la[0 : pos1[2]-2]
            else
                let ll = ''
            endif
            let lc = la[pos1[2]-1 : -1]

            let lc = substitute(lc, '\(' . ecleft . '\|' . ecright . '\)', cright . cleft, 'g')
            call setline(a:firstline, ll . cl . lc)

            for l in range(a:firstline+1, a:lastline-1)
                call setline(l, substitute(getline(l), '\(' . ecleft . '\|' . ecright . '\)', cright . cleft, 'g'))
            endfor

            let la = getline(a:lastline)
            if pos2[2] > 0
                let lc = la[0 : pos2[2]-1]
            else
                let lc = ''
            endif
            let lr = la[pos2[2] : -1]

            let lc = substitute(lc, '\(' . ecleft . '\|' . ecright . '\)', cright . cleft, 'g')

            call setline(a:lastline, lc . cr . lr)
        endif
    elseif len(b:line_comments) > 0
        for l in range(a:firstline, a:lastline)
            setpos(l, 0)
            call CommenLine()
        endfor
    endif
endfunction

function! UnCommentLine()
    if &modifiable == 0
        echohl WarningMsg | echo "UnCommentLine: failed: file is read-only" | echohl None
        return
    endif

    let cleft = "/*"
    let cright = "*/"
    if len(b:line_comments) > 0
        let cleft = b:line_comments
        let cright = ""
    elseif len(b:range_comments) > 0
        let cleft = b:range_comments[0]
        let cright = b:range_comments[1]
    endif

    let ecleft = escape(cleft, '*\.^$') . '\s\?'
    let ecright = escape(cright, '*\.^$')
    if ecright != ""
        let ecright = '\s\?' . ecright
    endif
    let curline = getline('.')
    if match(curline, '^\s*' . ecleft . '\s*' . ecright . '\s*$') != -1
        call setline('.', '')
    else
        call setline('.', substitute(curline, '^\(\s*\)' . ecleft . '\(.*\)\s*' . ecright . '\(\s*\)$', '\1\2\3', ''))
    endif
endfunction

function! UnCommentRange() range
    if &modifiable == 0
        echohl WarningMsg | echo "UnCommentRange: failed: file is read-only" | echohl None
        return
    endif
    if len(b:range_comments) > 0
        let cleft = b:range_comments[0]
        let cright = b:range_comments[1]

        let ecleft = escape(cleft, '*\.^$')
        let ecright = escape(cright, '*\.^$')

        let pos1 = getpos("'<")
        let pos2 = getpos("'>")

        if ((pos1[1] > pos2[1]) || ((pos1[1] == pos2[1]) && (pos1[2] > pos2[2])))
            tmp = pos1
            pos1 = pos2
            pos2 = tmp
        endif

        if pos1[1] != a:firstline
            echohl ErrorMsg | echo "CommentRange: failed: firstline=" . a:firstline . " pos1=" . pos1[1] | echohl None
            return
        endif
        if pos2[1] != a:lastline
            echohl ErrorMsg | echo "CommentRange: failed: lastline=" . a:lastline . " pos2=" . pos2[1] | echohl None
            return
        endif

        let pos2[2] = min([pos2[2], len(getline(a:lastline))])

        let ecl = '\%' . pos1[2] . 'c'
        let ecr = '\%' . (pos2[2]+1) . 'c'

        let isincommentl = s:isincomment(pos1[1], pos1[2], ecl . ecleft)
        let isincommentr = s:isincomment(pos2[1], pos2[2], ecright . ecr)

        if !isincommentl
            let cl = ''
        else
            let cl = cright
        endif
        if !isincommentr
            let cr = ''
        else
            let cr = cleft
        endif

        if a:firstline == a:lastline
            let la = getline(a:firstline)
            if pos1[2] >= 2
                let ll = la[0 : pos1[2]-2]
            else
                let ll = ''
            endif
            let lc = la[pos1[2]-1 : pos2[2]-1]
            let lr = la[pos2[2] : -1]

            let lc = substitute(lc, '\(' . ecleft . '\|' . ecright . '\)', '', 'g')

            call setline(a:firstline, ll . cl . lc . cr . lr)
        else
            let la = getline(a:firstline)
            if pos1[2] >= 2
                let ll = la[0 : pos1[2]-2]
            else
                let ll = ''
            endif
            let lc = la[pos1[2]-1 : -1]

            let lc = substitute(lc, '\(' . ecleft . '\|' . ecright . '\)', '', 'g')
            call setline(a:firstline, ll . cl . lc)

            for l in range(a:firstline+1, a:lastline-1)
                call setline(l, substitute(getline(l), '\(' . ecleft . '\|' . ecright . '\)', '', 'g'))
            endfor

            let la = getline(a:lastline)
            let lc = la[0 : pos2[2]-1]
            let lr = la[pos2[2] : -1]

            let lc = substitute(lc, '\(' . ecleft . '\|' . ecright . '\)', '', 'g')

            call setline(a:lastline, lc . cr . lr)
            return
        endif
    elseif len(b:line_comments) > 0
        for l in range(a:firstline, a:lastline)
            setpos(l, 0)
            call UnCommenLine()
        endfor
    endif
endfunction

" Key mappings
nnoremap <C-C> :call SmartComment("normal")<CR>
nnoremap <C-F> :call SmartUnComment("normal")<CR>
inoremap <C-C> <C-R>=SmartComment("normal")<CR>
inoremap <C-F> <C-R>=SmartUnComment("normal")<CR>
vnoremap <C-C> :call SmartComment("visual")<CR>
vnoremap <C-F> :call SmartUnComment("visual")<CR>
"vmap <C-C> :call SmartComment("normal")<CR>
"vmap <C-F> :call SmartUnComment("normal")<CR>

" Autoparse comment strings at any relevant event
if !exists("g:smartcomment_loaded")
    let g:smartcomment_loaded = 0
endif

if g:smartcomment_loaded == 0
    autocmd BufReadPost,FileType,Syntax,EncodingChanged * call GetCommentsData()
endif
let g:smartcomment_loaded = 1
