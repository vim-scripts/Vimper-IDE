"" File:        classexplorer.vim
"" Description: tree-like file system explorer for vim
"" Version:     $Revision: 1.24 $ $Date: 2005/11/17 16:24:33 $
"" Author:      ghoshs (sughosh@msn.com)
""

"" prevent multiple loading unless developing with g:treeExplDebug
if exists("vloaded_class_explorer")
	finish
endif
let vloaded_class_explorer=1
let g:_SUPPORTED_EXTS = { 'cpp':'cpp|cxx|c|hpp|HPP|h|H|CPP|CXX|C'}

let s:cpo_save = &cpo
set cpo&vim
command! -n=? VClassBr :call s:OpenBrowser()

"" create a string of chr cnt long - emulate vim7 repeat function
function! s:MyRepeat(chr, cnt) " <<<
	let sret = ""
	let lcnt = a:cnt
	while lcnt > 0
		let sret = sret . a:chr
		let lcnt = lcnt - 1
	endwhile
	return sret
endf " >>>

let s:_TYPESDICT = {}

"" ClassExplorer() - set up explorer window
function! s:SetupEnv() " <<<
	"" chars to escape in file/dir names - TODO '+' ?
	" throwaway buffer options
	setlocal noswapfile
	setlocal buftype=nowrite
	setlocal bufhidden=delete " d
	setlocal nowrap
	setlocal foldcolumn=0
	setlocal nonumber

	if exists("g:treeExplNoList")
		setlocal nobuflisted
	endif
	if has('spell')
		setlocal nospell
	endif
	iabc <buffer>

	" setup folding for markers that will be inserted
	setlocal foldmethod=marker
	setlocal foldtext=substitute(getline(v:foldstart),'.{{{.*','','')
	setlocal foldlevel=1

	" syntax highlighting
	if has("syntax") && exists("g:syntax_on") && !has("cb_syntax_items")

		syn match treeFld     "{{{"
		syn match treeFld     "}}}"
		syn match hiddentxt   "\[\[\[.*\]\]\]"
		syn match entities       "\(CLASSES\|FUNCTIONS\|ENUMS\|STRUCTS\)"
		syn match typeParts   "\(Enum\:\|Struct\:\|Class\:\)"
		syn match typeMembs   "\(Members\|Methods\|Prototypes\|Definitions\)"
		syn match namespace   'namespace \[.\{-}\]' 
		syn match inherits    'inherits \[.\{-}\]' 
		syn match public      "(\*)"
		syn match protected   "(+)"
		syn match private     "(!)\|(?)"

		hi def link hiddentxt Ignore
		hi def link treeFld Ignore
		hi def link typeMembs Special
		hi def link typeParts Directory
		hi def link entities TabLineSel
		hi def link namespace Question
		hi def link inherits Constant
		hi def link method Type
		hi def link private WarningMsg
		hi def link public Structure
		hi def link protected ModeMsg
		hi def link argmnts Special
	endif

	autocmd BufEnter * setlocal cursorline
	autocmd BufLeave * setlocal nocursorline
	
	" for line continuation
	let cpo_save1 = &cpo
	set cpo&vim

	" set up mappings and commands for this buffer
	nnoremap <buffer> o    :call <SID>ActivateEntity()<cr>
	nnoremap <buffer> X    :call <SID>RecursiveExpand()<cr>
	nnoremap <buffer> S    :call <SID>ShowTypes(1)<cr>
	nnoremap <buffer> <2-leftmouse> :call <SID>ActivateEntity()<cr>

	let &cpo = cpo_save1 " restore

endfunction " >>>

function! s:ActivateEntity()
	let l:line = getline(".")
	if empty(l:line)
		return
	endif

	if l:line =~ "\]\]\]$"
		let l:line = substitute(l:line, ".*\[\[\[", "", "")
		let l:line = substitute(l:line, "\]\]\]$", "", "")
		if empty(l:line)
			return
		endif
		let data = split(l:line, "||")
		if empty(data) || len(data) < 2
			return
		endif
		let cmd = substitute(data[0], "\\", "", "")
		let file = data[1]
		call s:OpenFile(file, cmd)
	endif
endfunction " ActivateEntity()

function! s:OpenFile(filename, cmd)
	if empty(a:filename)
		return
	endif
	let l:opened = 0
	let l:bufname = bufname(a:filename)
	if bufexists(l:bufname)
		if bufwinnr(l:bufname) >= 0
			let l:winnr = bufwinnr(l:bufname)
			let l:opened = 1
			execute l:winnr . "wincmd w"
		else
			let l:bufnr = bufnr(l:bufname)
			if l:bufnr >= 0
				for l:tabs in range(tabpagenr('$'))
					let l:tabnr = l:tabs + 1
					for l:tabbuf in tabpagebuflist(l:tabnr)
						if l:tabbuf == l:bufnr
							let l:opened = 1
							execute "tabn " . l:tabnr
							let l:winnr = bufwinnr(l:bufname)
							execute l:winnr . "wincmd w"
						endif
					endfor
				endfor
			endif
		endif
	endif
	if !l:opened
		execute "tabf " . a:filename
	endif
	let l:retval = vimper#Utils#GotoWindow(a:filename)
	if l:retval < 0
		return
	endif
	let l:cmd = escape(a:cmd, '*~[]')
	execute l:cmd
endfunction " OpenFile()

"" InitWithFile() - Open the types defined in the file in the ClassBrowser
function! s:InitWithFile(filename, root) " <<<
	let l:_TYPESDICT = {}
	call s:SetupEnv()

	let l:typesdict = {}
	if a:filename != ""
		let l:typesdict = vimper#project#cpp#class_buffer#LoadFile(a:filename, a:root)
	else
		return
	endif
	if empty(l:typesdict)
		return
	endif

	let s:_TYPESDICT = l:typesdict
	call s:ShowTypes(0)

endfunction " >>>

function! s:ShowTypes(sort)
	" clear buffer
	setlocal modifiable | silent! normal ggdG
	setlocal nomodifiable

	if empty(s:_TYPESDICT)
		return
	endif
	execute "sign define VHeading linehl=Visual"

	for [key, value] in items(s:_TYPESDICT)
		if key == "class"
			call s:ShowClasses(value, getline("."), a:sort)
		elseif key == "enum"
			call s:ShowEnums(value, getline("."), a:sort)
		elseif key == "struct"
			call s:ShowStructs(value, getline("."), a:sort)
		elseif key == "function"
			call s:ShowFunctions(value, getline("."), a:sort)
		endif
	endfor
endfunction " ShowTypes()

function! s:ShowFunctions(funcdict, line, sort)
	if empty(a:funcdict)
		return
	endif
	let @f = "FUNCTIONS "
	setlocal modifiable | silent put f | setlocal nomodifiable
	execute "sign place " . line('.') . " line=" . line('.') . " name=VHeading buffer=" . bufnr("")

	let l:funcdict = {}
	if has_key(a:funcdict, "funcd")
		let l:funcdict = a:funcdict["funcd"]
	elseif has_key(a:funcdict, "funcp")
		let l:funcdict = a:funcdict["funcp"]
	else
		return
	endif
	if a:sort
		for [key, value] in sort(items(l:funcdict))
			let @f = "  |- " . value["name"] . value["signature"] . "[[[" . value["cmd"] . "||" . value["filename"] . "]]]"
			setlocal modifiable | silent put f | setlocal nomodifiable
		endfor
	else
		for [key, value] in items(l:funcdict)
			let @f = "  |- " . value["name"] . value["signature"] . "[[[" . value["cmd"] . "||" . value["filename"] . "]]]"
			setlocal modifiable | silent put f | setlocal nomodifiable
		endfor
	endif
	let @f = "  --" " End functions fold
	setlocal modifiable | silent put f | setlocal nomodifiable
endfunction " ShowFunctions()

function! s:ShowEnums(enumdict, line, sort)
	if empty(a:enumdict)
		return
	endif
	let @f = "ENUMS "
	setlocal modifiable | silent put f | setlocal nomodifiable

	execute "sign place " . line('.') . " line=" . line('.') . " name=VHeading buffer=" . bufnr("")
	for [key, value] in items(a:enumdict)
		if has_key(value, "def")
			let l:enumdef = value["def"]
			if !empty(l:enumdef)
				let l:ename = "  |-Enum: " . l:enumdef["name"]
				if has_key(l:enumdef, "namespace")
					let l:ename = l:ename . " namespace [" . l:enumdef["namespace"] . "]"
				endif
				let @f = l:ename . "{{{"
				setlocal modifiable | silent put f | setlocal nomodifiable
			else
				continue
			endif
		else
			continue
		endif
		if has_key(value, "members")
			let l:members = value["members"]
			if !empty(l:members)
				let l:heading = "  |  |-" . "Members : {{{"
				let @f = l:heading
				setlocal modifiable | silent put f | setlocal nomodifiable

				if a:sort
					for [mkey, mvalue] in sort(items(l:members))
						let @f = "  |  |  |- " . mvalue["name"] . "[[[" . mvalue["cmd"] . "||" . mvalue["filename"] . "]]]"
						setlocal modifiable | silent put f | setlocal nomodifiable
					endfor
				else
					for [mkey, mvalue] in items(l:members)
						let @f = "  |  |  |- " . mvalue["name"] . "[[[" . mvalue["cmd"] . "||" . mvalue["filename"] . "]]]"
						setlocal modifiable | silent put f | setlocal nomodifiable
					endfor
				endif
				let @f = "  }}}" " End Members fold
				setlocal modifiable | silent put f | setlocal nomodifiable
			endif
		endif
		if has_key(value, "def")
			let @f = "  --}}}" " End enums fold
			setlocal modifiable | silent put f | setlocal nomodifiable
		endif
	endfor
	let @f = "  --" " End enums fold
	setlocal modifiable | silent put f | setlocal nomodifiable
endfunction " ShowEnums()

function! s:ShowStructs(structdict, line, sort) 
	if empty(a:structdict)
		return
	endif

	let @f = "STRUCTS "
	setlocal modifiable | silent put f | setlocal nomodifiable
	execute "sign place " . line('.') . " line=" . line('.') . " name=VHeading buffer=" . bufnr("")

	for [key, value] in items(a:structdict)
		if key =~ "__anon"
			continue
		endif
		if has_key(value, "def")
			let l:structdef = value["def"]
			if !empty(l:structdef)
				let l:cname = "  |-" . "Struct: " . l:structdef["name"]
				if has_key(l:structdef, "namespace")
					let l:cname = l:cname . " namespace [" . l:structdef["namespace"] . "]"
				endif
				let @f = l:cname . "{{{"
				setlocal modifiable | silent put f | setlocal nomodifiable
			else
				continue
			endif
		else
			continue
		endif
		if has_key(value, "members")
			let l:members = value["members"]
			if !empty(l:members)
				let l:heading = "  |  |-" . "Members : {{{"
				let @f = l:heading
				setlocal modifiable | silent put f | setlocal nomodifiable

				if a:sort
					for [mkey, mvalue] in sort(items(l:members))
						let l:access = "!"
						if mvalue["access"] =~ "^protected$"
							let l:access = "+"
						elseif mvalue["access"] =~ "^public$"
							let l:access = "*"
						endif
						let @f = "  |  |  |- (" . l:access . ") " . mvalue["name"] . "[[[" . mvalue["cmd"] . "||" . mvalue["filename"] . "]]]"
						setlocal modifiable | silent put f | setlocal nomodifiable
					endfor
				else
					for [mkey, mvalue] in items(l:members)
						let l:access = "!"
						if mvalue["access"] =~ "^protected$"
							let l:access = "+"
						elseif mvalue["access"] =~ "^public$"
							let l:access = "*"
						endif
						let @f = "  |  |  |- (" . l:access . ") " . mvalue["name"] . "[[[" . mvalue["cmd"] . "||" . mvalue["filename"] . "]]]"
						setlocal modifiable | silent put f | setlocal nomodifiable
					endfor
				endif
				let @f = "}}}" " End Members fold
				setlocal modifiable | silent put f | setlocal nomodifiable
			endif
		endif
		if has_key(value, "funcp")
			let l:funcp = value["funcp"]
			if !empty(l:funcp)
				let l:heading = "  |  |-" . "Methods : {{{"
				let @f = l:heading
				setlocal modifiable | silent put f | setlocal nomodifiable

				if a:sort
					for [fkey, fvalue] in sort(items(l:funcp))
						let l:access = "!"
						if fvalue["access"] =~ "^protected$"
							let l:access = "+"
						elseif fvalue["access"] =~ "^public$"
							let l:access = "*"
						endif
						let @f =  "  |  |  |- (" . l:access . ") " . fvalue["name"] . fvalue["signature"] . "[[[" . fvalue["cmd"] . "||" . fvalue["filename"] . "]]]"

						setlocal modifiable | silent put f | setlocal nomodifiable
					endfor
				else
					for [fkey, fvalue] in items(l:funcp)
						let l:access = "!"
						if fvalue["access"] =~ "^protected$"
							let l:access = "+"
						elseif fvalue["access"] =~ "^public$"
							let l:access = "*"
						endif
						let @f =  "  |  |  |- (" . l:access . ") " . fvalue["name"] . fvalue["signature"] . "[[[" . fvalue["cmd"] . "||" . fvalue["filename"] . "]]]"

						setlocal modifiable | silent put f | setlocal nomodifiable
					endfor
				endif
				let @f = "  }}}" " End methods fold
				setlocal modifiable | silent put f | setlocal nomodifiable
			endif
		endif
		let @f = "  }}}" " End struct fold
		setlocal modifiable | silent put f | setlocal nomodifiable
	endfor
	let @f = "  --" " End structes fold
	setlocal modifiable | silent put f | setlocal nomodifiable
endfunction " ShowClasses()

function! s:ShowClasses(classdict, line, sort) 
	if empty(a:classdict)
		return
	endif

	let @f = "CLASSES "
	setlocal modifiable | silent put f | setlocal nomodifiable
	execute "sign place " . line('.') . " line=" . line('.') . " name=VHeading buffer=" . bufnr("")

	for [key, value] in items(a:classdict)
		if has_key(value, "def")
			let l:classdef = value["def"]
			if !empty(l:classdef)
				let l:cname = "  |-" . "Class: " . l:classdef["name"]
				if has_key(l:classdef, "namespace")
					let l:cname = l:cname . " namespace [" . l:classdef["namespace"] . "]"
				endif
				if has_key(l:classdef, "inherits")
					let l:cname = l:cname . " inherits [" . l:classdef["inherits"] . "]"
				endif
				let @f = l:cname . "{{{"
				setlocal modifiable | silent put f | setlocal nomodifiable
			else
				continue
			endif
		else
			continue
		endif
		if has_key(value, "members")
			let l:members = value["members"]
			if !empty(l:members)
				let l:heading = "  |  |-" . "Members : {{{"
				let @f = l:heading
				setlocal modifiable | silent put f | setlocal nomodifiable

				if a:sort
					for [mkey, mvalue] in sort(items(l:members))
						let l:access = "!"
						if mvalue["access"] =~ "^protected$"
							let l:access = "+"
						elseif mvalue["access"] =~ "^public$"
							let l:access = "*"
						endif
						let @f = "  |  |  |- (" . l:access . ") " . mvalue["name"] . "[[[" . mvalue["cmd"] . "||" . mvalue["filename"] . "]]]"
						setlocal modifiable | silent put f | setlocal nomodifiable
					endfor
				else
					for [mkey, mvalue] in items(l:members)
						let l:access = "!"
						if mvalue["access"] =~ "^protected$"
							let l:access = "+"
						elseif mvalue["access"] =~ "^public$"
							let l:access = "*"
						endif
						let @f = "  |  |  |- (" . l:access . ") " . mvalue["name"] . "[[[" . mvalue["cmd"] . "||" . mvalue["filename"] . "]]]"
						setlocal modifiable | silent put f | setlocal nomodifiable
					endfor
				endif
				let @f = "  }}}" " End Members fold
				setlocal modifiable | silent put f | setlocal nomodifiable
			endif
		endif
		let l:heading = "  |  |-" . "Methods : {{{"
		let @f = l:heading
		setlocal modifiable | silent put f | setlocal nomodifiable
		if has_key(value, "funcp")
			let l:funcp = value["funcp"]
			if !empty(l:funcp)
				let l:heading = "  |  |  |-" . "Prototypes : {{{"
				let @f = l:heading
				setlocal modifiable | silent put f | setlocal nomodifiable
				if a:sort
					for [fkey, fvalue] in sort(items(l:funcp))
						let l:access = "!"
						if fvalue["access"] =~ "^protected$"
							let l:access = "+"
						elseif fvalue["access"] =~ "^public$"
							let l:access = "*"
						endif
						let @f =  "  |  |  |- (" . l:access . ") " . fvalue["name"] . fvalue["signature"] . "[[[" . fvalue["cmd"] . "||" . fvalue["filename"] . "]]]"
						setlocal modifiable | silent put f | setlocal nomodifiable
					endfor
				else
					for [fkey, fvalue] in items(l:funcp)
						let l:access = "!"
						if fvalue["access"] =~ "^protected$"
							let l:access = "+"
						elseif fvalue["access"] =~ "^public$"
							let l:access = "*"
						endif
						let @f =  "  |  |  |- (" . l:access . ") " . fvalue["name"] . fvalue["signature"] . "[[[" . fvalue["cmd"] . "||" . fvalue["filename"] . "]]]"
						setlocal modifiable | silent put f | setlocal nomodifiable
					endfor
				endif
				let @f = "  }}}" " End Prototypes fold
				setlocal modifiable | silent put f | setlocal nomodifiable
			endif
		endif
		if has_key(value, "funcd")
			let l:funcd = value["funcd"]
			if !empty(l:funcd)
				let l:heading = "  |  |  |-" . "Definitions : {{{"
				let @f = l:heading
				setlocal modifiable | silent put f | setlocal nomodifiable
				if a:sort
					for [fkey, fvalue] in sort(items(l:funcd))
						let l:access = "?"
						let @f =  "  |  |  |- (" . l:access . ") " . fvalue["name"] . fvalue["signature"] . "[[[" . fvalue["cmd"] . "||" . fvalue["filename"] . "]]]"
						setlocal modifiable | silent put f | setlocal nomodifiable
					endfor
				else
					for [fkey, fvalue] in items(l:funcd)
						let l:access = "?"
						let @f =  "  |  |  |- (" . l:access . ") " . fvalue["name"] . fvalue["signature"] . "[[[" . fvalue["cmd"] . "||" . fvalue["filename"] .  "]]]"
						setlocal modifiable | silent put f | setlocal nomodifiable
					endfor
				endif
				let @f = "  }}}" " End Definitions fold
				setlocal modifiable | silent put f | setlocal nomodifiable
			endif
		endif
		let @f = "  }}}" " End methods fold
		setlocal modifiable | silent put f | setlocal nomodifiable
		let @f = "  }}}" " End class fold
		setlocal modifiable | silent put f | setlocal nomodifiable
	endfor
	let @f = "  --" " End classes fold
	setlocal modifiable | silent put f | setlocal nomodifiable
endfunction " ShowClasses()

"" Determine the number of windows open to this buffer number.
"" Care of Yegappan Lakshman.  Thanks!
fun! s:BufInWindows(bnum) " <<<
	let cnt = 0
	let winnum = 1
	while 1
		let bufnum = winbufnr(winnum)
		if bufnum < 0
			break
		endif
		if bufnum == a:bnum
			let cnt = cnt + 1
		endif
		let winnum = winnum + 1
	endwhile

	return cnt
endfunction " >>>


let &cpo = s:cpo_save
function! vimper#project#classexplorer#LoadBrowser()
	if !exists("g:vimperShowClassBrowser") || g:vimperShowClassBrowser == 0
		return
	endif


	if !exists("g:vimperProjectType") || empty(g:vimperProjectType)
		return
	endif  

	if !exists("g:vimperProjectRoot") || empty(g:vimperProjectRoot)
		return
	endif  
	
	let l:filename = vimper#project#common#WinConvertPath(expand ("%:p"))
	if vimper#Utils#IsLockedBuffer(l:filename)
		return
	endif

	let l:bufname = vimper#Utils#GetTabbedBufferName('ClassExplorer')
	call  vimper#Utils#ClearBuffer(l:bufname)

	let l:extlist = []
	if has_key(g:_SUPPORTED_EXTS, g:vimperProjectType)
		let l:exts =  g:_SUPPORTED_EXTS[g:vimperProjectType]
		let l:extlist = split(l:exts, "|")
	endif
	if empty(l:extlist)
		return
	endif
	let l:ext = expand("%:e")
	if empty(l:ext)
		return
	endif
	let l:extfound = 0
	for l:extn in l:extlist
		if l:ext == l:extn
			let l:extfound = 1
			break
		endif
	endfor
	if !l:extfound
		return
	endif
	let l:retval = s:OpenBrowser()

	if l:retval == 0

		if !empty(l:filename)
			call s:InitWithFile(l:filename, g:vimperProjectRoot)
		endif
	endif
endfunction "LoadBrowser()

function! s:OpenBrowser()
	let l:bufname = vimper#Utils#GetTabbedBufferName('ClassExplorer')
	let g:vimperShowClassBrowser = 1

	if !exists("g:vimperProjectType") || empty(g:vimperProjectType)
		return
	endif  

	if !exists("g:vimperProjectRoot") || empty(g:vimperProjectRoot)
		return
	endif  
	
	let l:filename = vimper#project#common#WinConvertPath(expand ("%:p"))
	let wSize = 40
	if exists("g:vimperExplorerWidth") && g:vimperExplorerWidth
		let wSize = g:vimperExplorerWidth
	endif
	let win_dir = 'botright vertical'

	" If the tag listing temporary buffer already exists, then reuse it.
	" Otherwise create a new buffer
	let bufnum = vimper#Utils#CheckBufferExists(l:bufname)
	let wcmd = l:bufname
	if bufnum != -1
		let l:retval = vimper#Utils#GotoWindow(l:bufname)
		if l:retval == 1
			return 0
		else
			let wcmd = '+buffer' . bufnum
		endif
	endif
	let win_dir = 'botright vertical'

	exe 'silent! ' . win_dir . ' ' . wSize . 'split ' . wcmd

	setlocal nonumber

	call vimper#Utils#AddLockedBuffer(l:bufname)    
	call s:InitWithFile(l:filename, g:vimperProjectRoot)

	autocmd BufWinEnter * call vimper#project#classexplorer#LoadBrowser()

	return 1
endfunction " s:OpenBrowser()
" vim: set ts=2 sw=2 foldmethod=marker foldmarker=<<<,>>> foldlevel=2 :
