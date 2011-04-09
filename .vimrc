" .vimrc : Mark Tran <mark@nirv.net>

syntax on

set nocompatible
set incsearch
set showmode
set nowrap
set textwidth=79
set viminfo='50,\"1000,:100,n~/.vim/viminfo

set noerrorbells
set visualbell
autocmd VimEnter * set vb t_vb=

set expandtab
set shiftwidth=4
set tabstop=4
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
set number

set matchpairs+=<:>
set complete=.,w,b,i,t,u
set backspace=indent,eol,start
set formatoptions=tcrqn
set comments=b:#,ex:/*,f://,mb:*,s1:/*

filetype plugin on
filetype on

autocmd BufRead,BufNewFile /tmp/mutt-* set tw=72|set nocindent
inoremap kj <Esc>

hi LineNr ctermfg=darkmagenta
hi Comment ctermfg=darkgreen
hi Special ctermfg=darkred
hi Constant ctermfg=darkgreen
hi Identifier ctermfg=black
hi MatchParen ctermbg=white ctermfg=black
hi NonText ctermfg=black
hi PreProc ctermfg=none
hi Type ctermfg=yellow
hi Statement ctermfg=darkmagenta
hi Visual ctermbg=black ctermfg=white
