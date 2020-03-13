scriptencoding utf-8
set encoding=utf-8
set fenc=utf-8

"---------------------------------------------------------------------------
"   visual settings
"---------------------------------------------------------------------------
syntax enable
" 不可視文字を可視化(タブが「▸-」と表示される)
set list listchars=tab:\▸\-
" コマンドライン補完するときに強化されたものを使う(参照 :help wildmenu)
set wildmenu
" テキスト挿入中の自動折り返しを日本語に対応させる
set formatoptions+=mM
" 行番号を表示 
set number
" タブや改行を表示 (list:表示)
set nolist
" どの文字でタブや改行を表示するかを設定
set listchars=tab:>-,extends:<,trail:-,eol:<
" 長い行を折り返して表示 (nowrap:折り返さない)
set wrap
" always show statusline
set laststatus=2
" set height of commandline
set cmdheight=1
" コマンドをステータス行に表示
set showcmd
" タイトルを表示
set title
set background=dark
" colorscheme solarized
let g:airline#extensions#tabline#enabled = 1
let g:airline#extensions#tabline#buffer_idx_mode = 1
let g:airline_powerline_fonts = 1

"---------------------------------------------------------------------------
"   edit settings
"---------------------------------------------------------------------------
" Tab文字を半角スペースにする
set expandtab
" 行頭でのTab文字の表示幅
set shiftwidth=4
" タブの画面上での幅
set tabstop=4
" 自動的にインデントする (noautoindent:インデントしない)
set autoindent
set smartindent
" バックスペースでインデントや改行を削除できるようにする
set backspace=indent,eol,start
" 括弧入力時に対応する括弧を表示 (noshowmatch:表示しない)
set showmatch
set matchtime=1
augroup fileTypeIndent
  autocmd!
  autocmd BufNewFile,BufRead *.scss setlocal tabstop=2 softtabstop=2 shiftwidth=2
  autocmd BufNewFile,BufRead *.css setlocal tabstop=2 softtabstop=2 shiftwidth=2
augroup END

"---------------------------------------------------------------------------
"   search settings
"---------------------------------------------------------------------------
" 検索時にファイルの最後まで行ったら最初に戻る (nowrapscan:戻らない)
set wrapscan
" silent beep
set belloff=all
" 検索文字列入力時に順次対象文字列にヒットさせる
set incsearch
" 検索語をハイライト表示
set hlsearch
" 大文字小文字の両方が含まれている場合は大文字小文字を区別
set smartcase

"---------------------------------------------------------------------------
"   file settings
"---------------------------------------------------------------------------

" バックアップファイルを作成しない
"set directory=~/AppData/Local/Temp
"set backupdir=~/AppData/Local/Temp
"set undodir=~/AppData/Local/Temp
:set nobackup
:set noswapfile
:set noundofile


" --------------------------------------------------------------------------
"   mapping
" --------------------------------------------------------------------------
" double ESC to clear highlights
nmap <Esc><Esc> :nohlsearch<CR><Esc>
" 括弧の補完
inoremap {<Enter> {}<Left><CR><ESC><S-o>
inoremap [<Enter> []<Left><CR><ESC><S-o>
inoremap (<Enter> ()<Left><CR><ESC><S-o>
" xでヤンク内容が消えないようにする
noremap x "_x
" insert時にjjでEsc
inoremap jj <Esc>
"C-n to NERDTree
map <C-n> :NERDTreeToggle<CR>
" prohibit allowline
noremap <Up> <Nop>
noremap <Down> <Nop>
noremap <Left> <Nop>
noremap <Right> <Nop>

" ------------------------------------------------------------------------
"   settings of vim-lsp
" ------------------------------------------------------------------------
let g:lsp_settings_servers_dir='~/dotfiles/.servers'

" ------------------------------------------------------------------------
"   settings of deoplete
" ------------------------------------------------------------------------
" Use deoplete.
let g:deoplete#enable_at_startup = 1
" Set minimum syntax keyword length.
let g:deoplete#sources#syntax#min_keyword_length = 3

" ------------------------------------------------------------------------
"   other
" ------------------------------------------------------------------------
set mouse-=a

" ------------------------------------------------------------------------
"   dein
" ------------------------------------------------------------------------
call plug#begin('~/.local/share/nvim/plugged')
Plug 'vim-airline/vim-airline'
Plug 'scrooloose/nerdtree'
Plug 'mattn/emmet-vim'
Plug 'scrooloose/nerdtree'
Plug 'prabirshrestha/async.vim'
Plug 'prabirshrestha/vim-lsp'
Plug 'mattn/vim-lsp-settings'
Plug 'Shougo/deoplete.nvim'
call plug#end()
