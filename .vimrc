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
" show statusline when multiple windows opened (:he laststatus)
set laststatus=1
" set height of commandline
set cmdheight=1
" コマンドをステータス行に表示
set showcmd
" タイトルを表示
set title
set background=dark
colorscheme codedark

highlight Normal ctermbg=none
highlight NonText ctermbg=none
highlight LineNr ctermbg=none
highlight Folded ctermbg=none
highlight EndOfBuffer ctermbg=none 
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
" 検索時に大文字小文字を無視 (noignorecase:無視しない)
set ignorecase
" 大文字小文字の両方が含まれている場合は大文字小文字を区別
set smartcase
" enable matchit
source $VIMRUNTIME/macros/matchit.vim
let b:match_words = "<ol>:</ol>"

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
" prohibit allowline
noremap <Up> <Nop>
noremap <Down> <Nop>
noremap <Left> <Nop>
noremap <Right> <Nop>

" ------------------------------------------------------------------------
"   settings of NERDTree (won't work)
" ------------------------------------------------------------------------
function! NERDTreeHighlightFile(extension, fg, bg, guifg, guibg)
  exec 'autocmd FileType nerdtree highlight ' . a:extension .' ctermbg='. a:bg .' ctermfg='. a:fg .' guibg='. a:guibg .' guifg='. a:guifg
  exec 'autocmd FileType nerdtree syn match ' . a:extension .' #^\s\+.*'. a:extension .'$#'
endfunction
call NERDTreeHighlightFile('md', 'blue', 'none', '#3366FF', '#151515')
call NERDTreeHighlightFile('json', 'yellow', 'none', 'yellow', '#151515')
call NERDTreeHighlightFile('html', 'yellow', 'none', 'yellow', '#151515')
call NERDTreeHighlightFile('css', 'cyan', 'none', 'cyan', '#151515')
call NERDTreeHighlightFile('scss', 'green', 'none', 'green', '#151515')
call NERDTreeHighlightFile('js', 'Red', 'none', '#ffa500', '#151515')
call NERDTreeHighlightFile('php', 'Magenta', 'none', '#ff00ff', '#151515')

" ------------------------------------------------------------------------
"   settings of neocomplete
" ------------------------------------------------------------------------
" Use neocomplete.
let g:neocomplete#enable_at_startup = 1
" Set minimum syntax keyword length.
let g:neocomplete#sources#syntax#min_keyword_length = 3

" ------------------------------------------------------------------------
"   settings of easymotion
" ------------------------------------------------------------------------
let mapleader = "\<Space>"
" ------------------------------------------------------------------------
"   other
" ------------------------------------------------------------------------
set mouse-=a

let g:ale_fixers = {'javascript': ['prettier', 'eslint']}
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
call dein#add('posva/vim-vue')
call dein#add('yegappan/grep')
call dein#add('Lokaltog/vim-powerline')
call dein#add('itchyny/lightline.vim')
call dein#add('Shougo/neocomplete.vim')
call dein#add('Lokaltog/vim-easymotion')

" below 3 lines are essential
call dein#end()
filetype plugin indent on
syntax enable

" install plugins
if dein#check_install()
  call dein#install()
endif
" ------------------------------------------------------------------------
