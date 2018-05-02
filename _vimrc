scriptencoding utf-8
" vim:set ts=8 sts=2 sw=2 tw=0: (この行に関しては:help modelineを参照)
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
" ルーラーを表示 (noruler:非表示)
set ruler
" タブや改行を表示 (list:表示)
set nolist
" どの文字でタブや改行を表示するかを設定
set listchars=tab:>-,extends:<,trail:-,eol:<
" 長い行を折り返して表示 (nowrap:折り返さない)
set wrap
" 常にステータス行を表示 (詳細は:he laststatus)
set laststatus=2
" コマンドラインの高さ (Windows用gvim使用時はgvimrcを編集すること)
set cmdheight=2
" コマンドをステータス行に表示
set showcmd
" タイトルを表示
set title

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
"htmlのタグ閉じ
let g:loadedInsertTag = 1

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
" C-n to NERDTree
map <C-n> :NERDTreeToggle<CR>

" ------------------------------------------------------------------------
"   dein
" ------------------------------------------------------------------------
" dein path settings
let s:dein_dir = fnamemodify('~/vim/dein/', ':p') "<-お好きな場所
let s:dein_repo_dir = s:dein_dir . 'repos/github.com/Shougo/dein.vim' "<-固定

" dein.vim本体の存在チェックとインストール
if !isdirectory(s:dein_repo_dir)
    execute '!git clone https://github.com/Shougo/dein.vim' shellescape(s:dein_repo_dir)
endif

" dein.vim本体をランタイムパスに追加
if &runtimepath !~# '/dein.vim'
    execute 'set runtimepath^=' . s:dein_repo_dir
endif

" essential
call dein#begin(s:dein_dir)
call dein#add('Shougo/neocomplcache')

" packages
call dein#add('mattn/emmet-vim')
call dein#add('scrooloose/nerdtree')
call dein#add('bronson/vim-visual-star-search')

" below 3 lines are essential
call dein#end()
filetype plugin indent on
syntax enable

" install plugins
if dein#check_install()
  call dein#install()
endif
" ------------------------------------------------------------------------
