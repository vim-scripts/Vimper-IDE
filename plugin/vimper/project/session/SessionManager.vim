"" File: SessionManager.vim
"" Description: Functions for project session related functions
""		and configurations.
"" Version: 1.0
"" Author: ghoshs (subhagho@msn.com)
"" Namespace: vimper#project#session#SessionManager

function! vimper#project#session#SessionManager#Load(rootdir)
	let sessf = a:rootdir . "/.session"
	if !filereadable(sessf)
		let olines = []	
		add(olines, "\#\n")
		add(olines, "\# Vimper Session History...\n")
		add(olines, "\#\n")
		call writefile(olines, sessf)
	endif
	let inlines = readfile(sessf)
	if empty(inlines)
		return 
	endif
	let ofiles = []
	for line in inlines
		if empty(line) || line =~ "^#"
			continue
		endif
		call add(ofiles, line)
	endfor
	if empty(ofiles)
		return
	endif
	for ofile in ofiles
		if filereadable(ofile)
			call vimper#Utils#OpenInWindow(ofile)
		endif
	endfor
endfunction " Load()

function! vimper#project#session#SessionManager#AddFile(rootdir, path)
	let sessf = a:rootdir . "/.session"
	if !filereadable(sessf)
		let olines = []	
		add(olines, "\#\n")
		add(olines, "\# Vimper Session History...\n")
		add(olines, "\#\n")
		call writefile(olines, sessf)
	endif
	let inlines = readfile(sessf)
	for line in inlines
		if empty(line) || line =~ "^#"
			continue
		endif
		if line =~ a:path
			return
		endif
	endfor
	call add(inlines, a:path)
	call writefile(inlines, sessf)
endfunction " AddFile()

function! vimper#project#session#SessionManager#RemoveFile(rootdir, path)
	if !filereadable(a:path)
		return
	endif

	let sessf = a:rootdir . "/.session"
	if !filereadable(sessf)
		return
	endif
	let inlines = readfile(sessf)
	let olines = []
	for line in inlines
		if line =~ a:path
			continue
		endif
		call add(olines, line)
	endfor
	call writefile(olines, sessf)
endfunction
