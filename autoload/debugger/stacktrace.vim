let s:V = vital#of('debugger')

" v:throwpoint example
" - function Test_gfunc[2]..<SNR>366_test_sfunc[2]..781, line 3
" - /home/haya14busa/.cache/junkfile/2016/01/2016-01-17-053123.vim, line 34
" - function 786, line 3
function! debugger#stacktrace#report(throwpoint) abort
  if a:throwpoint =~# '^\%(Error detected while processing \)\=function\s'
    let report = s:build_func_report(a:throwpoint)
    call s:create_buffer('==ErrorReport==.vim')
    call s:draw_report(report, ['" throwpoint: ' . a:throwpoint, ''])
    return report
  endif
endfunction

function! s:build_func2line(func_with_line_list) abort
  return map(copy(a:func_with_line_list), 's:parse_funcreport(v:val)')
endfunction

" @param {list<{'funcname': {string}, 'line': {number}}>} func2lines
function! s:build_func_report(throwpoint) abort
  let throwpoint = substitute(a:throwpoint, '^\%(Error detected while processing \)\=function\s', '', '')
  let throwpoint = substitute(throwpoint, '\m\%(, \|:\s\+\)line\s\+\(\d\+\):\=$', '[\1]', '')
  let report = []
  for func2line in s:build_func2line(split(throwpoint, '\m\.\.'))
    let report += [extend(copy(func2line), {'func': s:build_func(func2line.funcname)})]
  endfor
  return report
endfunction

function! s:build_func(funcname) abort
  let name = s:is_dict_func(a:funcname) ? printf('{%d}', a:funcname) : a:funcname
  if !exists('*' . name)
    throw 'function undefined: ' . name
  endif
  let funclines = split(s:redir(':verbose function ' . name), "\n")
  let last_set = funclines[1]
  call remove(funclines, 1)
  return {'lines': funclines, 'last_set': last_set}
endfunction

function! s:is_dict_func(funcname) abort
  return a:funcname =~# '^\d\+$'
endfunction

" @param {string} funcreport
"   {funcname}[{lnum}]
function! s:parse_funcreport(funcreport) abort
  let matches = matchlist(a:funcreport, '\m^\(.\{-}\)\[\(\d\+\)\]')
  return {
  \   'funcname': matches[1],
  \   'line': str2nr(matches[2])
  \ }
endfunction

function! s:create_buffer(name, ...) abort
  let open_cmd = get(a:, 1, 'belowright new')
  execute open_cmd printf("`='%s'`", a:name)
  1,$ delete
  setlocal buftype=nowrite
  setlocal noswapfile
  setlocal bufhidden=wipe
  setlocal buftype=nofile
  setlocal nonumber
  setlocal filetype=vim
endfunction

" @param {list<{func: {lines: list<string>, last_set: {string}}, funcname: {string}, line: {number}}>} report
function! s:draw_report(report, ...) abort
  let head = get(a:, 1, [])
  let [lines, hl_lnums] = s:report_to_text(a:report, head)
  put! =lines
  :0
  syntax match Error containedin=ALL /^->\d\+/
  redraw
endfunction

function! s:report_to_text(report, ...) abort
  let head = get(a:, 1, [])
  let lines = copy(head)
  let lnum = len(lines) + 1
  let hl_lnums = []
  for funcreport in a:report
    let lines += ['" ' . funcreport.func.last_set]
    let hl_lnum_offset = 1
    for l in funcreport.func.lines
      let func_lnum = matchstr(l, '^\s*\zs\d\+\ze\s\s')
      let prefix = func_lnum ==# funcreport.line ? '->' : '  '
      if func_lnum ==# funcreport.line
        let hl_lnums += [lnum + hl_lnum_offset]
      endif
      let lines += [prefix . l]
      let hl_lnum_offset += 1
    endfor
    let lines += ['']
    let lnum += len(funcreport.func.lines) + 2
  endfor
  return [lines, hl_lnums]
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

let s:reports = {}

function! debugger#stacktrace#callstack(...) abort
  let id = get(a:, 1, '0')
  let id = id is# '' ? '0' : id
  let sfile = substitute(expand('<sfile>'), '\m\.\.[^.]\{-}debugger#stacktrace#callstack$', '', '')
  let report = s:build_func_report(sfile)
  let s:reports[id] = report
  return report
endfunction

function! debugger#stacktrace#callstackreport(...) abort
  let id = get(a:, 1, '0')
  let id = id is# '' ? '0' : id
  let report = s:reports[id]
  call s:create_buffer(printf('==CallStack: %s==.vim', id))
  call s:draw_report(report, ['" callstack: ' . id, ''])
endfunction
