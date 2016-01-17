"=============================================================================
" FILE: plugin/debugger.vim
" AUTHOR: haya14busa
" License: MIT license
"=============================================================================
scriptencoding utf-8
if expand('%:p') ==# expand('<sfile>:p')
  unlet! g:loaded_debugger
endif
if exists('g:loaded_debugger')
  finish
endif
let g:loaded_debugger = 1
let s:save_cpo = &cpo
set cpo&vim

command! DebuggerOn call debugger#init()

" :StackTrace accepts v:throwpoint string as an argument and makes a stack trace report.
command! -nargs=1 StackTrace call debugger#stacktrace#report(<q-args>)

" :CallStack {id} save callstack
" :CallStackReport {id} show callstack report
command! -nargs=? CallStack call debugger#stacktrace#callstack(<q-args>)
command! -nargs=? CallStackReport call debugger#stacktrace#callstackreport(<q-args>)

let &cpo = s:save_cpo
unlet s:save_cpo
" __END__
" vim: expandtab softtabstop=2 shiftwidth=2 foldmethod=marker
