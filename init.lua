vim.o.encoding = 'utf-8'
vim.o.fenc = 'utf-8'
vim.scriptencoding = 'utf-8'

-- neovide settings
vim.g.neovide_window_blurred = false
vim.g.neovide_opacity = 0.8

-- visual settings
vim.syntax = 'enable'
vim.o.title = true
vim.o.relativenumber = true
vim.o.wrap = true
vim.o.wildmenu = true
vim.o.showcmd = true
vim.o.list = true
vim.o.listchars = 'tab:▸ ,trail:·,nbsp:␣,extends:>,precedes:<,eol:↲'

-- edit settings
vim.o.expandtab = true -- Tab文字を半角スペースにする
vim.o.shiftwidth = 4 -- 行頭でのTab文字の表示幅
vim.o.tabstop = 4 -- タブの画面上での幅
vim.o.smartindent = true
vim.o.showmatch = true
vim.o.matchtime = 1 -- カーソルを合わせたときに括弧をハイライトする時間
vim.o.backspace = 'indent,eol,start' -- バックスペースで削除できる範囲

-- search settings
vim.o.wrapscan = true -- 検索時にファイルの最後まで行ったら最初に戻る
vim.o.incsearch = true -- 検索時にリアルタイムで結果を表示
vim.o.hlsearch = true -- 検索結果をハイライト表示
vim.o.ignorecase = true -- 検索時に大文字小文字を区別しない
vim.o.smartcase = true -- 検索時に大文字が含まれていたら大文字小文字を区別する

-- other
vim.o.mouse = 'a' -- enable mouse (選択・右クリックメニュー)
vim.o.clipboard = 'unnamedplus' -- yank/paste をシステムクリップボードと共有
vim.o.backup = false
vim.o.swapfile = false
vim.o.undofile = false

-- enable
vim.api.nvim_set_keymap('!', '<D-v>', '<C-R>+', { noremap = true, silent = true})
vim.api.nvim_set_keymap('n', '<D-v>', '"+p', { noremap = true, silent = true})
vim.api.nvim_set_keymap('v', '<D-v>', '"+P', { noremap = true, silent = true})
-- Cmd+C でビジュアル選択をコピー
vim.api.nvim_set_keymap('v', '<D-c>', '"+y', { noremap = true, silent = true})
-- double esc to clear highlights
vim.api.nvim_set_keymap('n', '<Esc><Esc>', ':nohlsearch<CR>', { noremap = true, silent = true})
-- jj to esc
vim.api.nvim_set_keymap('i', 'jj', '<Esc>', { noremap = true, silent = true})
vim.api.nvim_set_keymap('n', 'x', '_x', { noremap = true, silent = true})
-- prohibit arrow keys
vim.api.nvim_set_keymap('n', '<Up>', '<Nop>', { noremap = true, silent = true})
vim.api.nvim_set_keymap('n', '<Down>', '<Nop>', { noremap = true, silent = true})
vim.api.nvim_set_keymap('n', '<Left>', '<Nop>', { noremap = true, silent = true})
vim.api.nvim_set_keymap('n', '<Right>', '<Nop>', { noremap = true, silent = true})

-- plugins (vim-plug)
local Plug = vim.fn['plug#']
vim.call('plug#begin')
Plug('github/copilot.vim')
Plug('nvim-lualine/lualine.nvim')
Plug('EdenEast/nightfox.nvim')
vim.call('plug#end')

require('lualine').setup()

-- load config from init.vim
vim.cmd('set formatoptions+=mM') -- テキスト挿入中の自動折り返しを日本語に対応させる
-- vim.cmd('source ~/.config/nvim/init.vim')
vim.cmd("colorscheme nightfox")
