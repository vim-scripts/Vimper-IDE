"" File:        Utils.vim
"" Description: Common utilities functions
"" Version:     $Revision: 1.24 $ $Date: 2005/11/17 16:24:33 $
"" Author:      ghoshs (sughosh@msn.com)
"" Namespace:   vimper#Utils
""
let s:_LOCKED_BUFFERS = {}

"" CheckBufferExists        Check if a buffer with the name 
"                           is already loaded. Even if not visible.
"  Args:
"       name                --> Name of the buffer to search for
"  Return:                  --> Buffer number if exists else -1
function! vimper#Utils#CheckBufferExists(name)
	let l:name = bufname(a:name)
	if empty(l:name)
		return -1
	endif
	let l:bnum = bufnr(l:name)
	return l:bnum
endfunction " CheckBufferExists()

"" IsBufferInTab            Is the buffer opened in one of the
"                           viewports in the specified tab.
"  Args:
"       tabnr               --> Tab id of the tab to check in
"       name                --> Name of the buffer.
"  Return:                  --> 1 if exists in tabpage else 0
function! vimper#Utils#IsBufferInTab(tabnr, name)
	let l:bnum = vimper#Utils#CheckBufferExists(a:name)
	if l:bnum < 0
		return 0
	endif
	for l:tabbuf in tabpagebuflist(a:tabnr)
		if l:bnum == l:tabbuf
			return 1
		endif
	endfor
	return 0
endfunction " IsBufferInTab()

"" IsBufferInTabs           Check if a buffer with the name 
"                           exists in one of the tabs.
"  Args:
"       name                --> Name of the buffer to search for
"  Return:                  --> Tab number if exists else -1
function! vimper#Utils#IsBufferInTabs(name)
	let l:bnum = vimper#Utils#CheckBufferExists(a:name)
	if l:bnum < 0
		return 0
	endif
	for l:tabs in range(tabpagenr('$'))
		let l:tabnr = l:tabs + 1
		let l:tabret = vimper#Utils#IsBufferInTab(l:tabnr, a:name)
		if l:tabret >= 0
			return l:tabret
		endif
	endfor
	return -1
endfunction " IsBufferInTabs()

"" GotoTabWindow            Goto the window which is the
"                           viewport for the buffer 
"                           sepcified by the name.
"  Args:
"       name                --> Name of the buffer to search for
function! vimper#Utils#GotoTabWindow(name)
	let l:tabnr = vimper#Utils#IsBufferInTabs(a:name)
	if l:tabnr < 0
		echo "Buffer " . a:name . " not found."
		return 0
	endif
	execute "tabn " . l:tabnr

	let l:bufname = bufname(a:name)
	let l:winnr = bufwinnr(l:bufname)
	execute l:winnr . "wincmd w"

	return 1
endfunction " GotoTabWindow()

"" GotoWindow             Goto the window which is the
"                         viewport for the buffer
"                         specified by the name
"  Args:
"       name                --> Name of the buffer to search for
function! vimper#Utils#GotoWindow(name)
	let l:bnum = vimper#Utils#CheckBufferExists(a:name)
	if l:bnum < 0
		return 0
	endif

	let l:bufname = bufname(a:name)
	let l:winnr = bufwinnr(l:bufname)
	if l:winnr < 0
		return 0
	endif
	let l:cmd = l:winnr . "wincmd w"

	execute l:cmd

	return 1
endfunction " GotoWindow()

"" GetTabbedBufferName    Get a new buffer name to be used
"                         for creating temporary buffers.
"  Args:  
"       prefix            --> Prefix to start the buffer name with
function! vimper#Utils#GetTabbedBufferName(prefix)
	return a:prefix . "_" . tabpagenr()
endfunction " GetTabbedBufferName()

function! vimper#Utils#ClearBuffer(name)
	let l:curwinnr = winnr()
	let l:bnum =  vimper#Utils#CheckBufferExists(a:name)
	if l:bnum < 0
		return 0
	endif

	let l:retval = vimper#Utils#GotoWindow(a:name)
	if l:retval == 0
		return 0
	endif
	let end = line('$')
	setlocal modifiable
	exe 'silent! 0,' . end . 'delete _'
	setlocal nomodifiable

	if l:curwinnr > 0
		execute l:curwinnr . "wincmd w"
	endif
	return 1
endfunction " ClearBuffer()

function! vimper#Utils#AddLockedBuffer(name)
	let l:bnum =  vimper#Utils#CheckBufferExists(a:name)
	if l:bnum < 0
		return 0
	endif

	let l:bufname = bufname(a:name)
	let s:_LOCKED_BUFFERS[l:bufname] = l:bnum
	return 1
endfunction " AddLockedBuffer()

function! vimper#Utils#IsLockedBuffer(name)
	let l:bnum =  vimper#Utils#CheckBufferExists(a:name)
	if l:bnum < 0
		return 0
	endif
	let l:bufname = bufname(a:name)
	if has_key(s:_LOCKED_BUFFERS, l:bufname)
		return 1
	else
		" Check only with the name and not full path
		if has('win32')
			let l:bufname = vimper#project#common#WinConvertPath(l:bufname)
		endif
		let l:bufname = substitute(l:bufname, "^.*[/]", "","g")
		if has_key(s:_LOCKED_BUFFERS, l:bufname)
			return 1
		else
			return 0
		endif
	endif
	return 0
endfunction " IsLockedBuffer()

function! vimper#Utils#OpenInWindow(bufname)
	let l:tabnr = tabpagenr() 
	for l:tabbuf in tabpagebuflist(l:tabnr)
		let l:winnr = bufwinnr(l:tabbuf)
		if l:winnr < 0
			continue
		endif
		let l:bufname = bufname(l:tabbuf)
		if !empty(l:bufname) && vimper#Utils#IsLockedBuffer(l:bufname)
			continue
		endif
		execute l:winnr . "wincmd w"
		if &modified
			continue
		endif
		let l:bnum = vimper#Utils#CheckBufferExists(a:bufname)
		if l:bnum >= 0
			execute "buffer " . l:bnum
		else
			call vimper#project#session#SessionManager#AddFile(g:vimperProjectRoot, expand(a:bufname))
			execute "edit " . a:bufname
		endif
		return 1
	endfor
	return 0
endfunction " OpenInWindow()
