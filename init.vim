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
" show statusline when multiple windows opened (:he laststatus)
set laststatus=2
" set height of commandline
set cmdheight=1
" コマンドをステータス行に表示
set showcmd
" タイトルを表示
set title
set background=dark

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
set smartindent
" バックスペースでインデントや改行を削除できるようにする
set backspace=indent,eol,start
" 括弧入力時に対応する括弧を表示 (noshowmatch:表示しない)
set showmatch
set matchtime=1
set completeopt=menuone
" 補完表示時のEnterで改行をしない
inoremap <expr><CR>  pumvisible() ? "<C-y>" : "<CR>"

augroup fileTypeIndent
  autocmd!
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
" 検索時に大文字小文字を無視 (noignorecase:無視しない)
set ignorecase
" 大文字小文字の両方が含まれている場合は大文字小文字を区別
set smartcase

"---------------------------------------------------------------------------
"   file settings
"---------------------------------------------------------------------------
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
" xでヤンク内容が消えないようにする
noremap x "_x
" insert時にjjでEsc
inoremap jj <Esc>
" prohibit allowline
noremap <Up> <Nop>
noremap <Down> <Nop>
noremap <Left> <Nop>
noremap <Right> <Nop>
" fzf.vim
nnoremap <C-p> :Files<CR>

" ------------------------------------------------------------------------
"   settings of lightline
" ------------------------------------------------------------------------
let g:lightline = {
    \ 'colorscheme': 'terafox',
    \ 'separator': { 'left': "\ue0b0", 'right': "\ue0b2" },
    \ 'subseparator': { 'left': "\ue0b1", 'right': "\ue0b3" }
\}

" ------------------------------------------------------------------------
"   settings of coc-nvim
" ------------------------------------------------------------------------
inoremap <expr> <cr> coc#pum#visible() ? coc#pum#confirm() : "\<CR>"
inoremap <expr> <Tab> coc#pum#visible() ? coc#pum#next(1) : "\<Tab>"
inoremap <expr> <S-Tab> coc#pum#visible() ? coc#pum#prev(1) : "\<S-Tab>"

" ------------------------------------------------------------------------
"   other
" ------------------------------------------------------------------------
set mouse-=a
set relativenumber

" ------------------------------------------------------------------------
"   vim-plug
" ------------------------------------------------------------------------
call plug#begin()
Plug 'EdenEast/nightfox.nvim'
Plug 'w0ng/vim-hybrid'
Plug 'itchyny/lightline.vim'
Plug 'neoclide/coc.nvim', {'branch': 'release'}
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'
call plug#end()

colorscheme terafox
