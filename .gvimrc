scriptencoding utf-8
"---------------------------------------------------------------------------
" when insert mode change status line color
augroup InsertHook
autocmd!
autocmd InsertEnter * highlight StatusLine guifg=#ccdc90 guibg=#2E4340
autocmd InsertLeave * highlight StatusLine guifg=#2E4340 guibg=#ccdc90
augroup END

" load colorscheme
colorscheme codedark
set background=dark

" change guifont
if has('win32')
    set guifont=Ricty_diminished:h12:cSHIFTJIS:qDRAFT
    set rop=type:directx
endif

" set columns
set columns=200
" set lines
set lines=60
" set cmdheight
set cmdheight=1
" hide toolbar
set guioptions-=T
" hide menu
set guioptions-=m
" make transparent
" :set transparency=210
" autocmd GUIEnter * set transparency=230
" autocmd FocusGained * set transparency=230
" autocmd FocusLost * set transparency=128

" map gvim
map <C-Tab> gt
map <C-S-Tab> gT
