"" File: project.vim
"" Description: Functions to generate project related make files
""		and configurations.
"" Version: 1.0
"" Author: ghoshs (subhagho@msn.com)
"" Namespace: vimper#project#vcpp

"" Build() -            Build the current C/C++ project
"  Args :
"  	proj_root     --> Project root directory.
"  Return :		--> bool, sucess = 1, failure = 0
function! vimper#project#vcpp#functions#Build(proj_root)
  let l:filename = vimper#Utils#GetTabbedBufferName('make')
  let l:file = vimper#project#common#ConvertPath(expand('$VIMPER_HOME') . '/scripts')
  let l:efile = vimper#project#common#ConvertPath(expand('$TEMP') . "/" . l:filename) . '.makerr'

  let makecmd =  "!cd ". vimper#project#common#ConvertPath(a:proj_root) . "&& make 2\>\&1 \| " .l:file. "/cygwin.pl 2\>\&1 > " .  l:efile
  call system( makecmd )

  if has('win32')
    let l:efile =  vimper#project#common#WinConvertPath(l:efile)
  endif 
  if filereadable(l:efile)
    " Move the cursor out of the explorer window 
    execute "wincmd l" 
    call vimper#project#vcpp#error_buffer#Build(l:efile, "cpp")
    call vimper#Utils#AddLockedBuffer(l:efile)
  endif

endfunction " Build()
"" CreateNewProject() - Create a new project and include all sub-directories
"                       under the project root containing source files into the project.
"  Args :
"  	proj_name     --> Project name.
"  	proj_root     --> Project root directory.
"  Return :		--> bool, sucess = 1, failure = 0
function! vimper#project#vcpp#functions#CreateNewProject(proj_name, proj_root)
  call vimper#project#vcpp#functions#CreateVimStartup(a:proj_root)
  return 1
endfunction " CreateNewProject()


"" IsVCppType() - 	Check if the current project root contains a C++
"                       project definition.
"  Args :
"  	proj_root`	--> Project Root directory
"  Return :		--> bool, sucess = 1, failure = 0
function! vimper#project#vcpp#functions#IsVCppType(proj_root)
  let CWD = getcwd()

  let retval = 0

  execute "lcd " . a:proj_root

  if filereadable("./.vimproj")
    
    let p_lines = readfile(a:proj_root . "./.vimproj")
    if empty(p_lines)
      throw "Invalid project definition file " . a:proj_root . "/.vimproj. Contains no data."
    endif

    let p_type = ""
    for line in p_lines
      let mt = matchlist(line, '^let g\:vimperProjectType\s*=\s*\(\S\+\)')

      if !empty(mt)
        let p_type = mt[1]
        break
      endif
    endfor

    if p_type == "\"vcpp\""
      let retval = 1
    endif
  endif
  execute "lcd " . CWD
  return retval
endfunction " IsVCppType()


"" CheckIsProjectOrPart() - Check if the current forlder is part of a project.
"  Args :                 --> dir - Directory to validate
"  Return                 --> 1 - if part of project, 0 - otherwise
function! vimper#project#vcpp#functions#CheckIsProjectOrPart(dir) " <<<
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
          let retval = vimper#project#vcpp#functions#IsVCppType(dir)          
          return retval
        endif

        if retval != 1
	  let dir = vimper#project#Utils#GetParentDirectory(dir)
	  let retval = vimper#project#vcpp#functions#CheckIsProjectOrPart(dir)
        endif
        return retval
endfunction ">>> CheckIsProjectOrPart()


"" RemoveFromProject()    - Remove the directory from the current project
"  Args :                 --> root - Project Root directory
"                         --> dir - Directory to delete
"  Return                 --> 1 - if part of project, 0 - otherwise
function! vimper#project#vcpp#functions#RemoveFromProject(root, dir) " <<<
 
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
function! vimper#project#vcpp#functions#CreateVimStartup(proj_root)
 
  let proj_root = a:proj_root
  let src_home = expand('$VIMPER_HOME') . '/scripts/vcpp/'

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
