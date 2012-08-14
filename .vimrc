set background=dark
colorscheme solarized
set nocompatible
syntax on
filetype on
filetype plugin on
filetype indent on
set pastetoggle=<F2>
set history=1000
set hidden
set autoindent
set copyindent
set tabstop=2
set expandtab
set showmatch
set title
set noerrorbells
set backspace=indent,eol,start
set ignorecase
set smartcase
set smarttab
set hlsearch
set incsearch
set shiftwidth=2
set number
set mouse=a
set noswapfile
set nobackup
set visualbell
set noerrorbells
set showcmd
set autoread
set showmode
set fenc=utf8
set enc=utf8
inoremap kj <Esc>
set ruler

" shortcuts
map <leader>c <c-_><c-_>

set guifont=Inconsolata:h16

" Show crosshairs
set cursorline
set cursorcolumn

" Pathogen
call pathogen#infect()

" Cycle between windows with tab
map <Tab> <C-W>w
