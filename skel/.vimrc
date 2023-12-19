" .vimrc

" (c) 2017-2023 George Georgalis <george@galis.org> unlimited use with this notice

" I know not using ascii is going to hurt, but binary txt files already hurts
"set fileencoding=utf8
"set encoding=utf8
"set termencoding=utf8
" :e! ++enc=utf8
" :e! ++enc=ascii

set timeout timeoutlen=3000 ttimeoutlen=100
set timeout timeoutlen=1000 ttimeoutlen=100
"set noesckeys

" https://linuxhandbook.com/vim-auto-complete/

" zm zr foldmethod=indent foldmethod=syntax foldlevel=20
" %  jump to matching ([{}]), start/end of C-style comment, preprocessor conditional, code block

"  ]s  [s :: fwd and back move to a misspelled word
"  z= :: get suggestions
"  zg :: add word to dictionary
"  zw :: mark word incorrect
setlocal nospell
set spelllang=en_us

set nocompatible
set modelines=0 " prior to 6.3.83, modelines could could execute arbitrary commands
set noautoindent
set textwidth=0	" wrap with cr @ n cols
set viminfo='80,\"200	" read/write a .viminfo file
set history=350
set suffixes=.bak,~,.swp,.o,.info,.aux,.log,.dvi,.bbl,.blg,.brf,.cb,.ind,.idx,.ilg,.inx,.out,.toc,.rpm,.z,.Z,.tar,.gz,.tgz,.zip,.bz2,.deb
set showcmd		" Show (partial) command in status line.
set showmatch	" Show matching brackets.
set ignorecase	" Do case insensitive matching
set smartcase	" Only ignorecase when no caps in search
set incsearch	" Incremental search
set ttyfast
set hlsearch
set sidescroll=20
set scrolloff=48	
set mouse=a     " helps, and no problems
set wrap	" so longlines are visible
"set nowrap	" can be better
set nolbr   " better for copying
"set lbr	" wrap on word, for editing text
set expandtab " prefer spaces, use ctrl-v tab for tab-character
set tabstop=4 " 4 characters better than 8
"set shiftwidth=4
"set backspace=2
set backspace=indent,eol,start
set nobackup " Preserves multi links cf 'vip' 'vim in place'
"set backupcopy=yes 
"set backupskip=/tmp/crontab*
set ruler		" show the cursor position all the time
set laststatus=2
set statusline=%<%f%h%m%r%=%{strftime(\"%D\ %l:%M:%S\ \%p,\ %a\ %b\ %d,\ %Y\")}\ %{&ff}\ %l,%c%V\ %P
set statusline=%<%f%h%m%r%=%{strftime(\"%a\ %D\ %l:%M\ \%p,\")}\ %{&ff}\ %l,%c\ %P

"set autowrite 		"Write the contents of the file, if it has been modified, on each :next, :rewind, :last, :first, :previous, :stop, :suspend, :tag, :!, :make, CTRL-] and CTRL-^ command; and when a :buffer, CTRL-O, CTRL-I, '{A-Z0-9}, or `{A-Z0-9} command takes one to another file.

if has("autocmd")
  " When editing a file, always jump to the last known cursor position.
  " Don't do it when the position is invalid or when inside an event handler
  " (happens when dropping a file into gvim).
  autocmd BufReadPost *
    \ if line("'\"") > 0 && line("'\"") <= line("$") |
    \   exe "normal g`\"" |
    \ endif
endif " has("autocmd")

map <f1> {!}par 1600<CR>
map <F2> {!}par 52<CR>
map <F3> {!}par 66<CR>
map <F4> {!}par 94<CR>

""  http://www.rayninfo.co.uk/vimtips.html/
""  ----------------------------------------
""  '.               : jump to last modification line (SUPER)
""  `.               : jump to exact spot in last modification line
""  <C-O>            : retrace your movements in file (starting from most recent)
""  <C-I>            : retrace your movements in file (reverse diection)
""  :ju(mps)         : list of your movements
""  :help jump-motions
""  :history         : list of all your commands
""  :his c           : commandline history
""  :his s           : search history
""  q/               : Search history Window
""  q:               : commandline history Window
""  :<C-F>           : history Window
""  ----------------------------------------

" Function to source only if file exists
function! SourceIfExists(file)
  if filereadable(expand(a:file))
    exe 'source' a:file
    endif
  endfunction

call SourceIfExists("~/.vim-color.vim")
call SourceIfExists("~/.vimrc.local")

