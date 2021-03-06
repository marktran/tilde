" .vimrc : Mark Tran <mark.tran@gmail.com>

" vim expects a POSIX-compatible underlying shell
set shell=/bin/sh

set nocompatible
set incsearch
set showmode
set nowrap
set textwidth=79
set viminfo='50,\"1000,:100,n~/.vim/viminfo
set noeol

set noerrorbells
set visualbell
autocmd VimEnter * set vb t_vb=

set expandtab
set shiftwidth=2
set tabstop=2
set cindent
set cinkeys=0{,0},0),:,!^F,o,O
set cinoptions=(0t0c

set ruler
set showcmd
set showmatch
set ignorecase
set smartcase
set notitle
set nolist
set nonumber

set matchpairs+=<:>
set complete=.,w,b,i,t,u
set backspace=indent,eol,start
set formatoptions=tcrqn
set comments=b:#,ex:/*,f://,mb:*,s1:/*

set noswapfile
set nobackup

let mapleader = ","

filetype off
filetype plugin indent on
