" File: search_buffer.vim
"" Description: Create and maintain the Search Result buffer
"" Version: 1.0
"" Author: ghoshs (subhagho@msn.com)
"" Namespace: vimper#project#search_buffer

setlocal nomodifiable

let s:SearchFile = ""
let s:LastSearchLine = 0
let s:BufferName = ""
let s:Regex = ""

command! -n=? VSQuit :call vimper#project#search_buffer#Quit()
command! -n=? VSNext :call vimper#project#search_buffer#Next(1)
command! -n=? VSPrev :call vimper#project#search_buffer#Next(-1)
command! -n=? VSReop :call vimper#project#search_buffer#ReOpen()

function! vimper#project#search_buffer#ReOpen()
        if empty(s:BufferName)
                return
        endif
        let wSize = 10
        if exists("g:vimperOutputWindowHeight") && g:vimperOutputWindowHeight
                let wSize = g:vimperOutputWindowHeight
        endif

        " If the tag listing temporary buffer already exists, then reuse it.
        " Otherwise create a new buffer
        let bufnum = vimper#Utils#CheckBufferExists(s:BufferName)
        let wcmd =  s:SearchFile
        if bufnum != -1
                let l:retval = vimper#Utils#GotoWindow(s:BufferName)
                if l:retval == 1
                        return 0
                else
                        let wcmd = '+buffer' . bufnum
                endif
        endif
        let win_dir = 'botright '

        exe 'silent! ' . win_dir . ' ' . wSize . 'split ' . wcmd

        setlocal nonumber
        setlocal nomodifiable
        call vimper#project#search_buffer#Next(0)
        return 1
endfunction " s:OpenBrowser()

"" Show() -             Show the current search file in the buffer
"  Args :
"  	searchfile      --> Search file to show.
"  	regex           --> The regex used to search 
function! vimper#project#search_buffer#Results(searchfile, regex)
        let s:SearchFile = a:searchfile
        let s:Regex = a:regex
        " clear buffer
        " setlocal modifiable | silent! normal ggdG
        " setlocal nomodifiable

        let mt = matchlist(s:SearchFile, "[^/]*$")
        if empty(mt)
                return
        endif

        let s:BufferName = mt[0]
        let wSize = 10
        if exists("g:vimperOutputWindowHeight") && g:vimperOutputWindowHeight
                let wSize = g:vimperOutputWindowHeight
        endif
        let win_dir = 'botright vertical'

        " If the tag listing temporary buffer already exists, then reuse it.
        " Otherwise create a new buffer
        let bufnum = vimper#Utils#CheckBufferExists(s:BufferName)
        let wcmd = s:SearchFile
        if bufnum != -1
                let l:retval = vimper#Utils#GotoWindow(s:BufferName)
                if l:retval == 1
                        return 0
                else
                        let wcmd = '+buffer' . bufnum
                endif
        endif
        let win_dir = 'botright '

        let ocmd = win_dir . ' ' . wSize . 'split ' . wcmd
        exe ocmd

        setlocal nomodifiable
        setlocal nonumber

        if has("syntax") && exists("g:syntax_on")
                execute "syn match SearchRx #" . s:Regex . "#"
                if has('win32')
                        syn match SearchFile "^[A-Z]:[^:]*:"
                else
                        syn match SearchFile "^[^:]*:"
                endif
                syn match SearchLine "[0-9]\+:"

                hi def link SearchRx Search
                hi def link SearchFile Question
                hi def link SearchLine Identifier
        endif

        call vimper#Utils#AddLockedBuffer(s:BufferName)    
        nnoremap <buffer> <cr>  :call vimper#project#search_buffer#ShowResults()<cr>
        nnoremap <buffer> <2-leftmouse>  :call vimper#project#search_buffer#ShowResults()<cr>
        nnoremap <buffer> n     :call vimper#project#search_buffer#Next(1)<cr>
        nnoremap <buffer> p     :call vimper#project#search_buffer#Next(-1)<cr>
        nnoremap <buffer> q     :call vimper#project#search_buffer#Quit()<cr>

        let s:LastSearchLine = 0

        call vimper#project#search_buffer#Next(1)
endfunction " Show()

function! vimper#project#search_buffer#Quit()
        au WinEnter * set nocursorline 
        au WinLeave * set nocursorline 
        set nocursorline 

        if !bufexists(bufname(s:BufferName))
                return
        endif

        let bufn = bufwinnr(bufname(s:BufferName))
        if bufn < 0
                return 0
        endif
        let s:SearchFile = ""
        let s:LastSearchLine = 0

        let s:BufferName = ""

        execute "bdelete " . bufname(s:BufferName)
endfunction "Quit()

function! vimper#project#search_buffer#Next(direction)
        if !bufexists(bufname(s:BufferName))
                return
        endif

        let bufn = bufwinnr(bufname(s:BufferName))
        if bufn < 0
                return 0
        endif

        execute bufn . "wincmd W"

        let s:LastSearchLine =  s:LastSearchLine + a:direction
        while 1 == 1
                if s:LastSearchLine > line('$') || s:LastSearchLine < 0
                        let s:LineSearchLine = 0
                        return
                endif

                execute s:LastSearchLine 
                if vimper#project#search_buffer#ShowResults() >= 0
                        return
                endif

                let s:LastSearchLine =  s:LastSearchLine + a:direction
        endwhile

endfunction " Next()

function! vimper#project#search_buffer#ShowResults()
        let l:line = getline('.')
        if empty(l:line)
                return -1
        endif

        let mt = split(l:line, ":")
        if empty(mt) 
                return -1
        endif

        let l:filen = ""
        let l:linen = "0"

        if has('win32')
		if len(mt) < 4
			return -1
		endif
                if mt[0] =~ '[a-z|A-Z]'
                        let l:filen = mt[0] . ":" . mt[1]
                        let l:linen = mt[2]
                else
                        let l:filen = mt[0]
                        let l:linen = mt[1]
                endif
        else
		if len(mt) < 2
			return -1
		endif
                let l:filen = mt[0]
                let l:linen = mt[1]
        endif

        let s:LastSearchLine = line(".")

        call vimper#Utils#OpenInWindow(l:filen)
        "execute "wincmd k" 
        "execute "edit " . l:filen
        execute l:linen

        au BufRead WinEnter * set nocursorline 
        au BufRead WinLeave * set cursorline 
        set cursorline 

        "let bufn = bufwinnr(bufname(s:BufferName))
        "if bufn < 0
        "        return 0
        "endif

        "execute bufn . "wincmd W"
        "execute s:LastSearchLine

        return s:LastSearchLine
endfunction " ShowResults()
