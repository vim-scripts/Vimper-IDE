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
"" g  enum names
"" t  typedefs
"" u  union names
"" v  variable definitions
"" x  external and forward variable declarations [off] 
" Cache data

let s:_TEMP_COUNT = 0
let s:_TIME_TAKEN = 0

"" 
"" Tag Data Stucture :
"" -->
""	"macros" :
""		...
""	"typedefs" :
""		...
""	"members" :
""		...
""	"functions" :
""		"functions" :
""			...
""		"prototypes" :
""			...
""		...
""	"classes" :
""		<name> :
"" 			"typedefs" :
""				...
"" 			"members" :
""				...
""			"functions" :
""				...
""			"prototypes" :
""				...
""			...
""	"structs" :
""		<name> :
""			"members" :
""				...
""			"funcp" :
""				...
""			"funcd" :
""				...
""		...
""	"enums" :
""		<name> :
""			"members" :
""				...
""		...
""
let s:CURRENT_TAG_LIST = {}

function! vimper#project#cpp#class_buffer#GetDefinition(name, record)
	let l:taglist = taglist("^" . a:name . "$")
	if !empty(l:taglist) && !empty(l:taglist[0])
		let l:taglist[0]["displayname"] = s:GetTypeName(a:name)	
	endif
	if !empty(l:taglist) && !empty(l:taglist[0])
		return l:taglist[0]
	endif
	return {}
endfunction " GetDefinition()

function! vimper#project#cpp#class_buffer#LoadFile(filename, root)

	let s:_TIME_TAKEN = 0
	let l:t_file = expand("$TEMP") . "/class_buffer_" . s:_TEMP_COUNT "_" .  vimper#project#Utils#GetFileName(a:filename) . ".tmp"
	let l:startime = localtime()
	let l:taglines = []
	let result = vimper#project#cpp#functions#IsTagFileValid(a:filename, a:root)
	if result == 1
		let s:CURRENT_TAG_LIST = {}

		let l:tagfile = vimper#project#cpp#functions#GetTagFileBySource(a:filename, a:root)
		let l:taglines = s:GetTagsForFile(a:filename, l:tagfile)
		if !empty(l:taglines)
			for l:tagline in l:taglines
				let rv = s:LoadTagLine(l:tagline)
			endfor
		endif
	endif
	let s:_TIME_TAKEN += localtime() - l:startime
	return s:CURRENT_TAG_LIST
endfunction " LoadFile()

function! s:LoadTagLine(tagline)
	if empty(a:tagline)
		return 0
	endif

	if !has_key(a:tagline, "name") || empty(a:tagline["name"])
		return 0
	endif

	if !has_key(a:tagline, "kind") || empty(a:tagline["kind"])
		return 0
	endif

	if !has_key(a:tagline, "filename") || empty(a:tagline["filename"])
		return 0
	endif

	if !has_key(a:tagline, "cmd") || empty(a:tagline["cmd"])
		return 0
	endif

	if has_key(a:tagline, "type") && a:tagline["type"] == "enum"
		return s:LoadEnumTypeTags(a:tagline)
	endif

	if has_key(a:tagline, "type") 
		if a:tagline["type"] == "class" || a:tagline["type"] == "struct" || a:tagline["type"] == "union"
			return s:LoadDataTypeTags(a:tagline)
		endif
	endif

	return s:LoadNonStructs(a:tagline)
endfunction " LoadTagLine()

function! s:ParseTagLine(data)
	let l:record = {}
	if !empty(a:data) || len(a:data) < 4
		let l:record["data"] = a:data
		let l:record["name"] = a:data[0]
		let l:record["displayname"] = s:GetTypeName(a:data[0])
		let l:record["filename"] = a:data[1]
		let l:record["cmd"] = a:data[2]
		let l:record["kind"] = a:data[3]
		let indx = 4
		while indx < len(a:data)
			let elem = a:data[indx]
			if elem =~ "^class:"
				let l:record["type"] = "class"
				let l:record["typename"] = substitute(elem, "^class:","","")
			elseif elem =~ "^struct:"
				let l:record["type"] = "struct"
				let l:record["typename"] = substitute(elem, "^struct:","","")
			elseif elem =~ "^enum:"
				let l:record["type"] = "enum"
				let l:record["typename"] = substitute(elem, "^enum:","","")
			elseif elem =~ "^union:"
				let l:record["type"] = "union"
				let l:record["typename"] = substitute(elem, "^union:","","")
			elseif elem =~  "^signature:"
				let l:record["signature"] = substitute(elem, "^signature:","","")
			elseif elem =~ "^typeref:" 
				let l:record["reference"] = substitute(elem, "^typeref:","","")
			elseif elem =~ "^access:"
				let l:record["access"] = substitute(elem, "^access:","","")
			elseif elem =~ "^inherits:"
				let l:record["inherits"] = substitute(elem, "^inherits:","","")
			elseif elem =~ "^namespace:"
				let l:record["namespace"] = substitute(elem, "^namespace:","","")
			endif

			let indx = indx + 1
		endwhile
		if l:record["kind"] == "c"
			let l:record["type"] = "class"
			if has_key(l:record, "namespace") && l:record["name"] !~ "^" . l:record["namespace"] . "::" . l:record["displayname"] . "$"
				let l:record["name"] = l:record["namespace"] . "::" . l:record["name"]
			endif
			let l:record["typename"] = l:record["name"]
		elseif l:record["kind"] == "s"
			let l:record["type"] = "struct"
			if has_key(l:record, "namespace") && l:record["name"] !~ "^" . l:record["namespace"] . "::" . l:record["displayname"] . "$"
				let l:record["name"] = l:record["namespace"] . "::" . l:record["name"]
			endif
			let l:record["typename"] = l:record["name"]
		elseif l:record["kind"] == "u"
			let l:record["type"] = "union"
			if has_key(l:record, "namespace") && l:record["name"] !~ "^" . l:record["namespace"] . "::" . l:record["displayname"] . "$"
				let l:record["name"] = l:record["namespace"] . "::" . l:record["name"]
			endif
			let l:record["typename"] = l:record["name"]
		elseif l:record["kind"] == "g"
			let l:record["type"] = "enum"
			if has_key(l:record, "namespace") && l:record["name"] !~ "^" . l:record["namespace"] . "::" . l:record["displayname"] . "$"
				let l:record["name"] = l:record["namespace"] . "::" . l:record["name"]
			endif
			let l:record["typename"] = l:record["name"]
		endif
	endif
	return l:record
endfunction " ParseTagLine()

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

function! s:LoadNonStructs(tagline)
	let l:typedict = {}

	if has_key(a:tagline, "type") 
		if a:tagline["type"] == "class" || a:tagline["type"] == "struct" || a:tagline["type"] == "enum" || a:tagline["type"] == "union"
			return 0
		endif
	endif

	if !has_key(a:tagline, "kind")
		return 0
	endif

	if a:tagline["kind"] != "f" && a:tagline["kind"] != "p" && a:tagline["kind"] != "m" && a:tagline["kind"] != "d" &&  a:tagline["kind"] != "t"
		return 0
	endif

	if a:tagline["kind"] == "f" || a:tagline["kind"] == "p"
		let l:funcdict = {}
		if has_key(s:CURRENT_TAG_LIST, "functions")
			let l:typedict = s:CURRENT_TAG_LIST["functions"]
		else
			let s:CURRENT_TAG_LIST["functions"] = l:typedict
		endif
		if a:tagline["kind"] == "f"
			if has_key(l:typedict, "functions")
				let l:funcdict = l:typedict["functions"]
			else
				let l:typedict["functions"] = l:funcdict
			endif
		elseif a:tagline["kind"] == "d"
			if has_key(l:typedict, "prototypes")
				let l:funcdict = l:typedict["prototypes"]
			else
				let l:typedict["prototypes"] = l:funcdict
			endif
		else
			return 0
		endif
		let l:funcdict[a:tagline["name"] . a:tagline["signature"]] = a:tagline
	elseif a:tagline["kind"] == "t"
		if has_key(s:CURRENT_TAG_LIST, "typedefs")
			let l:typedict = s:CURRENT_TAG_LIST["typedefs"]
		else
			let s:CURRENT_TAG_LIST["typedefs"] = l:typedict
		endif
		let l:typedict[a:tagline["name"]] = a:tagline
	elseif a:tagline["kind"] == "d"
		if has_key(s:CURRENT_TAG_LIST, "macros")
			let l:typedict = s:CURRENT_TAG_LIST["macros"]
		else
			let s:CURRENT_TAG_LIST["macros"] = l:typedict
		endif
		let l:typedict[a:tagline["name"]] = a:tagline
	elseif a:tagline["kind"] == "m"
		if has_key(s:CURRENT_TAG_LIST, "members")
			let l:typedict = s:CURRENT_TAG_LIST["members"]
		else
			let s:CURRENT_TAG_LIST["members"] = l:typedict
		endif
		let l:typedict[a:tagline["name"]] = a:tagline
	endif
	return 1
endfunction " LoadFunctionTags()

function! s:LoadEnumTypeTags(tagline)
	if empty(a:tagline)
		return 0
	endif

	if !has_key(a:tagline, "type")
		return 0
	endif

	if !has_key(a:tagline, "typename") || empty(a:tagline["typename"])
		return 0
	endif

	if a:tagline["type"] != "enum"
		return 0
	endif

	let l:typedict = {}

	if has_key(s:CURRENT_TAG_LIST, "enums")
		let l:enums = s:CURRENT_TAG_LIST["enums"]
		if has_key(l:enums, a:tagline["typename"])
			let l:typedict = l:enums[a:tagline["typename"]]
		else
			let l:enums[a:tagline["typename"]] = l:typedict
		endif
	else
		let l:enums = {}
		let s:CURRENT_TAG_LIST["enums"] = l:enums
		let l:enums[a:tagline["name"]] = l:typedict
	endif

	if a:tagline["kind"] == "g"
		let l:typedict["definition"] = a:tagline
		return 1
	endif

	let l:members = {}
	if has_key(l:typedict, "members")
		let l:members = l:typedict["members"]
	else
		let l:typedict["members"] = l:members
	endif
	let l:members[a:tagline["displayname"]] = a:tagline

	return 1
endfunction " LoadEnumTypeTags()

function! s:LoadDataTypeTags(tagline)
	if empty(a:tagline)
		return 0
	endif

	if !has_key(a:tagline, "kind")
		return 0
	endif

	if !has_key(a:tagline, "type")
		return 0
	endif

	if !has_key(a:tagline, "name")
		return 0
	endif

	if a:tagline["type"] != "class" && a:tagline["type"] != "struct" && a:tagline["type"] != "union"
		return 0
	endif

	if !has_key(a:tagline, "typename") || empty(a:tagline["typename"])
		return 0
	endif

	let l:typedict = {}
	if a:tagline["type"] == "class" 
		let l:classes = {}
		if has_key(s:CURRENT_TAG_LIST, "classes")
			let l:classes = s:CURRENT_TAG_LIST["classes"]
		else
			let s:CURRENT_TAG_LIST["classes"] = l:classes
		endif
		if has_key(l:classes, a:tagline["typename"])
			let l:typedict = l:classes[a:tagline["typename"]]
		else
			let l:classes[a:tagline["typename"]] = l:typedict
		endif
	elseif a:tagline["type"] == "struct" 
		let l:structs = {}
		if has_key(s:CURRENT_TAG_LIST, "structs")
			let l:structs = s:CURRENT_TAG_LIST["structs"]
		else
			let s:CURRENT_TAG_LIST["structs"] = l:structs
		endif
		if has_key(l:structs, a:tagline["typename"])
			let l:typedict = l:structs[a:tagline["typename"]]
		else
			let l:structs[a:tagline["typename"]] = l:typedict
		endif
	elseif a:tagline["type"] == "union" 
		let l:unions = {}
		if has_key(s:CURRENT_TAG_LIST, "unions")
			let l:unions = s:CURRENT_TAG_LIST["unions"]
		else
			let s:CURRENT_TAG_LIST["unions"] = l:unions
		endif
		if has_key(l:unions, a:tagline["typename"])
			let l:typedict = l:unions[a:tagline["typename"]]
		else
			let l:unions[a:tagline["typename"]] = l:typedict
		endif
	endif

	if a:tagline["type"] == "class" && a:tagline["kind"] == "c"
		let l:typedict["definition"] = a:tagline
		return 1
	endif

	if a:tagline["type"] == "struct" && a:tagline["kind"] == "s"
		let l:typedict["definition"] = a:tagline
		return 1
	endif

	if a:tagline["type"] == "union" && a:tagline["kind"] == "u"
		let l:typedict["definition"] = a:tagline
		return 1
	endif

	if a:tagline["kind"] == "t"
		let l:typedefs = {}
		if has_key(l:typedict, "typedefs")
			let l:typedefs = l:typedict["typedefs"]
		else
			let l:typedict["typedefs"] = l:typedefs
		endif
		let l:typedefs[a:tagline["displayname"]] = a:tagline
		return 1
	endif

	if a:tagline["kind"] == "m"
		let l:members = {}
		if has_key(l:typedict, "members")
			let l:members = l:typedict["members"]
		else
			let l:typedict["members"] = l:members
		endif

		let l:members[a:tagline["displayname"]] = a:tagline
		return 1
	endif

	if a:tagline["kind"] == "f"
		let l:functions = {}
		if has_key(l:typedict, "functions")
			let l:functions = l:typedict["functions"]
		else
			let l:typedict["functions"] = l:functions
		endif
		if !has_key(a:tagline, "signature")
			return 0
		endif
		let l:functions[a:tagline["displayname"].a:tagline["signature"]] = a:tagline
		return 1
	endif

	if a:tagline["kind"] == "p"
		let l:prototypes = {}
		if has_key(l:typedict, "prototypes")
			let l:prototypes = l:typedict["prototypes"]
		else
			let l:typedict["prototypes"] = l:prototypes
		endif
		if !has_key(a:tagline, "signature")
			return 0
		endif
		let l:prototypes[a:tagline["displayname"].a:tagline["signature"]] = a:tagline
		return 1
	endif

endfunction " LoadDataTypeTags()

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

	let l:fname = vimper#project#Utils#GetFileName(l:ifile)
	if empty(l:fname)
		return l:retval
	endif

	for l:line in l:inlines
		if l:line =~ "^!"
			continue
		endif

		if l:line !~ l:fname
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
		if l:filename !~ l:fname
			continue
		endif
		let l:record = s:ParseTagLine(l:data)
		call add(l:retval, l:record)
	endfor
	return l:retval
endfunction " ParseFile()
