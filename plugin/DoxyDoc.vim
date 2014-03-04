"=============================================================================
" File: DoxyDoc.vim
" Author: mopp
" Created: 2014-01-18
"=============================================================================


scriptencoding utf-8
if exists('g:loaded_DoxyDoc')
    finish
endif
let g:loaded_DoxyDoc = 1

let s:save_cpo = &cpo
set cpo&vim


command! -nargs=0 DoxyDoc :call DoxyDoc#make_function_comment()
command! -nargs=0 DoxyDocAuthor :call DoxyDoc#make_author_comment()


let &cpo = s:save_cpo
unlet s:save_cpo
