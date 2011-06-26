" Description: Templates for creating the Vim Project load configuration.
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
let g:vimperProjectType = "vim"


execute "cd " . g:vimperProjectRoot

execute "VTreeExplore " . g:vimperProjectRoot
