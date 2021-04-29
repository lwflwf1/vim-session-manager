" Description:   vim-session-manager - Make session management easier.
" Maintainer:    lwflwf1
" Website:       https://github.com/lwflwf1/vim-session-manager.com
" Created Time:  2021-04-21 16:03:18
" Last Modified: 2021-04-30 00:52:39
" File:          vim-session-manager.vim
" Version:       0.1.3
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

augroup session_auto_save_load_group
    autocmd!
    autocmd VimEnter * ++nested if g:session_autoload_enable ==# 1 | call session_manager#sessionLoad(session_manager#getLastSessionName()) | endif
    autocmd VimLeavePre * if g:session_autosave_enable ==# 1 | call session_manager#sessionSave() | endif
    " FIXME: cursor will goto line 1
    autocmd BufEnter * if g:session_track_current_session ==# 1 && !empty(s:this_session) | call session_manager#sessionSave() | endif
augroup END

command! -nargs=0 SessionList call session_manager#sessionList()
command! -nargs=0 SessionClose call session_manager#sessionClose()
command! -nargs=? -complete=custom,session_manager#sessionCommandComplete SessionSave call session_manager#sessionSave(<f-args>)
command! -nargs=? -complete=custom,session_manager#sessionCommandComplete SessionLoad call session_manager#sessionLoad(<f-args>)
command! -nargs=* -bang -complete=custom,session_manager#sessionCommandComplete SessionDelete call session_manager#sessionDelete(<bang>0, <f-args>)
command! -nargs=+ -complete=custom,session_manager#sessionCommandComplete SessionRename call session_manager#sessionRename(<f-args>)

call session_manager#checkSessionDirectory()

let &cpo = s:save_cpo
unlet s:save_cpo
