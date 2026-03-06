" Show relative line numbers
set relativenumber
" Show current line number
set number

" Set modal cursor for xterm-compatible terminals
if &term =~ '^xterm'
    " 0 or 1 -> blinking block
    " 2 -> solid block
    " 3 -> blinking underscore
    " 4 -> solid underscore
    " 5 -> blinking vertical bar
    " 6 -> solid vertical bar
    let &t_EI = "\<Esc>[2 q"
    let &t_SI = "\<Esc>[6 q"
    let &t_SR = "\<Esc>[4 q"
endif

" Use space as the leader key
nnoremap <SPACE> <Nop>
let mapleader=" "

" Enable CamelCaseMotion plugin
let g:camelcasemotion_key = '<leader>'
