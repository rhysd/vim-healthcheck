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
let s:suggest_faq = 'https://github.com/neovim/neovim/wiki/FAQ'
function! s:get_tmux_option(option) abort
    let cmd = 'tmux show-option -qvg '.a:option  " try global scope
    let out = system(cmd)
    let val = substitute(out, '\v(\s|\r|\n)', '', 'g')
    if v:shell_error
        call health#report_error('command failed: '.cmd."\n".out)
        return 'error'
    elseif empty(val)
        let cmd = 'tmux show-option -qvgs '.a:option  " try session scope
        let out = system(cmd)
        let val = substitute(out, '\v(\s|\r|\n)', '', 'g')
        if v:shell_error
            call health#report_error('command failed: '.cmd."\n".out)
            return 'error'
        endif
    endif
    return val
endfunction
function! s:check_tmux() abort
    if empty($TMUX) || !executable('tmux')
        return
    endif
    call health#report_start('tmux')

    " check escape-time
    let suggestions = ["set escape-time in ~/.tmux.conf:\nset-option -sg escape-time 10",
                \ s:suggest_faq]
    let tmux_esc_time = s:get_tmux_option('escape-time')
    if tmux_esc_time !=# 'error'
        if empty(tmux_esc_time)
            call health#report_error('`escape-time` is not set', suggestions)
        elseif tmux_esc_time > 300
            call health#report_error(
                        \ '`escape-time` ('.tmux_esc_time.') is higher than 300ms', suggestions)
        else
            call health#report_ok('escape-time: '.tmux_esc_time)
        endif
    endif

    " check focus-events
    let suggestions = ["(tmux 1.9+ only) Set `focus-events` in ~/.tmux.conf:\nset-option -g focus-events on"]
    let tmux_focus_events = s:get_tmux_option('focus-events')
    call health#report_info('Checking stuff')
    if tmux_focus_events !=# 'error'
        if empty(tmux_focus_events) || tmux_focus_events !=# 'on'
            call health#report_warn(
                        \ "`focus-events` is not enabled. |'autoread'| may not work.", suggestions)
        else
            call health#report_ok('focus-events: '.tmux_focus_events)
        endif
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
                    \ ["Set default-terminal in ~/.tmux.conf:\nset-option -g default-terminal \"screen-256color\"",
                    \  s:suggest_faq])
    endif

    " check for RGB capabilities
    let info = system('tmux server-info')
    let has_tc = stridx(info, " Tc: (flag) true") != -1
    let has_rgb = stridx(info, " RGB: (flag) true") != -1
    if !has_tc && !has_rgb
        call health#report_warn(
                    \ "Neither Tc nor RGB capability set. True colors are disabled. |'termguicolors'| won't work properly.",
                    \ ["Put this in your ~/.tmux.conf and replace XXX by your $TERM outside of tmux:\nset-option -sa terminal-overrides ',XXX:RGB'",
                    \  "For older tmux versions use this instead:\nset-option -ga terminal-overrides ',XXX:Tc'"])
    endif
endfunction

" Port of s:check_peformance() in health/nvim.vim
function! s:check_performance() abort
    call health#report_start('Performance')

    " check for slow shell invocation
    let slow_cmd_time = 1.5
    let start_time = reltime()
    call system('echo')
    let elapsed_time = reltimefloat(reltime(start_time))
    if elapsed_time > slow_cmd_time
        call health#report_warn(
                    \ 'Slow shell invocation (took '.printf('%.2f', elapsed_time).' seconds).')
    else
        call health#report_ok('`echo` command took '.printf('%.2f', elapsed_time).' seconds.')
    endif
endfunction

function! health#vim#check() abort
    call s:check_config()
    call s:check_tmux()
    call s:check_performance()
endfunction
