if exists('g:loaded_termp')
  finish
endif
let g:loaded_termp = 1

let s:popup_id = -1
let s:current_input = ''

function! termp#open() abort
  if s:popup_id != -1
    call popup_close(s:popup_id)
  endif

  let width  = float2nr(&columns * 0.6)
  let height = float2nr(&lines   * 0.6)
  let line   = (&lines   - height) / 2
  let col    = (&columns - width)  / 2

  let s:popup_id = popup_create([], {
        \ 'line': line,
        \ 'col': col,
        \ 'minwidth': width,
        \ 'minheight': height,
        \ 'border': [1,1,1,1],
        \ 'borderchars': ['─','│','─','│','┌','┐','┘','└'],
        \ 'title': ' termp ',
        \ 'wrap': v:true,
        \ 'mapping': 0,
        \ 'filter': 'termp#filter',
        \ 'callback': 'termp#close_cb'
        \ })

  let s:log = ['Type a shell command and press <Enter>.',
        \ 'Type "clear" to reset, "exit" to close.',
        \ '',
        \ '> ']
  call popup_settext(s:popup_id, s:log)
endfunction

function! termp#filter(id, key) abort
  if a:key ==# "\<CR>"
    if s:current_input ==# 'exit'
      call popup_close(a:id)
      let s:popup_id = -1
      return 1
    elseif s:current_input ==# 'clear'
      let s:log = ['Type a shell command and press <Enter>.',
            \ 'Type "clear" to reset, "exit" to close.',
            \ '', '> ']
      let s:current_input = ''
      call popup_settext(a:id, s:log)
      return 1
    elseif s:current_input !=# ''
      call termp#run(a:id, s:current_input)
      let s:current_input = ''
      return 1
    endif
  elseif a:key ==# "\<Esc>" || a:key ==# "\<C-c>"
    call popup_close(a:id)
    let s:popup_id = -1
    return 1
  elseif a:key ==# "\<BS>"
    if len(s:current_input) > 0
      let s:current_input = s:current_input[:-2]
      call termp#redraw()
    endif
    return 1
  elseif a:key =~ '^[ -~]$'
    let s:current_input .= a:key
    call termp#redraw()
    return 1
  endif
  return 0
endfunction

function! termp#run(id, cmd) abort
  let out = systemlist(a:cmd)
  if v:shell_error
    call add(out, '[exit code: ' . v:shell_error . ']')
  endif
  call extend(s:log, ['$ ' . a:cmd] + out + ['> '])
  call popup_settext(a:id, s:log)
endfunction

function! termp#redraw() abort
  let s:log[-1] = '> ' . s:current_input
  call popup_settext(s:popup_id, s:log)
endfunction

function! termp#close_cb(id, result) abort
  let s:popup_id = -1
  let s:current_input = ''
endfunction
