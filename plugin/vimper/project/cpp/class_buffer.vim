"" File: class_buffer.vim
"" Description: Functions used for displaying the class browser.
"" Version: 1.0
"" Author: ghoshs (subhagho@msn.com)
"" Namespace: vimper#project#cpp#class_buffer

"" c  classes
"" d  macro definitions
"" e  enumerators (values inside an enumeration)
"" f  function definitions "" g  enumeration names
"" l  local variables [off]
"" m  class, struct, and union members
"" n  namespaces
"" p  function prototypes [off]
"" s  structure names
"" t  typedefs
"" u  union names
"" v  variable definitions
"" x  external and forward variable declarations [off] 
" Cache data
let s:CACHE_TAG_FILES = {}
let s:CACHE_TAG_ENV = ''
let s:_TEMP_COUNT = 0
let s:_TIME_TAKEN = 0

function! vimper#project#cpp#class_buffer#LoadFile(filename, root)

	let s:_TIME_TAKEN = 0
	let l:t_file = expand("$TEMP") . "/class_buffer_" . s:_TEMP_COUNT "_" .  vimper#project#Utils#GetFileName(a:filename) . ".tmp"
	let l:startime = localtime()
	let l:taglines = []
	let result = vimper#project#cpp#functions#IsTagFileValid(a:filename, a:root)
	if result == 1
		let l:tagfile = vimper#project#cpp#functions#GetTagFileBySource(a:filename, a:root)
		let l:taglines = s:GetTagsForFile(a:filename, l:tagfile)
		let l:types = {}
		if !empty(l:taglines)
			let l:typedict = s:ExtractTypes(l:taglines)
			for l:tagline in l:taglines
				let l:used = 0
				if has_key(l:typedict, "class") && !empty(l:typedict["class"])
					let retval = s:IsValidClassTagLine(l:typedict["class"], l:tagline)
					if retval == 1
						for l:class in l:typedict["class"]
							let l:used = s:LoadClassTypeTags(types, l:class, l:tagline)
						endfor
					endif
				endif
				if l:used != 0
					continue
				endif
				if has_key(l:typedict, "struct") && !empty(l:typedict["struct"])
					for l:class in l:typedict["struct"]
						let l:used = s:LoadStructTypeTags(types, l:class, l:tagline)
						if l:used != 0
							break
						endif
					endfor
				endif
				if l:used != 0
					continue
				endif
				if has_key(l:typedict, "union") && !empty(l:typedict["union"])
					for l:class in l:typedict["union"]
						let l:used = s:LoadUnionTypeTags(types, l:class, l:tagline)
						if l:used != 0
							break
						endif
					endfor
				endif
				if l:used != 0
					continue
				endif
				if has_key(l:typedict, "enum") && !empty(l:typedict["enum"])
					for l:enum in l:typedict["enum"] 
						let l:used = s:LoadEnumTypeTags(l:types, l:enum, l:tagline)
						if l:used != 0
							break
						endif
					endfor
				endif 
				if l:used != 0
					continue
				endif
				let l:used = s:LoadFunctionTags(l:types, l:tagline)
			endfor
		endif
	endif
	let s:_TIME_TAKEN += localtime() - l:startime
	return l:types
endfunction " LoadFile()

function! s:IsValidClassTagLine(types, tagline)
	let l:line = a:tagline
	let l:found = 0
	for l:class in a:types
		if l:line =~ l:class
			let l:found = 1
			break
		endif
	endfor
	if !l:found
		return 0
	endif

	let l:data = s:SplitTagLine(l:line)
	if empty(l:data)
		return 0
	endif
	if len(l:data) < 5
		return 0
	endif

	if empty(l:data[4])
		return 0
	endif

	for l:type in a:types
		let l:expr =  "^class:" . l:type . "$"
		if l:data[4] =~ l:expr
			return 1
		else
			let l:expr =  "^typeref:class:" . l:type . "$"
			if l:data[4] =~ l:expr
				return 1
			endif
		endif
	endfor
	return 0
endfunction " IsValidClassTagLine()

function! s:GetTaglines(types, tagfile)
	let l:taglines = []
	if empty(a:types)
		return l:taglines
	endif
	if !filereadable(a:tagfile)
		return l:taglines
	endif
	let l:lines = readfile(a:tagfile)
	if empty(l:lines)
		return l:taglines
	endif

	let l:failed = []
	for l:line in l:lines
		let l:found = 0
		for l:class in a:types
			if l:line =~ l:class
				let l:found = 1
				break
			endif
		endfor
		if !l:found
			continue
		endif

		let l:data = s:SplitTagLine(l:line)
		if empty(l:data)
			continue
		endif
		if len(l:data) < 5
			continue
		endif

		if empty(l:data[4])
			continue
		endif

		for l:type in a:types
			let l:expr =  "^class:" . l:type . "$"
			if l:data[4] =~ l:expr
				call add(l:taglines, l:line)
				break
			else
				let l:expr =  "^typeref:class:" . l:type . "$"
				if l:data[4] =~ l:expr
					call add(l:taglines, l:line)
					break
				endif
			endif
		endfor
	endfor
	return l:taglines
endfunction " GetTaglines()

function! s:SplitTagLine(tagline)

	let l:columns = []

	let l:index = 0
	let l:lastindx = 0

	let l:parts = split(a:tagline, "\t")
	if empty(l:parts)
		return l:columns
	endif
	let l:incmd = 0
	let l:cmd = ""
	let l:ignore = 0

	for l:part in l:parts
		if l:ignore == 0 && l:part =~ "^\/\^"
			if l:part =~ "\;\"$"
				call add(l:columns, l:part)
				let l:ignore = 1
			else
				let l:incmd = 1
				let l:cmd = l:cmd . l:part
			endif
		elseif l:incmd == 1 && l:part =~ "\;\"$"
			let l:incmd = 0
			let l:cmd = l:cmd . "\t" . l:part
			call add(l:columns, l:cmd)
			let l:ignore = 1
		elseif l:incmd == 1
			let l:cmd = l:cmd . "\t" . l:part
		else
			call add(l:columns, l:part)
		endif
	endfor
	return l:columns
endfunction " SplitTagLine()

function! s:GetTypeName(name)
	return  matchlist(a:name, "[^::]*$")[0]
endfunction " GetTypeName()

function! s:GetNamespace(name)
	return substitute(substitute(a:name, "[^::]*$", "",""), "::$", "", "")
endfunction " GetNamespace()

function! s:LoadStructTypeTags(types, typename, tagline)
	return s:LoadDataTypeTags(a:types, a:typename, a:tagline, "struct")
endfunction " LoadStructTypeTags()

function! s:LoadClassTypeTags(types, typename, tagline)
	return s:LoadDataTypeTags(a:types, a:typename, a:tagline, "class")
endfunction " LoadStructTypeTags()

function! s:LoadUnionTypeTags(types, typename, tagline)
	return s:LoadDataTypeTags(a:types, a:typename, a:tagline, "union")
endfunction " LoadStructTypeTags()

function! s:LoadFunctionTags(types, tagline)
	let l:typedict = {}

	let l:data = s:SplitTagLine(a:tagline)
	if empty(l:data)
		return -1
	endif

	if len(l:data) < 5
		return 0
	endif

	if l:data[4] =~ "^class:" || l:data[4] =~ "^struct:"
		return 0
	endif

	if l:data[3] != "f" && l:data[3] != "p"
		return 0
	endif

	let l:fdict = {}
	let l:fdict["name"] = l:data[0]
	let l:fdict["filename"] = l:data[1]
	let l:fdict["cmd"] = l:data[2]
	let l:fdict["kind"] = l:data[3]
	if len(l:data) > 5
		let l:signt = substitute(l:data[5], "^signature:","","")
	elseif len(l:data) == 5
		let l:signt = substitute(l:data[4], "^signature:","","")
	endif
	let l:fdict["signature"] = l:signt

	if has_key(a:types, "function")
		let l:typedict = a:types["function"]
	else
		let a:types["function"] = l:typedict
	endif
	let l:funcdict = {}
	if l:data[3] == "f"
		if has_key(l:typedict, "funcd")
			let l:funcdict = l:typedict["funcd"]
		else
			let l:typedict["funcd"] = l:funcdict
		endif
	elseif l:data[3] == "p"
		if has_key(l:typedict, "funcp")
			let l:funcdict = l:typedict["funcp"]
		else
			let l:typedict["funcp"] = l:funcdict
		endif
	else
		return 0
	endif
	let l:funcdict[l:data[0] . l:signt] = l:fdict

	return 1
endfunction " LoadFunctionTags()

function! s:LoadEnumTypeTags(types, typename, tagline)
	let l:typedict = {}

	let l:enumname = s:GetTypeName(a:typename)
	if empty(l:enumname)
		return 0
	endif

	if has_key(a:types, "enum")
		let l:enums = a:types["enum"]
		if has_key(l:enums, a:typename)
			let l:typedict = l:enums[a:typename]
		endif
	endif

	if empty(l:typedict)
		let l:taglist = taglist("^" . a:typename . "$") " Get an exact match for the class declaration
		if !empty(l:taglist)
			let l:retdict = l:taglist[0] 
			if !empty(l:retdict)
				if has_key(l:retdict, "kind")
					if l:retdict["kind"] == "g"
						let l:typedict["def"] = l:retdict
					else
						return 0
					endif
				endif
			endif
		endif
	endif

	let l:data = s:SplitTagLine(a:tagline)

	if empty(l:data)
		return -1
	endif
	if len(l:data) < 5
		return 0
	endif

	if empty(l:data[4])
		return 0
	endif
	let l:expr = "^enum:" . a:typename . "$"
	if l:data[4] !~ l:expr
		return 0
	endif
	if l:data[3] != "e"
		return 1
	endif

	let l:mdict = {}
	let l:mname = s:GetTypeName(l:data[0])
	let l:mdict["name"] = l:mname
	let l:mdict["filename"] = l:data[1]
	let l:mdict["cmd"] = l:data[2]
	let l:mdict["kind"] = l:data[3]

	let l:members = {}
	if has_key(l:typedict, "members")
		let l:members = l:typedict["members"]
	else
		let l:typedict["members"] = l:members
	endif
	let l:members[l:mname] = l:mdict

	if !has_key(a:types, "enum")
		let l:enums = {}
		let a:types["enum"] = l:enums
	endif
	if !has_key(l:enums, a:typename)
		let l:enums[a:typename] = l:typedict
	endif
	return 1
endfunction " LoadEnumTypeTags()

function! s:LoadDataTypeTags(types, typename, tagline, type)
	let l:typedict = {}
	let l:classes = {}

	let l:classname = s:GetTypeName(a:typename)
	if empty(l:classname)
		return 0
	endif

	if has_key(a:types, a:type)
		let l:classes = a:types[a:type]
		if has_key(l:classes, a:typename)
			let l:typedict = l:classes[a:typename]
		endif
	endif

	if empty(l:typedict) && a:type == "class"
		let l:taglist = taglist("^" . a:typename . "$") " Get an exact match for the class declaration
		if !empty(l:taglist)
			let l:retdict = l:taglist[0] 
			if !empty(l:retdict)
				if has_key(l:retdict, "kind")
					if l:retdict["kind"] == "c"
						let l:typedict["def"] = l:retdict
					else
						return -1
					endif
				else 
					return -1
				endif
			else
				return -1
			endif
		endif
	elseif empty(l:typedict) && a:type == "struct"
		let l:taglist = taglist("^" . a:typename . "$") " Get exact match tagline for the struct
		if !empty(l:taglist)
			let l:retdict = l:taglist[0] 
			if !empty(l:retdict)
				if has_key(l:retdict, "kind")
					if l:retdict["kind"] == "s"
						let l:typedict["def"] = l:retdict
					else
						return -1
					endif
				else
					return -1
				endif
			endif
		endif
	endif

	let l:data = s:SplitTagLine(a:tagline)
	if empty(l:data)
		return -1
	endif
	if len(l:data) < 5
		return 0
	endif

	if empty(l:data[4])
		return 0
	endif

	let l:expr = "^" . a:type . ":" . a:typename . "$"
	if l:data[4] !~ l:expr
		if a:type != "class"
			let l:expr = "^typeref:" . a:type . ":" . a:typename . "$"
			if l:data[4] !~ l:expr
				return 0
			endif
		else
			return 0
		endif
	endif

	if l:data[3] == "c" && a:type == "class"
		return 1
	endif

	let l:name = s:GetTypeName(l:data[0])
	if empty(l:name)
		return -1 
	endif
	let l:filename = l:data[1]
	if empty(l:filename)
		return -1
	endif
	let l:cmd = l:data[2]
	if empty(l:cmd)
		return -1
	endif

	if (a:type == "struct" || a:type == "union") && (l:data[3] == "t" || l:data[3] == "v")
		if l:data[3] == "v"
			let l:expr = "^typeref:" . a:type . ":" . a:typename . "$"
			if l:data[4] !~ l:expr
				return 0
			endif
		endif
		if has_key(l:typedict, "def")
			let l:defdict = l:typedict["def"]
			if l:defdict["name"] =~ "__anon"
				let l:defdict["name"] = l:data[0]
				if !has_key(l:classes, l:data[0])
					let l:classes[l:data[0]] = l:typedict
				endif
			endif
		else
			let l:defdict = {}
			let l:defdict["name"] = l:data[0]
			let l:defdict["filename"] = l:data[1]
			let l:defdict["cmd"] = l:data[2]
			let l:defdict["kind"] = "s"
			let l:defdict["static"] = 0

			let l:typedict["def"] = l:defdict
			if !has_key(l:classes, l:data[0])
				let l:classes[l:data[0]] = l:typedict
			endif
		endif
		if !has_key(a:types, a:type)
			let a:types[a:type] = l:classes
		endif
		if !has_key(l:classes, a:typename)
			let l:classes[a:typename] = l:typedict
		endif
		return 1
	endif

	if l:data[3] == "f"
		let l:signt = ""
		if l:data[5] =~ "^signature:"
			let l:signt = substitute(l:data[5], "^signature:","","")
		endif
		if empty(l:signt)
			if l:data[6] =~ "^signature:"
				let l:signt = substitute(l:data[6], "^signature:","","")
			endif
		endif
		if empty(l:signt)
			return -1
		endif

		let l:fdict = {}
		let l:fdict["name"] = l:name
		let l:fdict["filename"] = l:filename
		let l:fdict["cmd"] = l:cmd
		let l:fdict["signature"] = l:signt
		if has_key(l:typedict, "funcd")
			let l:funcs = l:typedict["funcd"]
			let l:funcs[l:name . l:signt] = l:fdict
		else
			let l:funcs = {}
			let l:funcs[l:name . l:signt] = l:fdict
			let l:typedict["funcd"] = l:funcs
		endif
	elseif l:data[3] == "p"
		let l:signt = ""
		if l:data[6] =~ "^signature:"
			let l:signt = substitute(l:data[6], "^signature:","","")
		endif
		if empty(l:signt)
			if l:data[7] =~ "^signature:"
				let l:signt = substitute(l:data[7], "^signature:","","")
			endif
		endif
		if empty(l:signt)
			return -1
		endif

		let l:access = ""
		if l:data[5] =~ "^access:"
			let l:access = substitute(l:data[5], "^access:","","")
		endif
		if empty(l:access)
			if l:data[6] =~ "^access:"
				let l:access = substitute(l:data[6], "^access:","","")
			endif
		endif
		if empty(l:access)
			return -1
		endif
		let l:fdict = {}
		let l:fdict["name"] = l:name
		let l:fdict["filename"] = l:filename
		let l:fdict["cmd"] = l:cmd
		let l:fdict["access"] = l:access
		let l:fdict["signature"] = l:signt
		if has_key(l:typedict, "funcp")
			let l:funcs = l:typedict["funcp"]
			let l:funcs[l:name . l:signt] = l:fdict
		else
			let l:funcs = {}
			let l:funcs[l:name . l:signt] = l:fdict
			let l:typedict["funcp"] = l:funcs
		endif
	elseif l:data[3] == "m"
		let l:access = substitute(l:data[5], "^access:", "", "")
		let l:mdict = {}
		let l:mdict["name"] = l:name
		let l:mdict["filename"] = l:filename
		let l:mdict["cmd"] = l:cmd
		let l:mdict["access"] = l:access
		if has_key(l:typedict, "members")
			let l:membs = l:typedict["members"]
			let l:membs[l:name] = l:mdict
		else
			let l:membs = {}
			let l:membs[l:name] = l:mdict
			let l:typedict["members"] = l:membs
		endif
	endif
	if !has_key(a:types, a:type)
		let a:types[a:type] = l:classes
	endif
	if !has_key(l:classes, a:typename)
		let l:classes[a:typename] = l:typedict
	endif

	return 1
endfunction " LoadClassTypeTags()

function! s:ExtractTypes(taglines)
	let l:retval = {}

	for l:line in a:taglines
		let l:data = s:SplitTagLine(l:line)
		if empty(l:data)
			continue
		endif
		if len(l:data) < 5
			continue
		endif

		if empty(l:data[4])
			continue
		endif

		call s:SearchAndAddType(l:retval, l:data, "class")
		call s:SearchAndAddType(l:retval, l:data, "struct")
		call s:SearchAndAddType(l:retval, l:data, "union")
		call s:SearchAndAddType(l:retval, l:data, "enum")
	endfor

	return l:retval
endfunction " ExtractTypes()

function! s:SearchAndAddType(adict,  data, type)
	let l:expr = "^" . a:type . "\:"
	if a:data[4] =~ l:expr
		let l:classlist = []
		if has_key(a:adict, a:type)
			let l:classlist = a:adict[a:type]
		endif
		let l:class = substitute(a:data[4], l:expr, "", "")
		let l:found = 0
		for l:cname in l:classlist
			if match(l:cname, l:class) == 0
				let l:found = 1
				break
			endif
		endfor
		if !l:found
			call add(l:classlist, l:class)
			let a:adict[a:type] = l:classlist
		endif
	endif
endfunction " SearchAndAddType()

function! s:GetTagsForFile(fsource, ftags)
	let l:retval = []
	let l:ifile = a:fsource
	if has('win32')
		let l:ifile = vimper#project#common#WinConvertPath(l:ifile)
	endif
	if !filereadable(a:ftags)
		return l:retval
	endif
	let l:inlines = readfile(a:ftags)
	if empty(l:inlines)
		return l:retval
	endif

	for l:line in l:inlines
		if l:line =~ "^!"
			continue
		endif

		if l:line !~ a:fsource
			continue
		endif

		let l:data = s:SplitTagLine(l:line)
		if empty(l:data)
			continue
		endif
		if empty(l:data[1])
			continue
		endif
		let l:filename = l:data[1]
		if match(l:filename, l:ifile) == 0
			call add(l:retval, l:line)
		endif
	endfor
	return l:retval
endfunction " ParseFile()

" Return if the tag env has changed
function! s:HasTagEnvChanged()
	if s:CACHE_TAG_ENV == &tags
		return 0
	else
		let s:CACHE_TAG_ENV = &tags
		return 1
	endif
endfunc

" Return if a tag file has changed in tagfiles()
function! s:HasATagFileOrTagEnvChanged()
	call s:HasTagEnvChanged()

	let result = 0
	for tagFile in tagfiles()
		if tagFile == ""
			continue
		endif

		if has_key(s:CACHE_TAG_FILES, tagFile)
			let currentFiletime = getftime(tagFile)
			if currentFiletime > s:CACHE_TAG_FILES[tagFile]
				" The file has changed, updating the cache
				let s:CACHE_TAG_FILES[tagFile] = currentFiletime
				let result = 1
			endif
		else
			" We store the time of the file
			let s:CACHE_TAG_FILES[tagFile] = getftime(tagFile)
			let result = 1
		endif
	endfor
	return result
endfunc

