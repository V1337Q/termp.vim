if exists('g:loaded_termp')
  finish
endif
let g:loaded_termp = 1

let s:popup_id = -1
let s:current_input = ''

function! s:SetupHighlights()
  "Didn't know if this actually works. But imma push anyway. 
    let normal_bg = synIDattr(synIDtrans(hlID("Normal")), "bg#")
    let normal_fg = synIDattr(synIDtrans(hlID("Normal")), "fg#")
    let comment_fg = synIDattr(synIDtrans(hlID("Comment")), "fg#")
    let constant_fg = synIDattr(synIDtrans(hlID("Constant")), "fg#")
    
    let title_color = empty(constant_fg) ? (empty(normal_fg) ? '#87CEEB' : normal_fg) : constant_fg
    let border_color = empty(comment_fg) ? (empty(normal_fg) ? '#666666' : normal_fg) : comment_fg
    let bg_color = empty(normal_bg) ? 'NONE' : normal_bg
    let text_color = empty(normal_fg) ? '#FFFFFF' : normal_fg
    
    execute 'highlight TermPopupTitle guifg=' . title_color . ' gui=bold'
    execute 'highlight TermPopupBorder guifg=' . border_color
    execute 'highlight TermPopupBg guibg=' . bg_color . ' guifg=' . text_color
endfunction

function! termp#open() abort
  if s:popup_id != -1
    call popup_close(s:popup_id)
  endif

  call s:SetupHighlights()

  let width  = float2nr(&columns * 0.6)
  let height = float2nr(&lines   * 0.6)
  let line   = (&lines   - height) / 2
  let col    = (&columns - width)  / 2
  let toptitle    = '  termp '
  let user_directory = expand('~')
  let full_title = toptitle . '   ' . user_directory

  let s:popup_id = popup_create([], {
        \ 'line': line,
        \ 'col': col,
        \ 'minwidth': width,
        \ 'minheight': height,
        \ 'border': [1,1,1,1],
        \ 'borderchars': ['─','│','─','│','┌','┐','┘','└'],
        \ 'title': full_title,
        \ 'wrap': v:true,
        \ 'mapping': 0,
        \ 'filter': 'termp#filter',
        \ 'callback': 'termp#close_cb',
        \ 'highlight': 'TermPopupBg',
        \ 'borderhighlight': ['TermPopupBorder'],
        \ 'titlehighlight': ['TermPopupTitle']
        \ })

  let s:prompt = '󰊠  '
  let s:log = ['Type a shell command and press <Enter>.',
        \ 'Type "clear" to reset, "exit" or <C-c> to close.',
        \ '',
        \ s:prompt]
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
            \ 'Type "clear" to reset, "exit" or <C-c> to close.',
            \ '', s:prompt]
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
  call extend(s:log, ['$ ' . a:cmd] + out + [s:prompt])
  call popup_settext(a:id, s:log)
endfunction

function! termp#redraw() abort
  let s:log[-1] = s:prompt . s:current_input
  call popup_settext(s:popup_id, s:log)
endfunction

function! termp#close_cb(id, result) abort
  let s:popup_id = -1
  let s:current_input = ''
endfunction
