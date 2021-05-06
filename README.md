# vim-session-manager

vim-session-manager is a fast, lightweight, and easy-to-use session manager plugin.

- Navigate in a session list
- Save current session
- Add description to a session
- Load a session
- Rename a session
- Track current session
- Delete a session
- Close current session
- Automatically remember the last session you used
- Automatically save current session when exiting Vim
- Automatically load last session when entering Vim

## Introduction

This plugin is based on vim's bulit-in `:mksession` command.

This plugin is inspired by [obsession](https://github.com/tpope/vim-obsession) and vscode plugin Project Manager.

Compared to [obsession](https://github.com/tpope/vim-obsession), this plugin provides more functions.
Compared to [vim-session](https://github.com/xolox/vim-session), this plugin is easier to use and does not rely on other plugin.

## Installation

[vim-plug](https://github.com/junegunn/vim-plug)

```vim
Plug 'lwflwf1/vim-session-manager'
```

[dein](https://github.com/Shougo/dein.vim)

```vim
call dein#add('lwflwf1/vim-session-manager')
```

## Usage
### commands
```vim
:SessionSave [{name}:{description}]
```
Use this command to save a session. For example `:SessionSave abc:this is abc`

The part before `:` is the **session name**, the part after `:` is the **description**.

You can omit `:` if you do not want to add a description.

If you are already in a session, you can use this command without arguments to save current session. However you can specify a new name, then current session will be saved in new name and you will be changed to the new session.

If you are **not** in a session, using this command without arguments will save current session as **default_session**.

```vim
:SessionLoad [{name}]
```
Use this command to load a session. For example `:SessionLoad abc`

If you use this command without arguments, the **last session** you loaded or saved will be loaded. If the last session is not existed, then **default_session** will be loaded.

```vim
:SessionList
```
Use this command to open a session list.

You can see all sessions in the session list, and you can navigate in it to enter a session or delete a session.

```vim
:SessionDelete[!] [{name1} {name2} ...]
```
Use this command to delete a session. For example `:SessionDelete abc`

All sessions that you specified will be deleted.

If you use this command with bang`!`, all sessions will be deleted.

If you use this command without arguments, the current session will be deleted.

```vim
:SessionRename {old name} {new name}
```
Use this command to rename a session. For example `SessionRename abc def`

If you rename current session, you will be changed to the new session.

```vim
:SessionClose
```
Use this command to close current session.

This command will save all unsaved changes and wipeout all buffers.

### configuration

```vim
g:session_autosave_enable
```
`default: 1`

Whether to save current session when exiting vim.

```vim
g:session_autoload_enable
```
`default: 0`

Whether to load last session you used when entering vim.

```vim
g:session_dir
```
`default: if use vim: '~/.vim/session'; if use neovim: stdpath('data').'/session'`

The session directory

```vim
g:session_track_current_session
```
`default: 0`

Whether to track current session

If you set this to 1, then once event `BufEnter` is triggerd, command `Sessionsave` will automatically called.

```vim
g:session_clear_before_load
```
`default: 1`

Load a session will wipeout all buffers by default. Set it to 0 can disable this behavier.

## Bugs

## License

## Credits
