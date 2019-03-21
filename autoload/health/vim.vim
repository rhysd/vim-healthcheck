if has('nvim')
    finish
endif

let s:path_sep = has('win32') || has('win64') ? '\' : '/'

function! s:VIM_is_correct() abort
    " 800 -> 80, 801 -> 81, 1201 -> 121
    let v = v:version[:-3] . v:version[-1:]
    let candidates = [
    \   [$VIM, 'runtime', 'doc', 'usr_01.txt'],
    \   [$VIM, 'vim' . v, 'doc', 'usr_01.txt'],
    \ ]
    for entries in candidates
        if filereadable(join(entries, s:path_sep))
            return v:true
        endif
    endfor
    return v:false
endfunction

function! s:check_config() abort
    let ok = v:true
    call health#report_start('Configuration')

    if !s:VIM_is_correct()
        let ok = v:false
        call health#report_error('$VIM is invalid: ' . $VIM, [
        \   'Read `:help $VIM` and set $VIM properly.',
        \   'Remove config to set $VIM manually.',
        \])
    endif

    if &paste
        let ok = v:false
        call health#report_error("'paste' is enabled. This option is only for pasting text.\nIt should not be set in your config.", [
        \   'Remove `set paste` from your vimrc, if applicable.',
        \   'Check `:verbose set paste?` to see if a plugin or script set the option.',
        \])
    endif

    if ok
        call health#report_ok('no issues found')
    endif
endfunction

" Port of s:check_tmux() in health/nvim.vim
function! s:check_tmux() abort
  if empty($TMUX) || !executable('tmux')
    return
  endif
  call health#report_start('tmux')

  " check escape-time
  let advice = "Set escape-time in ~/.tmux.conf:\nset-option -sg escape-time 10"
  let cmd = 'tmux show-option -qvgs escape-time'
  let out = system(cmd)
  let tmux_esc_time = substitute(out, '\v(\s|\r|\n)', '', 'g')
  if v:shell_error
    call health#report_error('command failed: '.cmd."\n".out)
  elseif empty(tmux_esc_time)
    call health#report_error('escape-time is not set', advice)
  elseif tmux_esc_time > 300
    call health#report_error(
        \ 'escape-time ('.tmux_esc_time.') is higher than 300ms', advice)
  else
    call health#report_ok('escape-time: '.tmux_esc_time.'ms')
  endif

  " check default-terminal and $TERM
  call health#report_info('$TERM: '.$TERM)
  let cmd = 'tmux show-option -qvg default-terminal'
  let out = system(cmd)
  let tmux_default_term = substitute(out, '\v(\s|\r|\n)', '', 'g')
  if empty(tmux_default_term)
    let cmd = 'tmux show-option -qvgs default-terminal'
    let out = system(cmd)
    let tmux_default_term = substitute(out, '\v(\s|\r|\n)', '', 'g')
  endif

  if v:shell_error
    call health#report_error('command failed: '.cmd."\n".out)
  elseif tmux_default_term !=# $TERM
    call health#report_info('default-terminal: '.tmux_default_term)
    call health#report_error(
          \ '$TERM differs from the tmux `default-terminal` setting. Colors might look wrong.',
          \ ['$TERM may have been set by some rc (.bashrc, .zshrc, ...).'])
  elseif $TERM !~# '\v(tmux-256color|screen-256color)'
    call health#report_error(
          \ '$TERM should be "screen-256color" or "tmux-256color" in tmux. Colors might look wrong.',
          \ "Set default-terminal in ~/.tmux.conf:\nset-option -g default-terminal \"screen-256color\"")
  endif
endfunction


function! health#vim#check() abort
    call s:check_config()
    call s:check_tmux()
endfunction
