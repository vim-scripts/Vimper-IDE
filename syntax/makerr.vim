" Vim syntax file
" Language:	GNU Make Output
" Maintainer:	ghoshs (sughosh@msn.com)
" Last Change:	8/12/2009

" For version 5.x: Clear all syntax items
" For version 6.x: Quit when a syntax file was already loaded
if version < 600
  syntax clear
elseif exists("b:current_syntax")
  finish
endif

syn case ignore

:hi MakeErrorMsg gui=bold,underline cterm=bold,underline guifg=salmon ctermfg=7 ctermbg=1
:hi MakeWarnMsg gui=bold,underline cterm=bold,underline guifg=Yellow ctermfg=7 ctermbg=1
:hi MakeInfoMsg gui=bold,underline cterm=bold,underline guifg=Green ctermfg=7 ctermbg=1

syn match makeError "^\S*\s*\: *error *\:"
syn match makeWarn "^\S*\s*\: *warning *\:"
syn match makeInfo "^\S*\s*\: *note *\:"

syn match makeCompiler "\(gcc \| g++ \| cc \| c++ \)"
syn match makeCompileFlags "\s\+-\S*"
syn match makeOutput "^make\[\S\+\]\:"

" Define the default highlighting.
" For version 5.7 and earlier: only when not done already
" For version 5.8 and later: only when an item doesn't have highlighting yet
if version >= 508 || !exists("did_man_syn_inits")
  if version < 508
    let did_makerr_syn_init = 1
    command -nargs=+ HiLink hi link <args>
  else
    command -nargs=+ HiLink hi def link <args>
  endif

  HiLink makeError	    MakeErrorMsg
  HiLink makeWarn           MakeWarnMsg
  HiLink makeInfo           MakeInfoMsg
  HiLink makeCompiler	    Question
  HiLink makeCompileFlags   Keyword
  HiLink makeOutput         Structure

  delcommand HiLink
endif

let b:current_syntax = "makerr"


