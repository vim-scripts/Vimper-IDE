"" File: Utils.vim
"" Description: Functions to generate project related make files
""		and configurations.
"" Version: 1.0
"" Author: ghoshs (subhagho@msn.com)
"" Namespace: vimper#project


"" FindFile() -           Returns a list of files matching the exprn
"                         under the directory specified.
"                         To ignore files specify the filter. All files 
"                         matching the filter will be ignored. The filter
"                         can be any valid regex.
" Args :
"                         --> exprn - expression or name to search for
"                         --> directory - Directory under which to search
"                         --> filter - additional filters can be specified
" Return                  --> List of files
function! vimper#project#Utils#FindFile(exprn, directory, filter)
        let l:list=system("find " .a:directory. " -type f -name '".a:exprn."'")

        let array = []
        let oarray = split(l:list, "\n")
        if empty(oarray)
                return array
        endif

        for l:line in oarray
                if !empty(a:filter)
                        if l:line =~ a:filter
                                continue
                        endif
                endif
                call add(array, l:line)
        endfor
        return array
endfunction " FindFile()

"" FindDir() -            Reutrns list of directories matching the exprn
"                         under the specified directory.
"                         To ignore directories specify the filter. All 
"                         directories matching the filter will be ignored. The filter
"                         can be any valid regex.
" Args :
"                         --> exprn - expression or name to search for
"                         --> directory - Directory under which to search
"                         --> filter - additional filters can be specified
" Return                  --> List of directories
function! vimper#project#Utils#FindDir(exprn, directory, filter)
        let l:list=system("find ".a:directory. " -type d -name '".a:exprn."'")

        let array = []
        let oarray = split(l:list, "\n")
        if empty(oarray)
                return array
        endif

        for l:line in oarray
                if !empty(a:filter)
                        if l:line =~ a:filter
                                continue
                        endif
                endif
                call add(array, l:line)
        endfor
        return array
endfunction " FindDir()

"" ListDirectories() -     Return a list of directories under the parent.
"                         To ignore directories specify the filter. All 
"                         directories matching the filter will be ignored. The filter
"                         can be any valid regex.
"                         Note: Do not use relative paths in the parent
"                         parameter. Only exception is "." or "./". If empty
"                         current directory is assumed.
" Args :
"                         --> parent - Directory under which to search
"                         --> filter - additional filters can be specified
"                         --> prefix - if 1 return the complete path else
"                         return only the directory names
"                         --> flags - Extra flags to be specified for listing.
"                             1. "a" - list .*
" Return                  --> List of directories
function! vimper#project#Utils#ListDirectories(parent, filter, prefix, flags)
        if a:parent == "" || a:parent == "." || a:parent == "./"
                let l:parent = getcwd()
        else
                let l:parent = a:parent
        endif

        let CWD = getcwd()

        execute "lcd " . l:parent

        let l:list = expand(l:parent . "/*")

        if a:flags =~ "a"
                let l:list = l:list . "\n" . expand(l:parent . "/.*")
        endif

        let array = []
        let oarray = split(l:list, "\n")
        if empty(oarray)
                return array
        endif

        for l:line in oarray
                let l:type = getftype(l:line)

                if empty(l:type) || l:type != "dir"
                        continue
                endif

                if !empty(a:filter)
                        if l:line =~ a:filter
                                continue
                        endif
                endif

                let l:fl = vimper#project#common#WinConvertPath(l:line)
                if a:prefix == 0
                        let l:fl = substitute(l:fl, '^'.l:parent, '', '')
                        let l:fl = substitute(l:fl, '/', '', 'g')
                endif

                call add(array, l:fl)
        endfor

        execute "lcd " . CWD
        return array
endfunction " ListDirectories()

"" ListFiles() -          Return a list of files under the parent.
"                         To ignore files specify the filter. All 
"                         files matching the filter will be ignored. The filter
"                         can be any valid regex.
"                         Note: Do not use relative paths in the parent
"                         parameter. Only exception is "." or "./". If empty
"                         current directory is assumed.
" Args :
"                         --> parent - Directory under which to search
"                         --> filter - additional filters can be specified
"                         --> prefix - if 1 return the complete path else
"                         return only the file names
"                         --> flags - Extra flags to be specified for listing.
"                             1. "a" - list .*
" Return                  --> List of files
function! vimper#project#Utils#ListFiles(parent, filter, prefix, flags)
        if a:parent == "" || a:parent == "." || a:parent == "./"
                let l:parent = getcwd()
        else
                let l:parent = a:parent
        endif

        let CWD = getcwd()

        execute "lcd " . l:parent

        let l:list = expand(l:parent . "/*")

        if a:flags =~ "a"
                let l:list = l:list . "\n" . expand(l:parent . "/.*")
        endif

        let array = []
        let oarray = split(l:list, "\n")
        if empty(oarray)
                return array
        endif

        for l:line in oarray
                let l:type = getftype(l:line)

                if empty(l:type) || l:type != "file"
                        continue
                endif

                if !empty(a:filter)
                        if l:line =~ a:filter
                                continue
                        endif
                endif

                let l:fl = vimper#project#common#WinConvertPath(l:line)
                if a:prefix == 0
                        let l:fl = substitute(l:fl, '^'.l:parent, '', '')
                        let l:fl = substitute(l:fl, '/', '', 'g')
                endif
                call add(array, l:fl)
        endfor

        execute "lcd " . CWD
        return array
endfunction " ListFiles()

"" GetParentDirectory() - Get the parent directory, return "" if root. 
"  Args :               --> dir - Directory to get the parent of
"  Return               --> Parent directory or "" if root
function! vimper#project#Utils#GetParentDirectory(dir)  
        if empty(a:dir)
                return ""
        endif
        let dir = a:dir
        if dir =~ '^[A-Z]:' 
                let is_root = (dir =~ '^[A-Z]:/$') ? 1 : 0
                if !is_root
                        let dir = substitute (dir, '/$', "", "")
                endif
        elseif dir =~ '^/'
                let is_root = (dir == "/") ? 1 : 0
                if !is_root
                        let dir = substitute (dir, '/$', "", "")
                endif
        else
                return ""
        endif

        if is_root == 1
                return ""
        endif

        let dir = substitute (dir, '[^/]*$', "", "")
        return dir
endfunction " GetParentDirectory()

"" DirectoryExists()    - Check if the directory exists in parent
"                       Note: Do not use relative paths when specifying the
"                       parent directory.
"  Args :
"       parent          --> Parent directory to search under
"       dir             --> Directory to search for
"  Return :             --> bool,exists = 1, not found = 0 
function! vimper#project#Utils#DirectoryExists(parent, dir)
        let l:dirs = vimper#project#Utils#ListDirectories(a:parent, "", 0, "a")
        if !empty(l:dirs)
                for dir in l:dirs
                        let dir = substitute(dir, ' ', '\\ ', 'g')
                        if match(dir, a:dir) == 0
                                return 1
                        endif
                endfor
        endif
        return 0
endfunction " DirectoryExists()
"" GetFileName()      - Get the filename from the file path specified.
"  Args :
"       path            --> Parent directory to search under
"  Return :             --> Filename or "" if directory
function! vimper#project#Utils#GetFileName(path)
        let l:path = a:path
        if has('win32')
                let l:path = vimper#project#common#WinConvertPath(a:path)
        endif
        let l:type = getftype(l:path)
        if l:type != "file"
                return ""
        endif

        let l:mt = matchlist(l:path, "[^/]*$")
        if empty(l:mt)
                return ""
        endif
        if empty(l:mt[0])
                return ""
        endif
        return l:mt[0]
endfunction " GetFileName()

function! vimper#project#Utils#GetExtension(path)
	let fname = a:path
	if fname =~ "/"
		let fname = vimper#project#Utils#GetFileName(a:path)
	endif

	if empty(fname)
		return ""
	endif
	let expts = split(fname, "\\.")
	if empty(expts)
		return ""
	endif
	let pindx = len(expts) - 1
	if pindx < 0
		return ""
	endif
	let ext = expts[pindx]
	
	return ext
endfunction " GetExtension()
