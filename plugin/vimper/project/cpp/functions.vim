"" File: project.vim
"" Description: Functions to generate project related make files
""		and configurations.
"" Version: 1.0
"" Author: ghoshs (subhagho@msn.com)
"" Namespace: vimper#project#cpp

"" Build() -            Build the current C/C++ project
"  Args :
"  	proj_root     --> Project root directory.
"  Return :		--> bool, sucess = 1, failure = 0
function! vimper#project#cpp#functions#Build(proj_root)
	let l:filename = vimper#Utils#GetTabbedBufferName('make')
	let l:file = vimper#project#common#ConvertPath(expand('$VIMPER_HOME') . '/scripts')
	let l:efile = vimper#project#common#ConvertPath(expand('$TEMP') . "/" . l:filename) . '.makerr'

	let makecmd =  "cd ". vimper#project#common#ConvertPath(a:proj_root) . "&& make 2\>\&1 \| tee " .  l:efile

	if has('win32')
		let makecmd =  "!cd ". vimper#project#common#ConvertPath(a:proj_root) . "&& make 2\>\&1 \| " .l:file. "/cygwin.pl 2\>\&1 \|tee " .  l:efile
	endif

	call system( makecmd )

	if has('win32')
		let l:efile =  vimper#project#common#WinConvertPath(l:efile)
	endif 
	if filereadable(l:efile)
		" Move the cursor out of the explorer window 
		execute "wincmd l" 
		call vimper#project#cpp#error_buffer#Build(l:efile, "cpp")
		call vimper#Utils#AddLockedBuffer(l:efile)
	endif

endfunction " Build()
"" CreateNewProject() - Create a new project and include all sub-directories
"                       under the project root containing source files into the project.
"  Args :
"  	proj_name     --> Project name.
"  	proj_root     --> Project root directory.
"  Return :		--> bool, sucess = 1, failure = 0
function! vimper#project#cpp#functions#CreateNewProject(proj_name, proj_root)
	" Get the project build directory
	let proj_output = input ("Enter Project Output Directory [".a:proj_root."/build] :")
	if empty(proj_output)
		let proj_output = a:proj_root . "/build"
	endif
	" Get the build architecture
	let build_arch = input ("Enter Platform Architecture (x86|amd64|...): ")

	" Get project build target
	let build_target = input ("Enter Build Target [exe|lib]:")

	if !empty(build_arch)
		let arch = build_arch
	else
		if has('win32')
			let proc = expand('$PROCESSOR_ARCHITEW6432')
			if proc != ""
				let arch = proc
			endif
		else
			" TODO: Find out what is the env variable for other platforms
			let arch = 'UNKNOWN'
		endif
	endif

	" print configuration parameters
	echo "Project Name:     " . a:proj_name
	echo "Project Root:     " . a:proj_root
	echo "Output Directory: " . proj_output
	echo "Project Type:     " . "cpp"
	echo "Build Arch.:      " . arch

	let extn = s:GetProjectExtn(build_target)
	try 
		execute "lcd " . a:proj_root 
		" Check if directory already contains a project definition
		if filereadable("./Makefile") && filereadable("./project.mk")
			let resp = input("Directory " . a:proj_root . " already contains a project definition. Overwrite? (y/n) :")
			if resp != 'y'
				return 0
			endif
		endif
		call s:CleanUpExistingMakes(a:proj_root)
		call s:SetupProjectFiles(a:proj_root, a:proj_name, proj_output, arch, extn)
		call s:CreateSubdirs(a:proj_root, a:proj_root)
		call vimper#project#cpp#functions#CreateVimStartup(a:proj_root)
	catch /.*/
		echo " CreateNewProject() : ERROR : " . v:exception
		return 0
	endtry
	return 1
endfunction " CreateNewProject()

function! s:GetProjectExtn(extn)
	if a:extn =~ "^lib"
		return ".a"
	else
		if has('win32')
			return ".exe"
		endif
	endif
	return ""
endfunction " GetProjectExtn()

function! s:SetupProjectFiles(proj_root, proj_name, proj_outdir, arch, extn)
	let make_home = expand('$VIMPER_HOME') . '/make/cpp/'

	" Copy the template file to the project root
	let copycmd = "cp " . vimper#project#common#ConvertPath(make_home) . "/global.mk " . vimper#project#common#ConvertPath(a:proj_root) . "/Makefile"
	call system(copycmd)

	if !filereadable(make_home . "project.mk")
		throw "Cannot read file " . make_home . "project.mk"
	endif

	let ilines = readfile(make_home . "project.mk")
	if empty(ilines)
		throw "Invalid project template file " . make_home . "project.mk"
	endif

	let olines = []

	let rootdir = vimper#project#common#ConvertPath(a:proj_root)
	let outdir = vimper#project#common#ConvertPath(a:proj_outdir)

	for line in ilines
		let line = substitute(line, "<PROJECT_NAME>", a:proj_name, "")  
		let line = substitute(line, "<PROJECT_ROOT>", rootdir, "")
		let line = substitute(line, "<PROJECT_OUTPUT_DIR>", outdir, "")
		let line = substitute(line, "<PROJECT_BUILD_OUTPUT>", outdir . "/" . a:proj_name . "." . a:extn, "")
		let line = substitute(line, "<PROJECT_TYPE>", "cpp", "")
		let line = substitute(line, "<ARCH>", a:arch,"")
		let line = substitute(line, "<EXTN>", a:extn,"")

		call add(olines, line)
	endfor

	call writefile(olines, "./project.mk")
endfunction " SetupProjectFiles()

function! s:CreateSubdirs(proj_root, dirname)
	call vimper#project#cpp#functions#CreateSubdir(a:proj_root, a:dirname, 1)
	let dirs = vimper#project#Utils#ListDirectories(a:dirname, "", 1, "")
	if !empty(dirs)
		for dir in dirs
			call s:CreateSubdirs(a:proj_root, dir)
		endfor
	endif
endfunction " CreateSubdirs()

"" CleanUpExistingMakes() - Remove any existing makefiles from the project
"                           root.
" Args :
"                         --> proj_root - Project Root directory
" Return                  --> 1 - Success, 0 - Failure
function! s:CleanUpExistingMakes(proj_root)

	let CWD = getcwd()

	execute "lcd " . a:proj_root

	if filereadable("./Makefile") 
		call delete("./Makefile")
	endif

	if filereadable("./project.mk")
		call delete("./project.mk")
	endif

	let flist = vimper#project#Utils#FindFile('subdir.mk', a:proj_root, '')
	if !empty(flist)
		for mfile in flist
			if !empty(mfile) && filereadable(mfile)
				call delete(mfile)
			endif
		endfor
	endif

	execute "lcd " . CWD
	return 1
endfunction " CleanUpExistingMakes()

"" CreateSubdir() - 	Create the project subdirectory and the subdir.mk
"			makefile and adds the directory to the project
"			Makefile.
"  Args :
"  	proj_root     --> Project root directory.
"  	dirname	--> Directory to create.
"  	check_exists	--> bool, check if directory contains sources (used
"  			when importing project)
"  Return :		--> bool, sucess = 1, failure = 0
function! vimper#project#cpp#functions#CreateSubdir(proj_root, dirname, check_exists) 
	let CWD = getcwd()
	if !filereadable(a:proj_root . "./project.mk")
		echo "Cannot find project definition file " . a:proj_root . "/project.mk."
		return 0
	endif

	try
		let p_lines = readfile(a:proj_root . "./project.mk")
		if empty(p_lines)
			throw "Invalid project definition file " . a:proj_root . "/project.mk. Contains no data."
		endif

		let retval = s:CreateSubdirMk(a:dirname, a:check_exists)

		if retval == 0
			throw "Error creating sub-directory makefile."
		elseif retval == 2
			return 1
		endif

		if !s:UpdateProjectMk(a:proj_root, a:dirname)
			throw "Error update project makefile."
		endif
	catch /.*/
		throw "Error : " . v:exception
	finally
		execute "lcd " . CWD
	endtry

	return 1
endfunction " CreateSubdir()

"" UpdateProjectMk() - 	Update the project Makefile to include the new
"                       subdirectory.
"  Args :
"  	proj_root     --> Project root directory.
"  	dirname	--> New directory path.
"  Return :		--> bool, sucess = 1, failure = 0
function! s:UpdateProjectMk(proj_root, dirname) 
	let f_orig = a:proj_root . '/Makefile'
	if !filereadable(f_orig)
		echo "Cannot open file " . f_orig
		return 0
	endif

	let p_lines = readfile(f_orig)
	if empty(p_lines)
		echo "Invalid project Makefile : file empty"
		return 0
	endif

	try 
		let t_dirname = vimper#project#common#ConvertPath(a:dirname)
		let t_dirname = substitute(t_dirname, '/$', '', '')
		let t_dirname = substitute(t_dirname, '//', '/', '')
		let t_dirname = substitute(t_dirname, '^' . vimper#project#common#ConvertPath(a:proj_root), './', '')
		let o_lines = []
		let b_openTag = 0

		for line in p_lines
			if line =~ '^\#\s*_START_SUBDIR_MAKES'
				let b_openTag = 1
			elseif b_openTag == 1
				let exprn = '^SUBDIRS\s*+=\s*' . t_dirname . '\s*$'
				let mt = matchlist(line, exprn)
				if !empty(mt)
					if line =~ "^\#"
						b_openTag = 1
					else 
						let b_openTag = 0
						echo "Makefile already contains entry for " . t_dirname  
					endif
				elseif line =~ '^\#\s*_END_SUBDIR_MAKES'
					call add(o_lines,  "SUBDIRS += " . t_dirname)      
					let b_openTag = 0
				endif
			endif
			call add(o_lines, line)
		endfor

		let f_new = a:proj_root . "/Makefile.new"
		call writefile(o_lines, f_new)

		call delete(f_orig)
		call rename(f_new, f_orig)
	catch /.*/
		throw "UpdateProjectMk() : " . v:exception
	endtry
	return 1
endfunction " UpdateProjectMk()

"" CreateSubdirMk() - 	Create the project subdirectory and the subdir.mk
"			makefile .
"  Args :
"  	dirname	--> Directory to create.
"  	type		--> Type of makefile (cpp, java, etc.)
"  	check_exists	--> bool, check if directory contains sources (used
"  			when importing project)
"  Return :		--> bool, sucess = 1, failure = 0
function! s:CreateSubdirMk(dirname, check_exists) 
	try
		if a:check_exists == 1 " Check if sub-directory contains any source files.
			let b_retval = 	 vimper#project#common#CheckSourceExists(a:dirname, "cpp")
			if b_retval == 0
				return 2
			endif
		endif
		execute "lcd " . a:dirname
		let submake = a:dirname . "/subdir.mk"
		let template = expand('$VIMPER_HOME') . '/make/cpp/template.subdir.mk'
		if !filereadable(template)
			throw "Cannot find make template file " . template . "."
		endif

		let in_lines = readfile(template)
		if empty(in_lines)
			throw "Invalid template file " . template . ", contains no data."
		endif

		let t_dirname =  vimper#project#common#ConvertPath(a:dirname)
		let t_dirname = substitute(t_dirname, '//', '/', '')
		let out_lines = []
		for line in in_lines
			let line = substitute(line, '<SUBDIRPATH>', t_dirname, "")
			call add(out_lines, line)
		endfor

		call writefile(out_lines, submake)
	catch /.*/
		throw "CreateSubdirMk() : " . v:exception
	endtry
	return 1
endfunction " CreateSubdirMk()


"" IsCppType() - 	Check if the current project root contains a C++
"                       project definition.
"  Args :
"  	proj_root`	--> Project Root directory
"  Return :		--> bool, sucess = 1, failure = 0
function! vimper#project#cpp#functions#IsCppType(proj_root)
	let CWD = getcwd()

	let retval = 0

	execute "lcd " . a:proj_root

	if filereadable("./Makefile") && filereadable("./project.mk")

		let p_lines = readfile(a:proj_root . "./project.mk")
		if empty(p_lines)
			throw "Invalid project definition file " . a:proj_root . "/project.mk. Contains no data."
		endif

		let p_type = ""
		for line in p_lines
			let mt = matchlist(line, '^PROJECT_TYPE\s*\:=\s*\(\S\+\)')

			if !empty(mt)
				let p_type = mt[1]
				break
			endif
		endfor

		if p_type == "cpp"
			let retval = 1
		endif
	endif
	execute "lcd " . CWD
	return retval
endfunction " IsCppType()


"" CheckIsProjectOrPart() - Check if the current forlder is part of a project.
"  Args :                 --> dir - Directory to validate
"  Return                 --> 1 - if part of project, 0 - otherwise
function! vimper#project#cpp#functions#CheckIsProjectOrPart(dir) " <<<
	let dir = a:dir
	if empty(dir)
		return 0
	endif

	if has('win32')
		let dir = vimper#project#common#WinConvertPath(dir)
	endif

	let retval = 0
	if filereadable(dir . "/Makefile") && filereadable(dir . "/project.mk")	
		let g:vimperProjectRoot = dir
		let retval = 1
	endif

	if retval == 1
		let retval = vimper#project#cpp#functions#IsCppType(dir)          
		return retval
	endif

	if retval != 1
		let dir = vimper#project#Utils#GetParentDirectory(dir)
		let retval = vimper#project#cpp#functions#CheckIsProjectOrPart(dir)
	endif
	return retval
endfunction ">>> CheckIsProjectOrPart()


"" RemoveFromProject()    - Remove the directory from the current project
"  Args :                 --> root - Project Root directory
"                         --> dir - Directory to delete
"  Return                 --> 1 - if part of project, 0 - otherwise
function! vimper#project#cpp#functions#RemoveFromProject(root, dir) " <<<

	let CWD = getcwd()

	execute "lcd " . a:root

	let f_orig = a:root . '/Makefile'
	if !filereadable(f_orig)
		echo "Cannot open file " . f_orig
		return 0
	endif

	let p_lines = readfile(f_orig)
	if empty(p_lines)
		echo "Invalid project Makefile : file empty"
		return 0
	endif

	try 
		let t_dirname = vimper#project#common#ConvertPath(a:dir)
		let t_dirname = substitute(t_dirname, '^' . vimper#project#common#ConvertPath(a:root), './', '')
		let t_dirname = substitute(t_dirname, '/$', '', '')
		let o_lines = []
		let b_openTag = 0

		for line in p_lines
			if line =~ '^\#\s*_START_SUBDIR_MAKES'
				let b_openTag = 1
			elseif b_openTag == 1
				let exprn = '^SUBDIRS\s*+=\s*' . t_dirname . '\s*$'
				let mt = matchlist(line, exprn)
				if line =~  '^SUBDIRS\s*+=\s*' . t_dirname . '\(\/\|\s*$\)'
					if line =~ "^\#"
						b_openTag = 1
					else 
						continue
					endif
				elseif line =~ '^\#\s*_END_SUBDIR_MAKES'
					let b_openTag = 0
				endif
			endif
			call add(o_lines, line)
		endfor

		let f_new = a:root . "/Makefile.new"
		call writefile(o_lines, f_new)

		call delete(f_orig)
		call rename(f_new, f_orig)
	catch /.*/
		throw "RemoveFromProject() : " . v:exception
	endtry
	execute "lcd " . CWD
	return 1
endfunction " RemoveFromProject()

"" CreateVimStartup() -         Creates the Vim script to be sourced
"                               during project load.
"  Args : 
"       proj_root               --> Project Root directory
function! vimper#project#cpp#functions#CreateVimStartup(proj_root)

	let proj_root = a:proj_root
	let src_home = expand('$VIMPER_HOME') . '/scripts/cpp/'

	if has('win32')
		let proj_root = vimper#project#common#WinConvertPath(proj_root)
		let src_home =  vimper#project#common#WinConvertPath(src_home)
	endif

	if !filereadable(src_home . "/template.vimper.vim")
		throw "Cannot open template file " . src_home . "/template.vimper.vim"
	endif

	let vfile = proj_root . "/.vimproj"
	if has('win32')
		let vfile = vimper#project#common#WinConvertPath(vfile)
	endif
	if filereadable(vfile)
		call delete(vfile)
	endif

	let ilines = readfile(src_home . "/template.vimper.vim")
	if empty(ilines)
		throw "Error reading " . src_home . "/template.vimper.vim, file is empty."
	endif

	let olines = []
	for line in ilines
		let nline = substitute(line, "<PROJ_HOME>", '"' . proj_root . '"', "")
		let nline = substitute(nline, "<TAG_DIR>", proj_root, "")
		let nline = substitute(nline, "\/\/", "\/", "")
		call add(olines, nline)
	endfor

	call writefile(olines, vfile)
endfunction " CreateVimStartup()

function! vimper#project#cpp#functions#IsTagFileValid(fsrc, root)
	let result = 0
	let gentag = 1
	let dbfilename = vimper#project#cpp#functions#GetTagFileBySource(a:fsrc, a:root)
	if filereadable(dbfilename)
		let fstime = getftime(a:fsrc)
		let fttime = getftime(dbfilename)
		if fstime < fttime
			let gentag = 0
		endif
	endif
	if gentag == 1
		"let cmd = ':silent !ctags -f ' . dbfilename . ' --c++-kinds=+pl --fields=+iaS --extra=+q --sort=yes ' . a:fsrc
		let dir = vimper#project#Utils#GetParentDirectory(a:fsrc)
		let fname = vimper#project#Utils#GetFileName(a:fsrc)
		let cmd = ":silent !" . expand('$VIMPER_HOME') . "/scripts/ctags.sh -f " . dir . " " . dbfilename . " " .  a:root . " " . fname
		execute cmd
	endif
	if filereadable(dbfilename)
		let result = 1
		let ctagsfile = a:root . "/.tags/current.tag"
		let cpcmd = ":silent !cp -f " . dbfilename . " " . ctagsfile
		execute cpcmd
	endif
	return result
endfunc " IsTagFileValid()

function! vimper#project#cpp#functions#GetTagFileBySource(fsrc, root)
	let tagsdir = a:root . "/.tags/"
	if has('win32')
		let tagsdir =  vimper#project#common#WinConvertPath(tagsdir)
	endif
	let tagsdbdir = tagsdir . "/db/"
	if has('win32')
		let tagsdbdir =  vimper#project#common#WinConvertPath(tagsdbdir)
	endif

	if vimper#project#Utils#DirectoryExists(tagsdir, "db") == 0
		call mkdir(tagsdbdir)
	endif

	let srcfname = vimper#project#Utils#GetFileName(a:fsrc)
	let dbfilename = tagsdbdir . "/" . srcfname . ".tag"

	return dbfilename
endfunc " GetTagFileBySource()


