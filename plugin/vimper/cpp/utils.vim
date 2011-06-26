" Description: Utilies to parse a C++/H file.
" Maintainer:  SubhaGho
" Last Change: 3 aug. 2009

"" SECTION COPIED FROM Omni Cxx Completion 
"" Changed namespace to vimper#cpp#utils

" Expression used to ignore comments
" Note: this expression drop drastically the performance
"let vimper#cpp#utils#expIgnoreComments = 'match(synIDattr(synID(line("."), col("."), 1), "name"), '\CcComment')!=-1'
" This one is faster but not really good for C comments
let vimper#cpp#utils#reIgnoreComment = escape('\/\/\|\/\*\|\*\/', '*/\')
let vimper#cpp#utils#expIgnoreComments = 'getline(".") =~ g:vimper#cpp#utils#reIgnoreComment'

" Characters to escape in a filename for vimgrep
"TODO: Find more characters to escape
let vimper#cpp#utils#szEscapedCharacters = ' %#'

" Resolve the path of the file
" TODO: absolute file path
function! vimper#cpp#utils#ResolveFilePath(szFile)
	let result = ''
	let listPath = split(globpath(&path, a:szFile), "\n")
	if len(listPath)
		let result = listPath[0]
	endif
	return simplify(result)
endfunc

" Get code without comments and with empty strings
" szSingleLine must not have carriage return
function! vimper#cpp#utils#GetCodeFromLine(szSingleLine)
	" We set all strings to empty strings, it's safer for 
	" the next of the process
	let szResult = substitute(a:szSingleLine, '".*"', '""', 'g')

	" Removing c++ comments, we can use the pattern ".*" because
	" we are modifying a line
	let szResult = substitute(szResult, '\/\/.*', '', 'g')

	" Now we have the entire code in one line and we can remove C comments
	return s:RemoveCComments(szResult)
endfunc

" Remove C comments on a line
function! s:RemoveCComments(szLine)
	let result = a:szLine

	" We have to match the first '/*' and first '*/'
	let startCmt = match(result, '\/\*')
	let endCmt = match(result, '\*\/')
	while startCmt!=-1 && endCmt!=-1 && startCmt<endCmt
		if startCmt>0
			let result = result[ : startCmt-1 ] . result[ endCmt+2 : ]
		else
			" Case where '/*' is at the start of the line
			let result = result[ endCmt+2 : ]
		endif
		let startCmt = match(result, '\/\*')
		let endCmt = match(result, '\*\/')
	endwhile
	return result
endfunc

" Get a c++ code from current buffer from [lineStart, colStart] to 
" [lineEnd, colEnd] without c++ and c comments, without end of line
" and with empty strings if any
" @return a string
function! vimper#cpp#utils#GetCode(posStart, posEnd)
	let posStart = a:posStart
	let posEnd = a:posEnd
	if a:posStart[0]>a:posEnd[0]
		let posStart = a:posEnd
		let posEnd = a:posStart
	elseif a:posStart[0]==a:posEnd[0] && a:posStart[1]>a:posEnd[1]
		let posStart = a:posEnd
		let posEnd = a:posStart
	endif

	" Getting the lines
	let lines = getline(posStart[0], posEnd[0])
	let lenLines = len(lines)

	" Formatting the result
	let result = ''
	if lenLines==1
		let sStart = posStart[1]-1
		let sEnd = posEnd[1]-1
		let line = lines[0]
		let lenLastLine = strlen(line)
		let sEnd = (sEnd>lenLastLine)?lenLastLine : sEnd
		if sStart >= 0
			let result = vimper#cpp#utils#GetCodeFromLine(line[ sStart : sEnd ])
		endif
	elseif lenLines>1
		let sStart = posStart[1]-1
		let sEnd = posEnd[1]-1
		let lenLastLine = strlen(lines[-1])
		let sEnd = (sEnd>lenLastLine)?lenLastLine : sEnd
		if sStart >= 0
			let lines[0] = lines[0][ sStart : ]
			let lines[-1] = lines[-1][ : sEnd ]
			for aLine in lines
				let result = result . vimper#cpp#utils#GetCodeFromLine(aLine)." "
			endfor
			let result = result[:-2]
		endif
	endif

	" Now we have the entire code in one line and we can remove C comments
	return s:RemoveCComments(result)
endfunc


"" END SECTION COPIED FROM Omni Cxx Completion 
