if exists('g:loaded_healthcheck') || has('nvim')
    finish
endif
let g:loaded_healthcheck = 1

command -nargs=* -bar CheckHealth call health#check([<f-args>])
