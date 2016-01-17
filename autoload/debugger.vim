let s:V = vital#of('debugger')
let s:Message = s:V.import('Vim.Message')
let s:ScriptLocal = s:V.import('Vim.ScriptLocal')
let s:String = s:V.import('Data.String')
let s:SyntaxEcho = s:V.import('Vim.SyntaxEcho')

function! debugger#init() abort
  " source this file
endfunction

command! Debugger execute 'breakadd' 'func' (expand('<slnum>') + 1) s:current_func()

command! Current call s:show_current(s:current_func(), expand('<slnum>'), expand('<sfile>'))

command! DebugHelp echo s:help()

command! -nargs=1 Break execute 'breakadd' 'func' <q-args> s:current_func()

command! File echo s:current_file(expand('<sfile>'))
command! SID echo s:sid(expand('<sfile>'))
command! -nargs=? Sfuncs echo PP(s:sfuncs(<q-args> is# '' ? s:sid(expand('<sfile>') : <q-args>))

augroup debugger-breakpoint
  autocmd!
  autocmd TextChanged,TextChangedI *.vim breakdel *
  autocmd ColorScheme * call s:init_hl()
augroup END

function! s:init_hl() abort
  highlight DebuggerSeparator term=bold ctermfg=166 gui=bold guifg=#ef5939
  highlight DebuggerCallStack term=bold cterm=bold ctermfg=118 gui=bold guifg=#A6E22E
  highlight DebuggerCurrentLineMark term=standout cterm=bold ctermfg=199 ctermbg=16 gui=bold guifg=#F92672 guibg=#232526
endfunction
call s:init_hl()

function! s:sid(sfile) abort
  let func = s:current_func(-3)
  if func is# ''
    return s:ScriptLocal.sid(a:sfile)
  endif
  return s:ScriptLocal.sid(s:last_set(func))
endfunction

function! s:current_file(sfile) abort
  let func = s:current_func(-3)
  if func is# ''
    return a:sfile
  endif
  return s:last_set(func)
endfunction

function! s:current_func(...) abort
  let offset = get(a:, 1, -2)
  let sfile = substitute(expand('<sfile>'), 'function ', '', '')
  let funcs = split(sfile, '\.\.')
  if len(funcs) < abs(offset)
    return ''
  endif
  return matchstr(funcs[offset], '.*\ze\[\d\+\]$')
endfunction

" --------------------
" function <SNR>655_test3[1]..<SNR>655_test2[1]..Debug_test
" line 7: unlet i
"      function Debug_test(...) abort
"         Last set from ~/.cache/junkfile/2016/01/2016-01-17-111024.vim
"   1    " hi
"   2    "hoge foo
"   3    let ho = 'ge'
"   4    for i in range(3)
"   5      echo i
"   6      Debugger
" ->7      unlet i
"   8    endfor
"   9    let foo = 'bar'
"   10   return
"      endfunction
function! s:show_current(funcname, slnum, sfile) abort
  call s:Message.echo('DebuggerSeparator', repeat('-', 20))
  call s:Message.echo('DebuggerCallStack', a:sfile)
  if a:funcname is# ''
    let line = ''
    if filereadable(a:sfile)
      let line = get(readfile(a:sfile), a:slnum - 1, 'End of sourced file')
    endif
    call s:_show_current_line(a:slnum, line)
    return a:sfile
  endif
  let name = s:is_dict_func(a:funcname) ? printf('{%d}', a:funcname) : a:funcname
  let lines = split(s:redir(':verbose function ' . name), "\n")
  let line_nr_len = len(matchstr(lines[-2], '^\d\+'))
  let line_dict = s:_line_dict(lines[2:-2], line_nr_len)
  call s:_show_current_line(a:slnum, line_dict[a:slnum])
  let text = []
  call s:_function(lines[0], line_nr_len)
  call s:Message.echo('Comment', lines[1])
  for line in lines[2:-2]
    let lnum = matchstr(line, '^\d\+')
    let ltext = line[line_nr_len + 1 :]
    if lnum ==# a:slnum
      call s:Message.echo('DebuggerCurrentLineMark', '->')
    else
      echo '  '
    endif
    call s:Message.echon('LineNr', s:String.pad_left(lnum, line_nr_len))
    echon ' '
    call s:SyntaxEcho.echon(ltext)
  endfor
  call s:_endfunction(line_nr_len)
  return join(text, "\n")
endfunction

function! s:_line_dict(lines, line_nr_len) abort
  let d = {}
  for line in a:lines
    let lnum = matchstr(line, '^\d\+')
    let ltext = line[a:line_nr_len + 1 :]
    let d[lnum] = ltext
  endfor
  return d
endfunction

function! s:_function(line, line_nr_len) abort
  echo repeat(' ', a:line_nr_len + 3)
  call s:Message.echon('Statement', 'function ')
  let [funcname, arg, after] = split(a:line, '\s*function \|(\|)')
  call s:Message.echon('vimFunction', funcname)
  call s:Message.echon('Delimiter', '(')
  call s:Message.echon('vimOperParen', arg)
  call s:Message.echon('Delimiter', ')')
  call s:Message.echon('vimIsCommand', after)
endfunction

function! s:_endfunction(line_nr_len) abort
  echo repeat(' ', a:line_nr_len + 3)
  call s:Message.echon('Statement', 'endfunction')
endfunction

function! s:_show_current_line(lnum, text) abort
  echo 'line '
  call s:Message.echon('Number', a:lnum)
  echon ': '
  call s:SyntaxEcho.echon(a:text)
endfunction

function! s:last_set(funcname) abort
  let name = s:is_dict_func(a:funcname) ? printf('{%d}', a:funcname) : a:funcname
  	" Last set from ~/.cache/junkfile/2016/01/2016-01-17-101852.vim
  return matchstr(split(s:redir(':verbose function ' . name), "\n")[1], '^\tLast set from \zs.*$')
endfunction

function! s:sfuncs(sid) abort
  return s:ScriptLocal.sid2sfuncs(a:sid)
endfunction

function! s:is_dict_func(funcname) abort
  return a:funcname =~# '^\d\+$'
endfunction

function! s:help() abort
  return PP({
  \   '>cont':
  \     'Continue execution until the next breakpoint is hit.',
  \   '>quit':
  \     "Abort execution.  This is like using CTRL-C, some things might still be executed, doesn't abort everything.  Still stops at the next breakpoint.",
  \   '>next':
  \     "Execute the command and come back to debug mode when it's finished.  This steps over user function calls and sourced files.",
  \   '>step':
  \     'Execute the command and come back to debug mode for the next command.  This steps into called user functions and sourced files.',
  \   '>interrupt':
  \     'This is like using CTRL-C, but unlike ">quit" comes back to debug mode for the next command that is executed.  Useful for testing |:finally| and |:catch| on interrupt exceptions.',
  \   '>finish':
  \     'Finish the current script or user function and come back to debug mode for the command after the one that sourced or called it.',
  \ })
endfunction

function! s:redir(cmd) abort
  let [save_verbose, save_verbosefile] = [&verbose, &verbosefile]
  set verbose=0 verbosefile=
  redir => res
    silent! execute a:cmd
  redir END
  let [&verbose, &verbosefile] = [save_verbose, save_verbosefile]
  return res
endfunction

function! s:Message.echon(hl, msg) abort
  execute 'echohl' a:hl
  try
    echon a:msg
  finally
    echohl None
  endtry
endfunction

