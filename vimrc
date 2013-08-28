"
" Colors
"
colorscheme solarized
set background=dark " For solarized
syntax on
"export TERM="xterm-256colors" " config for solarized theme in terminal

" Set font
set guifont=Inconsolata:h16

" make vim NOT pretend to be like vi
set nocompatible

" Highlights the 81st column
set colorcolumn=81

"
" vundle config
"
filetype off " required!
set rtp+=~/.vim/bundle/vundle/
call vundle#rc()

" Include bundles in different file
if filereadable(expand("~/.vimrc.bundles"))
  source ~/.vimrc.bundles
endif

" Treat JSON files like JavaScript
au BufRead,BufRead *.json set ft=javascript


" Use F2 button to toggle input paste
set pastetoggle=<F2>

set history=1000    " save 1000 points of history
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

" Pathogen
call pathogen#infect()

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

"
" CloseTag Config
"
autocmd FileType html,erb let b:closetag_html_style=1
autocmd FileType html,xml,erb source ~/.vim/bundle/closetag/plugin/closetag.vim

"
" CtrlP
"
set runtimepath^=~/.vim/bundle/ctrlp.vim

" Local config
if filereadable($HOME . "/.vimrc.local")
  source ~/.vimrc.local
endif
