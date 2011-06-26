" Description: Templates for creating the C/C++ Project load configuration.
" Maintainer:  SubhaGho
" Last Change: 3 aug. 2009


" Keep only one window open
execute "wincmd o" 
execute "bdelete"

let s:wSize = 40
if exists("g:vimperExplorerWidth") && g:vimperExplorerWidth
  let s:wSize = g:vimperExplorerWidth
endif
execute s:wSize . "vsp"
execute "wincmd h"

let g:vimperProjectRoot = <PROJ_HOME>
let g:vimperProjectType = "vcpp"

let s:tagsFolder = vimper#project#common#WinConvertPath(proj_root . "/.tags")
let s:tagsFile = s:tagsFolder . "/proj.tags"

let s:tagStartDir = vimper#project#common#WinConvertPath(proj_root)

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

function! s:RunCtags()
  let cmd = "!ctags -f " . s:tagsFile . " -R --c++-kinds=+pl --fields=+iaS --extra=+q " . s:tagStartDir
  execute cmd
endfunction! "RunCtags()
