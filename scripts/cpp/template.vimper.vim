" Description: Templates for creating the C/C++ Project load configuration.
" Maintainer:  SubhaGho
" Last Change: 3 aug. 2009


" Keep only one window open
execute "wincmd o" 
execute "bdelete"

filetype on
filetype indent on
filetype plugin on

let s:wSize = 40
if exists("g:vimperExplorerWidth") && g:vimperExplorerWidth
	let s:wSize = g:vimperExplorerWidth
endif
execute s:wSize . "vsp"
execute "wincmd h"

let g:vimperProjectRoot = <PROJ_HOME>
let g:vimperProjectType = "cpp"

let s:tagsFolder = vimper#project#common#WinConvertPath(g:vimperProjectRoot . "/.tags")
let s:tagsFile = s:tagsFolder . "/proj.tags"

let s:tagStartDir = vimper#project#common#WinConvertPath(g:vimperProjectRoot)
let g:vimperTagsOnSave = 1

set tags+=<TAG_DIR>/.tags/current.tag
set tags+=<TAG_DIR>/.tags/proj.tags
set tags+=~/.vim/tags/cpp.tags 

"map <C-F12> :call <SID>RunCtags()<CR>
command! -n=? VProjTags :call s:RunCtags()

execute "cd " . g:vimperProjectRoot

execute "VTreeExplore " . g:vimperProjectRoot

" OmniCppComplete
let OmniCpp_NamespaceSearch = 2
let OmniCpp_GlobalScopeSearch = 1
let OmniCpp_ShowAccess = 1
let OmniCpp_MayCompleteDot = 1
let OmniCpp_MayCompleteArrow = 1
let OmniCpp_MayCompleteScope = 1
let OmniCpp_DefaultNamespaces = ["std", "_GLIBCXX_STD"]
" automatically open and close the popup menu / preview window
au CursorMovedI,InsertLeave * if pumvisible() == 0|silent! pclose|endif
:set completeopt=menuone,menu,longest,preview

execute "VClassBr"

call vimper#project#session#SessionManager#Load(g:vimperProjectRoot)
au BufDelete * call vimper#project#session#SessionManager#RemoveFile(g:vimperProjectRoot, expand("<afile>:p"))

function! s:RunCtags()
	let scpath = expand('$VIMPER_HOME') . '/scripts/ctags.sh -d '
	let cmd = '!' . scpath . s:tagStartDir . ' ' . s:tagsFile
	execute cmd
endfunction! "RunCtags()
