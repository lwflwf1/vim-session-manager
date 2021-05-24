" Description   : autoload session_manager.vim
" Maintainer    : lwflwf1
" Website       : https://github.com/lwflwf1/vim-session-manager.com
" Created Time  : 2021-04-29 16:21:39
" Last Modified : 2021-05-24 23:13:30
" File          : session_manager.vim
" Version       : 0.2.0
" License       : MIT

let s:this_session = ''
let s:session_history_file = g:session_dir.'.session_history'

function! session_manager#echoError(...) abort
    echohl ErrorMsg
    for msg in a:000
        echomsg msg
    endfor
    echohl None
endfunction

function! session_manager#updateSessionHistory() abort
    if empty(s:this_session) | return | endif
    if filereadable(s:session_history_file)
        let l:session_history = readfile(s:session_history_file)
    else
        let l:session_history = []
    endif
    if len(l:session_history) >= g:session_max_history
        call writefile(l:session_history[1:]+[s:this_session], s:session_history_file)
    elseif len(l:session_history) == 0 || l:session_history[-1] !=# s:this_session
        call writefile([s:this_session], s:session_history_file, 'a')
    endif
endfunction

" function! session_manager#getLastSessionName() abort
"     if filereadable(s:session_history_file)
"         return session_manager#getSessionName(readfile(s:session_history_file, '', 1)[0])
"     else
"         return 'No Last Session'
"     endif
" endfunction

function! session_manager#getSessionName(session_full_path) abort
    return fnamemodify(a:session_full_path, ':t:r')
endfunction

function! session_manager#getListedBufnrs() abort
    return filter(range(1, bufnr('$')), 'buflisted(v:val)')
endfunction

function! session_manager#clearAllBuffers() abort
    wall
    silent %bwipeout
endfunction

function! session_manager#sessionSave(...) abort
    let l:save_sessionoptions = &sessionoptions
    set sessionoptions-=blank sessionoptions-=options sessionoptions+=tabpages
    if a:0 ==# 0
        if empty(s:this_session)
            let l:session_file = g:session_dir."default_session.vim"
            let l:description = "This is the default session"
        else
            if !exists('s:this_session_description')
                let l:this_session_file_line1 = readfile(s:this_session, '', 1)[0]
                if l:this_session_file_line1[0] ==# '"'
                    " let s:this_session_description = substitute(l:this_session_file_line1, '"\s*', '', '')
                    let s:this_session_description = trim(l:this_session_file_line1[1:])
                else
                    let s:this_session_description = ''
                endif
            endif
            let l:session_file = s:this_session
            let l:description = s:this_session_description
        endif
    else
        let l:session_info = split(a:1, ':')
        let l:session_name = substitute(l:session_info[0], '\v\s', '', 'g')
        let l:session_file = g:session_dir.l:session_name.'.vim'
        let l:description = get(l:session_info, 1, '')
    endif

    execute('mksession! '.l:session_file)
    call writefile(['" '.l:description] + readfile(l:session_file), l:session_file)
    let s:this_session = l:session_file
    let s:this_session_description = l:description
    " call session_manager#updateSessionHistory()
    let &sessionoptions = l:save_sessionoptions
endfunction

function! session_manager#sessionLoad(...) abort
    if a:0 ==# 0
        if filereadable(s:session_history_file)
            let l:session_history = readfile(s:session_history_file)
            if len(l:session_history) == 0
                let l:session_name = 'default_session'
                let l:session_file = g:session_dir.l:session_name.'.vim'
                " echomsg 'No previous session!'
                " return 0
            else
                let l:session_file = l:session_history[-1]
                let l:session_name = session_manager#getSessionName(l:session_file)
                " call session_manager#updateSessionHistory(1)
                call remove(l:session_history, -1)
                call writefile(l:session_history, s:session_history_file)
            endif
        else
            let l:session_name = 'default_session'
            let l:session_file = g:session_dir.l:session_name.'.vim'
        endif
    " elseif a:1 ==# 'No Last Session'
    "     echomsg 'No Last Session!'
    "     return 0
    elseif a:1[0] ==# '~'
        if filereadable(s:session_history_file) && len(readfile(s:session_history_file)) >= a:1[1:]
            let l:session_file = readfile(s:session_history_file)[-a:1[1:]]
            let l:session_name = session_manager#getSessionName(l:session_file)
        else
            call echoError('No such session')
            return
        endif
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
        if g:session_clear_before_load
            if empty(s:this_session)
                call session_manager#clearAllBuffers()
            else
                call session_manager#sessionClose()
            endif
        endif
        execute('source '.l:session_file)
        nohlsearch
        keepalt noautocmd windo if &ft ==# '' | bwipeout! | endif
        " if bufexists("__SessionList__")
        "     bwipeout! __SessionList__
        " endif
        let s:this_session = l:session_file
        if exists('s:this_session_description') | unlet s:this_session_description | endif
        " call session_manager#updateSessionHistory()
        normal! zvzz
    endif
    return 0
endfunction

function! session_manager#sessionList() abort
    if bufexists("__SessionList__")
        let l:session_list_exists = (bufwinnr('__SessionList__') !=# -1)
        bwipeout! __SessionList__
        if l:session_list_exists
            return
        endif
    endif

    let l:sessions = globpath(g:session_dir, '*.vim', 1, 1)

    let l:session_descriptions = []
    for sfp in l:sessions
        let l:session_file_line1 = readfile(sfp, '', 1)[0]
        if l:session_file_line1[0] ==# '"'
            let l:session_descriptions += [trim(l:session_file_line1[1:])]
        else
            let l:session_descriptions += ['']
        endif
    endfor

    call map(l:sessions, "fnamemodify(v:val, ':t:r')")
    let l:this_session_index = index(l:sessions, session_manager#getSessionName(s:this_session))
    call map(l:sessions, "'  '.v:val")
    if l:this_session_index !=# -1
        let l:sessions[l:this_session_index] = ' *'.l:sessions[l:this_session_index][2:]
    endif
    let l:session_names = deepcopy(l:sessions)
    let l:maxlen = max(map(l:sessions, 'strlen(v:val)') + [7])

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

function! session_manager#sessionListHighlight() abort
    syntax match SessionListName '\v\S+'
    syntax match SessionListDescription '\v%(\S+)@<=.*'
    syntax match SessionListType '\vSession\s+Description'
    syntax match SessionListSeparator '\v\=+'
    highlight link SessionListType Type
    highlight link SessionListName Keyword
    highlight link SessionListDescription String
    highlight link SessionListSeparator Comment
endfunction

function! session_manager#sessionListSetOptions() abort
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

function! session_manager#sessionDelete(bang, ...) abort
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
                " call delete(s:session_history_file)
                " echomsg 'Delete session: '.s:this_session
                let s:this_session = ''
            else
                call session_manager#echoError("You are not in a session!")
                return
            endif
        endif
    " if user specify arguments, and the sessions exist, delete those sessions
        for ss in a:000
            let l:session = g:session_dir.ss.'.vim'
            if l:session ==# s:this_session
                " call delete(s:session_history_file)
                let s:this_session = ''
            endif
            if filereadable(l:session)
                call delete(l:session)
            else
                call session_manager#echoError("Session: '".ss."' does not exist!")
                " return
            endif
        endfor
    endif
endfunction

function! session_manager#enterSessionFromList() abort
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

function! session_manager#sessionRename(...) abort
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
        " call session_manager#updateSessionHistory()
    endif
endfunction

function! session_manager#sessionClose() abort
    if s:this_session ==# ''
        call session_manager#echoError('You are not in a session!')
        return
    endif
    call session_manager#sessionSave()
    call session_manager#updateSessionHistory()
    let s:this_session = ''
    call session_manager#clearAllBuffers()
endfunction

function! session_manager#sessionCommandComplete(ArgLead, CmdLine, CursorPos) abort
    return join(map(globpath(g:session_dir, '*.vim', 1, 1), 'fnamemodify(v:val, ":t:r")'), "\n")
endfunction

function! session_manager#checkSessionDirectory() abort
    if g:session_dir[strlen(g:session_dir)-1] !~# '\v[\/]'
        let g:session_dir .= '/'
    endif
    let g:session_dir = substitute(g:session_dir, '\v\\', '/', 'g')
    if !isdirectory(g:session_dir)
        call mkdir(g:session_dir, "p")
    endif
endfunction

function! SessionStatusLine() abort
    return fnamemodify(s:this_session, ':t:r')
endfunction

augroup track_session_group
    autocmd!
    " FIXME: cursor will goto line 1
    autocmd BufEnter * if g:session_track_current_session ==# 1 && s:this_session !=# '' | call session_manager#sessionSave() | endif
augroup END
