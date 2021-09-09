" Set font
set guifont=Inconsolata:h16

" make vim NOT pretend to be like vi
set nocompatible

" Highlights the 81st column
set colorcolumn=81

" Treat JSON files like JavaScript
au BufRead,BufRead *.json set ft=javascript


" Use F2 button to toggle input paste
set pastetoggle=<F2>

" save 1000 points of history
set history=1000

set hidden

" Show matching brackets and parenthesis
set showmatch

"
" Whitespace
"
set nowrap        " don't wrap long lines
set tabstop=2     " tab is 2 spaces
set shiftwidth=2  " an autoindent (with <<) is two spaces

set expandtab     " use spaces, not tabs
set smarttab      " smart handling of the Tab key (what it does, not sure)

set autoindent    " auto-indent new lines
set copyindent    " auto-indent copied text

" Automatically remove trailing whitespace on save
autocmd BufWritePre * :%s/\s\+$//e

" Set terminal title with filename
set title

" Shut up, vim!
set noerrorbells
set visualbell

" Fix backspace indentation
set backspace=indent,eol,start

" Set persistent undo (v7.3 only)
set undodir=~/.vim/undodir
set undofile

"
" Searching
"
set hlsearch    " highlight matches
set incsearch   " incremental searching
set ignorecase  " searches are case insensitive...
set smartcase   " ... unless they contain at least one capital letter
" clear search highlight on //
map // :nohl<CR>

set number     " line numbers
set mouse=a

" Turn off annoying swapfiles
set noswapfile
set nobackup
set showcmd
set autoread
set showmode    " show what mode you are in

"
" Encoding
"
set fenc=utf8
set enc=utf8

" Show crosshairs
set cursorline
set cursorcolumn

" Open new split panes to right and bottom, which feels more natural
set splitbelow
set splitright

""""""""""""
" Shortcuts
""""""""""""

" Cycle between windows with tab
map <Tab> <C-W>w

" Comment
map <leader>c <c-_><c-_>

" Map KJ shortcut to ESC
inoremap kj <Esc>

" Reload vimrc
map rvimrc :source $MYVIMRC

"""""""""""
" Plug plugins
"""""""""""

" Specify a directory for plugins
" - For Neovim: stdpath('data') . '/plugged'
" - Avoid using standard Vim directory names like 'plugin'
call plug#begin('~/.vim/plugged')

" Make sure you use single quotes

Plug 'sainnhe/sonokai'

" Plugin outside ~/.vim/plugged with post-update hook
Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all' }

" Initialize plugin system
call plug#end()

""""""""""""""
" Color theme
""""""""""""""

" Important!!
if has('termguicolors')
  set termguicolors
endif

" The configuration options should be placed before `colorscheme sonokai`.
let g:sonokai_style = 'atlantis'
let g:sonokai_enable_italic = 1
let g:sonokai_disable_italic_comment = 1
let g:sonokai_cursor = 'red'
let g:sonokai_current_word = 'bold'
colorscheme sonokai

""""""""""

" Local config
if filereadable($HOME . "/.vimrc.local")
  source ~/.vimrc.local
endif

