" Description:   vim-session-manager - Make session management easier.
" Maintainer:    lwflwf1
" Website:       https://github.com/lwflwf1/vim-session-manager
" Created Time:  2021-04-21 16:03:18
" Last Modified: 2021-04-22 00:16:55
" File:          vim-session-manager.vim
" Version:       0.1.1
" License:       MIT

if exists("g:loaded_vim_session_manager")
    finish
endif

let g:loaded_vim_session_manager = 1

let s:save_cpo = &cpo
set cpo&vim

if has('nvim')
    let g:session_dir = stdpath('data').'/session/'
else
    let g:session_dir = '~/.vim/session/'
endif

let g:session_autosave_enable = 1
let g:session_autoload_enable = 0
let g:session_clear_before_load = 1
let g:session_track_current_session = 0

let s:this_session = ''
let s:last_session_file = g:session_dir.'.last_session'

function s:echoError(...) abort
    echohl ErrorMsg
    for msg in a:000
        echomsg msg
    endfor
    echohl None
endfunction

function s:saveLastSessionName() abort
    if empty(s:this_session)
        let s:this_session = g:session_dir."default_session.vim"
    endif
    call writefile([s:this_session], s:last_session_file)
endfunction

function s:getLastSessionName() abort
    if filereadable(s:last_session_file)
        " let s:this_session = readfile(s:last_session_file, '', 1)[0]
        return s:getSessionName(readfile(s:last_session_file, '', 1)[0])
    else
        return 'No Last Session'
    endif
endfunction

function s:getSessionName(session_full_path) abort
    " return substitute(a:session_full_path, '\v.*[\/]|\.vim', '', 'g')
    return fnamemodify(a:session_full_path, ':t:r')
endfunction

function s:getListedBufnrs() abort
    return filter(range(1, bufnr('$')), 'buflisted(v:val)')
endfunction

function s:clearAllBuffers(flag) abort
    if a:flag
        wall
        " for bufnr in GetListedBufnrs()
        "     execute "bwipeout ".bufnr
        " endfor
        silent %bwipeout
    endif
endfunction

function s:sessionSave(...) abort
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
    call s:saveLastSessionName()
endfunction

function s:sessionLoad(...) abort
    if a:0 ==# 0
        if empty(s:this_session)
            let l:session_name = 'default_session'
            let l:session_file = g:session_dir.l:session_name.'.vim'
        else
            let l:session_name = s:getSessionName(s:this_session)
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
        call s:echoError("You are already in the session: '".l:session_name."'!")
        return 1
    endif

    if !filereadable(l:session_file)
        call s:echoError("Session: '".l:session_name."' does not exist!")
        return 1
    else
        let s:this_session = ''
        call s:clearAllBuffers(g:session_clear_before_load)
        execute('source '.l:session_file)
        if bufexists("__SessionList__")
            bwipeout! __SessionList__
        endif
        let s:this_session = l:session_file
        call s:saveLastSessionName()
        normal! zvzz
    endif
    return 0
endfunction

function s:sessionList() abort
    if bufexists("__SessionList__")
        let l:isSessionListVisible = bufwinnr('__SessionList__') !=# -1
        bwipeout! __SessionList__
        if l:isSessionListVisible
            return
        endif
    endif
    let l:session_files = globpath(g:session_dir, '*.vim')
    let l:sessions = split(substitute(l:session_files, '\v[^\n]*[\/]%(\S+\.vim)@=|\.vim', '', 'g'), '\n')
    let l:this_session_index = index(l:sessions, s:getSessionName(s:this_session))
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

    if bufname() ==# '' && winnr('$') ==# 1
        file __SessionList__
    else
        set splitbelow
        botright split __SessionList__
    endif
    setlocal filetype=sessionlist

    call append(0, l:session_infos)
    call cursor(4, 1)
    call s:sessionListSetOptions()
    call s:sessionListHighlight()
endfunction

function s:sessionListHighlight() abort
    syntax match SessionListName '\v\S+'
    syntax match SessionListDescription '\v%(\S+)@<=.*'
    syntax match SessionListType '\vSession\s+Description'
    syntax match SessionListSeparator '\v\=+'
    highlight link SessionListType Type
    highlight link SessionListName Keyword
    highlight link SessionListDescription String
    highlight link SessionListSeparator Comment
endfunction

function s:sessionListSetOptions() abort
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

    nnoremap <silent> <buffer> dd :<c-u>call <SID>sessionDelete(0)<cr>
    nnoremap <silent> <buffer> <cr> :<c-u>call <SID>enterSessionFromList()<cr>
    nnoremap <silent> <buffer> q :<c-u>bwipeout!<cr>
endfunction

function s:sessionDelete(bang, ...) abort
    let l:delete_this_session_flag = 0
    " if use !, delete all sessions
    if a:bang
        call delete(g:session_dir, 'rf')
        call s:checkSessionDirectory()
        let s:this_session = ''
        echomsg 'All sessions are deleted!'
        return
    endif
    " if user not specify argument
    if a:0 ==# 0
        if &ft ==# 'sessionlist'
            if index([1, 2, 3], line('.')) !=# -1
                call s:echoError("You can not do that!")
                return
            endif
            " delete session under cursor
            let l:session_name = matchstr(getline("."), '\v\S+')
            let l:this_session_name = s:getSessionName(s:this_session)
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
                call s:echoError("You are not in a session!")
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
                call s:echoError("Session: '".ss."' does not exist")
                return
            endif
        endfor
    endif
endfunction

function s:enterSessionFromList() abort
    if index([1, 2, 3], line('.')) !=# -1
        call s:echoError("You can not do that!")
        return
    endif
    call cursor(0, 1)
    let l:session = matchstr(getline("."), '\v\S+')
    let l:this_session_name = s:getSessionName(s:this_session)
    if l:session ==# '*'.l:this_session_name
        let l:session = l:this_session_name
    endif
    call s:sessionLoad(l:session)
endfunction

function s:sessionRename(...) abort
    if a:0 != 2
        call s:echoError("Require 2 arguments: {old_name} {new_name}!")
        return
    endif
    let l:old_session = g:session_dir.a:1.'.vim'
    let l:new_session = g:session_dir.a:2.'.vim'
    if !filereadable(l:old_session)
        call s:echoError("Session: '".a:1."' does not exist!")
        return
    endif
    call writefile(readfile(l:old_session), l:new_session)
    call delete(l:old_session)
    if l:old_session ==# s:this_session
        let s:this_session = l:new_session
        call s:saveLastSessionName()
    endif
endfunction

function s:sessionClose() abort
    if s:this_session ==# ''
        s:echoError('You are not in a session!')
        return
    endif
    let s:this_session = ''
    call s:clearAllBuffers(1)
endfunction

function s:sessionCommandComplete(ArgLead, CmdLine, CursorPos) abort
    return substitute(globpath(g:session_dir, '*.vim'), '\v[^\n]*[\/]%(\S+\.vim)@=|\.vim', '', 'g')
endfunction

function s:checkSessionDirectory() abort
    if g:session_dir[strlen(g:session_dir)-1] !~# '\v[\/]'
        let g:session_dir .= '/'
    endif
    let g:session_dir = substitute(g:session_dir, '\v\\', '/', 'g')
    if !isdirectory(g:session_dir)
        call mkdir(g:session_dir, "p")
    endif
endfunction
" function Atest(...) abort
"     if &filetype ==# 'sessionlist'
"         let w:airline_section_a = 'SessionList'
"         let w:airline_section_b = ''
"         let w:airline_section_c = 'q: quit; dd: delete session; <cr>: enter session'
"         let w:airline_section_x = ''
"         let w:airline_section_y = ''
"         let w:airline_section_z = ''
"     endif
" endfunction
" call airline#add_statusline_func('Atest')
function s:test() abort
    let g:airline_section_c .= airline#section#create(['%{SessionStatusLine()}'])
"     call airline#parts#define_function('sessionlist', 'GetSessionListFileType')
"     call airline#parts#define_condition('sessionlist', '&ft ==# "sessionlist"')
    " let g:airline_section_a = airline#section#create_right(['sessionlist'])
endfunction

function SessionStatusLine() abort
    " let l:this_session_name = substitute(s:this_session, '\v.*[\/]|\.vim', '', 'g')
    " if !empty(l:this_session_name)
    "     let l:this_session_name = '$'.l:this_session_name
    " endif
    return s:getSessionName(s:this_session)
endfunction

augroup session_manager_statusline_group
    autocmd!
    autocmd User AirlineAfterInit call s:test()
augroup END

augroup session_auto_save_load_group
    autocmd!
    autocmd VimEnter * ++nested if g:session_autoload_enable ==# 1 | call s:sessionLoad(s:getLastSessionName()) | endif
    autocmd VimLeavePre * if g:session_autosave_enable ==# 1 | call s:sessionSave() | endif
    " FIXME: cursor will goto line 1
    autocmd BufEnter * if g:session_track_current_session ==# 1 && !empty(s:this_session) | call s:sessionSave() | endif
augroup END

command! -nargs=0 SessionList call s:sessionList()
command! -nargs=0 SessionClose call s:sessionClose()
command! -nargs=? -complete=custom,s:sessionCommandComplete SessionSave call s:sessionSave(<f-args>)
command! -nargs=? -complete=custom,s:sessionCommandComplete SessionLoad call s:sessionLoad(<f-args>)
command! -nargs=* -bang -complete=custom,s:sessionCommandComplete SessionDelete call s:sessionDelete(<bang>0, <f-args>)
command! -nargs=+ -complete=custom,s:sessionCommandComplete SessionRename call s:sessionRename(<f-args>)

call s:checkSessionDirectory()

let &cpo = s:save_cpo
unlet s:save_cpo
