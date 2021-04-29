" Description   : autoload session_manager.vim
" Maintainer    : lwflwf1
" Website       : https://github.com/lwflwf1/vim-session-manager.com
" Created Time  : 2021-04-29 16:21:39
" Last Modified : 2021-04-30 00:53:01
" File          : session_manager.vim
" Version       : 0.1.3
" License       : MIT

let s:this_session = ''
let s:last_session_file = g:session_dir.'.last_session'

function session_manager#echoError(...) abort
    echohl ErrorMsg
    for msg in a:000
        echomsg msg
    endfor
    echohl None
endfunction

function session_manager#saveLastSessionName() abort
    if empty(s:this_session)
        let s:this_session = g:session_dir."default_session.vim"
    endif
    call writefile([s:this_session], s:last_session_file)
endfunction

function session_manager#getLastSessionName() abort
    if filereadable(s:last_session_file)
        " let s:this_session = readfile(s:last_session_file, '', 1)[0]
        return session_manager#getSessionName(readfile(s:last_session_file, '', 1)[0])
    else
        return 'No Last Session'
    endif
endfunction

function session_manager#getSessionName(session_full_path) abort
    " return substitute(a:session_full_path, '\v.*[\/]|\.vim', '', 'g')
    return fnamemodify(a:session_full_path, ':t:r')
endfunction

function session_manager#getListedBufnrs() abort
    return filter(range(1, bufnr('$')), 'buflisted(v:val)')
endfunction

function session_manager#clearAllBuffers(flag) abort
    if a:flag
        wall
        " for bufnr in GetListedBufnrs()
        "     execute "bwipeout ".bufnr
        " endfor
        silent %bwipeout
    endif
endfunction

function session_manager#sessionSave(...) abort
    if a:0 ==# 0
        if empty(s:this_session)
            let l:session_file = g:session_dir."default_session.vim"
            let l:description = "This is the default session"
        else
            let l:session_file = s:this_session
            let l:this_session_file_line1 = readfile(s:this_session, '', 1)[0]
            if l:this_session_file_line1[0] ==# '"'
                " let l:description = readfile(s:this_session, '', 1)[0][1:]
                let l:description = substitute(l:this_session_file_line1, '"\s*', '', '')
            else
                let l:description = ''
            endif
        endif
    else
        let l:session_file = g:session_dir.matchstr(a:1, '\v[^:]*').'.vim'
        let l:session_file = substitute(l:session_file, '\v\s', '', 'g')
        let l:description = matchstr(a:1, '\v:@<=.*')
    endif

    execute('mksession! '.l:session_file)
    call writefile(['" '.l:description] + readfile(l:session_file), l:session_file)
    let s:this_session = l:session_file
    call session_manager#saveLastSessionName()
endfunction

function session_manager#sessionLoad(...) abort
    if a:0 ==# 0
        if empty(s:this_session)
            let l:session_name = 'default_session'
            let l:session_file = g:session_dir.l:session_name.'.vim'
        else
            let l:session_name = session_manager#getSessionName(s:this_session)
            let l:session_file = s:this_session
        endif
    elseif a:1 ==# 'No Last Session'
        echomsg 'No Last Session!'
        return 0
    else
        let l:session_name = a:1
        let l:session_file = g:session_dir.l:session_name.'.vim'
    endif

    if l:session_file == s:this_session
        call session_manager#echoError("You are already in the session: '".l:session_name."'!")
        return 1
    endif

    if !filereadable(l:session_file)
        call session_manager#echoError("Session: '".l:session_name."' does not exist!")
        return 1
    else
        let s:this_session = ''
        call session_manager#clearAllBuffers(g:session_clear_before_load)
        execute('source '.l:session_file)
        nohlsearch
        if bufexists("__SessionList__")
            bwipeout! __SessionList__
        endif
        let s:this_session = l:session_file
        call session_manager#saveLastSessionName()
        normal! zvzz
    endif
    return 0
endfunction

function session_manager#sessionList() abort
    if bufexists("__SessionList__")
        bwipeout! __SessionList__
        if bufwinnr('__SessionList__') !=# -1
            return
        endif
    endif
    let l:session_files = globpath(g:session_dir, '*.vim')
    let l:sessions = split(substitute(l:session_files, '\v[^\n]*[\/]%(\S+\.vim)@=|\.vim', '', 'g'), '\n')
    let l:this_session_index = index(l:sessions, session_manager#getSessionName(s:this_session))
    if l:this_session_index !=# -1
        let l:sessions[l:this_session_index] = '*'.l:sessions[l:this_session_index]
    endif
    " strlen("Session") = 7
    let l:maxlen = 7
    let l:session_names = []

    for ss in l:sessions
        let l:session_names += [" ".ss]
        let l:len_session = strlen(ss)
        let l:maxlen = max([l:maxlen, l:len_session])
    endfor

    let l:session_descriptions = []
    for sfp in split(l:session_files, '\n')
        if readfile(sfp, '', 1)[0][0] ==# '"'
            " let l:session_descriptions += [readfile(sfp)[0][1:]]
            let l:session_descriptions += [substitute(readfile(sfp, '', 1)[0], '\v"\s*', '', '')]
        else
            let l:session_descriptions += ['']
        endif
    endfor

    let l:session_infos = []
    for index in range(len(l:session_names))
        let l:session_infos += [l:session_names[index].repeat(" ", l:maxlen - len(l:session_names[index]) + 5).l:session_descriptions[index]]
    endfor

    let l:session_infos = [
                \' settings: autosave '.string(g:session_autosave_enable ==# 1).
                \', autoload '.string(g:session_autoload_enable ==# 1).
                \', track_current_session '.string(g:session_track_current_session ==# 1).
                \', clear_before_load '.string(g:session_clear_before_load ==# 1)
                \,' '.repeat('=', 80)] + [" Session".repeat(" ", l:maxlen - 3)."Description"] + l:session_infos

    set splitbelow
    botright split __SessionList__

    call append(0, l:session_infos)
    call cursor(4, 1)
    call session_manager#sessionListSetOptions()
    call session_manager#sessionListHighlight()
    echo 'q: quit, dd: delete session, <cr>: enter session'
endfunction

function session_manager#sessionListHighlight() abort
    syntax match SessionListName '\v\S+'
    syntax match SessionListDescription '\v%(\S+)@<=.*'
    syntax match SessionListType '\vSession\s+Description'
    syntax match SessionListSeparator '\v\=+'
    highlight link SessionListType Type
    highlight link SessionListName Keyword
    highlight link SessionListDescription String
    highlight link SessionListSeparator Comment
endfunction

function session_manager#sessionListSetOptions() abort
    setlocal filetype=sessionlist
    setlocal nonumber
    setlocal norelativenumber
    setlocal nopaste
    setlocal nomodeline
    setlocal noswapfile
    setlocal nocursorline
    setlocal nocursorcolumn
    setlocal colorcolumn=
    setlocal nobuflisted
    setlocal buftype=nofile
    setlocal bufhidden=hide
    setlocal nomodifiable
    setlocal signcolumn=no
    setlocal nolist
    setlocal nospell
    setlocal nofoldenable
    setlocal foldcolumn=0

    nnoremap <silent> <buffer> dd :<c-u>call session_manager#sessionDelete(0)<cr>
    nnoremap <silent> <buffer> <cr> :<c-u>call session_manager#enterSessionFromList()<cr>
    nnoremap <silent> <buffer> q :<c-u>bwipeout!<cr>
endfunction

function session_manager#sessionDelete(bang, ...) abort
    let l:delete_this_session_flag = 0
    " if use !, delete all sessions
    if a:bang
        call delete(g:session_dir, 'rf')
        call session_manager#checkSessionDirectory()
        let s:this_session = ''
        echomsg 'All sessions are deleted!'
        return
    endif
    " if user not specify argument
    if a:0 ==# 0
        if &ft ==# 'sessionlist'
            if index([1, 2, 3], line('.')) !=# -1
                call session_manager#echoError("You can not do that!")
                return
            endif
            " delete session under cursor
            let l:session_name = matchstr(getline("."), '\v\S+')
            let l:this_session_name = session_manager#getSessionName(s:this_session)
            if l:session_name ==# '*'.l:this_session_name
                let l:session = s:this_session
                let s:this_session = ''
                call delete(s:last_session_file)
            else
                let l:session = g:session_dir.l:session_name.'.vim'
            endif
            call delete(l:session)
            " echomsg 'Delete session: '.l:session
            setlocal modifiable
            normal! dd
            setlocal nomodifiable
        else
            if !empty(s:this_session)
                call delete(s:this_session)
                call delete(s:last_session_file)
                " echomsg 'Delete session: '.s:this_session
                let s:this_session = ''
            else
                call session_manager#echoError("You are not in a session!")
                return
            endif
        endif
    " if user specify arguments, and the sessions exist, delete those sessions
    else
        for ss in a:000
            let l:session = g:session_dir.ss.'.vim'
            if l:session ==# s:this_session
                call delete(s:last_session_file)
                let s:this_session = ''
            endif
            if filereadable(l:session)
                call delete(l:session)
            else
                call session_manager#echoError("Session: '".ss."' does not exist")
                return
            endif
        endfor
    endif
endfunction

function session_manager#enterSessionFromList() abort
    if index([1, 2, 3], line('.')) !=# -1
        call session_manager#echoError("You can not do that!")
        return
    endif
    call cursor(0, 1)
    let l:session = matchstr(getline("."), '\v\S+')
    let l:this_session_name = session_manager#getSessionName(s:this_session)
    if l:session ==# '*'.l:this_session_name
        let l:session = l:this_session_name
    endif
    call session_manager#sessionLoad(l:session)
endfunction

function session_manager#sessionRename(...) abort
    if a:0 != 2
        call session_manager#echoError("Require 2 arguments: {old_name} {new_name}!")
        return
    endif
    let l:old_session = g:session_dir.a:1.'.vim'
    let l:new_session = g:session_dir.a:2.'.vim'
    if !filereadable(l:old_session)
        call session_manager#echoError("Session: '".a:1."' does not exist!")
        return
    endif
    call writefile(readfile(l:old_session), l:new_session)
    call delete(l:old_session)
    if l:old_session ==# s:this_session
        let s:this_session = l:new_session
        call session_manager#saveLastSessionName()
    endif
endfunction

function session_manager#sessionClose() abort
    if s:this_session ==# ''
        call session_manager#echoError('You are not in a session!')
        return
    endif
    let s:this_session = ''
    call session_manager#clearAllBuffers(1)
endfunction

function session_manager#sessionCommandComplete(ArgLead, CmdLine, CursorPos) abort
    return substitute(globpath(g:session_dir, '*.vim'), '\v[^\n]*[\/]%(\S+\.vim)@=|\.vim', '', 'g')
endfunction

function session_manager#checkSessionDirectory() abort
    if g:session_dir[strlen(g:session_dir)-1] !~# '\v[\/]'
        let g:session_dir .= '/'
    endif
    let g:session_dir = substitute(g:session_dir, '\v\\', '/', 'g')
    if !isdirectory(g:session_dir)
        call mkdir(g:session_dir, "p")
    endif
endfunction

function SessionStatusLine() abort
    return fnamemodify(s:this_session, ':t:r')
endfunction
