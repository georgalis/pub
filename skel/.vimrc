" .vimrc

" Unlimited use with this notice. (C) 2017-2018 George Georgalis <george@galis.org>

set nocompatible
set modelines=0 " prior to 6.3.83, modelines could could execute arbitrary commands
set noautoindent
set textwidth=0	" wrap with cr @ n cols
set viminfo='80,\"200	" read/write a .viminfo file
set history=350
set suffixes=.bak,~,.swp,.o,.info,.aux,.log,.dvi,.bbl,.blg,.brf,.cb,.ind,.idx,.ilg,.inx,.out,.toc,.rpm,.z,.Z,.tar,.gz,.tgz,.zip,.bz2,.deb
set showcmd		" Show (partial) command in status line.
set showmatch		" Show matching brackets.
set ignorecase		" Do case insensitive matching
set smartcase		" Only ignorecase when no caps in search
set incsearch		" Incremental search
set ttyfast
set hlsearch
set sidescroll=20
set scrolloff=48	
set wrap	" so longlines are visible
"set nowrap	" can be better
set nolbr   " better for copying
"set lbr	" wrap on word, for text
set expandtab
set tabstop=4 " 4 characters sometimes better than 8
"set shiftwidth=4
"set backspace=2
set backspace=indent,eol,start
set nobackup " Preserves multi links cf 'vip' 'vim in place'
"set backupcopy=yes 
"set backupskip=/tmp/crontab*
set ruler		" show the cursor position all the time
set laststatus=2
" printf '%x' $(date '+%s')
set statusline=%<%f%h%m%r%=%{strftime(\"%D\ %l:%M:%S\ \%p,\ %a\ %b\ %d,\ %Y\")}\ %{&ff}\ %l,%c%V\ %P
set statusline=%<%f%h%m%r%=%{strftime(\"%a\ %D\ %l:%M\ \%p,\")}\ %{&ff}\ %l,%c\ %P
"set autowrite 		"Write the contents of the file, if it has been modified, on each :next, :rewind, :last, :first, :previous, :stop, :suspend, :tag, :!, :make, CTRL-] and CTRL-^ command; and when a :buffer, CTRL-O, CTRL-I, '{A-Z0-9}, or `{A-Z0-9} command takes one to another file.

if has("autocmd")
  " When editing a file, always jump to the last known cursor position.
  " Don't do it when the position is invalid or when inside an event handler
  " (happens when dropping a file on gvim).
  autocmd BufReadPost *
    \ if line("'\"") > 0 && line("'\"") <= line("$") |
    \   exe "normal g`\"" |
    \ endif
endif " has("autocmd")

"noremap <F8> :so `vimspell %`<CR>:!vimspell % -r<CR><CR>
map <f2> {!}par 1600<CR>
map <F3> {!}par 66<CR>
map <F4> {!}par 52<CR>
map <F5> :.!par 52<CR>
map <F8> :r !date "+\%D \%r"<cr>$a 
map <F9> :r! { date +\%Y\%m\%d_\%H\%M\%S_ && uuidgen ;} \| tr -d '\n' \| sed -e s/-.*// \| tr [A-Z] [a-z]	<CR>
"idnow () { sh -c "{ date '+%Y%m%d_%H%M%S_' && uuidgen ;} | tr -d '\n' | sed -e s/-.*// | tr '[A-Z]' '[a-z]'" ;} # dump local id
map <F10> :r! echo \| tai64n \| sed -e 's/^@[[:xdigit:]]\{8\}//' -e 's/[[:xdigit:]]\{8\} $//' <CR>

if &t_Co > 1
   syntax enable
endif
" use POSIX for shell highlighting
let g:is_posix= 1
set background=dark

" See ~/.Xdefaults

hi Comment	cterm=none	ctermfg=DarkCyan
hi Constant	cterm=underline	ctermfg=15
hi PreProc      cterm=none      ctermfg=6
hi Statement	cterm=none	ctermfg=3
hi Identifier	cterm=bold	ctermfg=8
hi Special	cterm=none	ctermfg=5
hi shDeref	cterm=none	ctermfg=7
hi shCmdSubRegion cterm=none	ctermfg=1

hi makeCommands cterm=none      ctermfg=7
hi makeComment	cterm=none	ctermfg=6
hi makeImplicit cterm=none	ctermfg=2
hi makeIdent	cterm=none	ctermfg=5
hi makeTarget	cterm=bold	ctermfg=3

"1 red
"2 green
"3 yellow
"4 blue
"5 megenta
"6 cyan
"7 8 9 10 11 12 13 white
"bold 10 11 12 13 white

" Highlight
"
"	term		attributes in a B&W terminal
"	cterm		attributes in a color terminal
"	ctermfg		foreground color in a color terminal
"	ctermbg		background color in a color terminal
"	gui		attributes in the GUI
"	guifg		foreground color in the GUI
"	guibg		background color in the GUI
"
"		cterm=none		ctermbg=	ctermfg=	gui=		guifg=		guibg=
"		bold,underline
"		reverse
"
"  0 Black	1 DarkBlue	2 DarkGreen	3 DarkCyan	4 DarkRed	5 DarkMagenta	6 Brown		7 Grey
"  8 DarkGrey	9 Blue		10 Green	11 Cyan		12 Red		13 LightMagenta	14 Yellow	15 White

"" some redefs of the default color syntax, good for dark
"" but makes very difficult with light background...
""set background=light
"
"hi Boolean cterm=none ctermbg=black ctermfg=LightGreen
"hi CommandSub cterm=none ctermbg=black  ctermfg=lightred
"hi Conditional cterm=none ctermbg=black  ctermfg=red
"hi Delimiter cterm=none ctermbg=black  ctermfg=darkred
"hi Delimiter cterm=none ctermbg=black ctermfg=LightGreen
"hi Directory cterm=none ctermbg=LightBlue ctermfg=white
"hi Identifier cterm=none ctermbg=black  ctermfg=DarkCyan
"hi ModeMsg cterm=none ctermbg=green  ctermfg=black
"hi Normal       ctermfg=Gray ctermbg=black
"hi PreProc cterm=none ctermbg=black  ctermfg=green
"hi Repeat cterm=none ctermbg=black  ctermfg=magenta
"hi Search cterm=reverse ctermbg=DarkBlue  ctermfg=LightCyan
"hi Statement cterm=none ctermbg=black  ctermfg=none
"hi String cterm=underline ctermbg=black  ctermfg=darkgreen
"hi Title cterm=bold ctermbg=black  ctermfg=yellow
"hi Todo cterm=none ctermbg=black  ctermfg=lightgreen
"hi Type cterm=none ctermbg=black  ctermfg=darkgreen
"hi Underlined cterm=underline
"hi WarningMsg cterm=none ctermbg=red  ctermfg=white
"hi diffAdded cterm=none ctermbg=black  ctermfg=lightgreen
"hi diffRemoved cterm=none ctermbg=black  ctermfg=red
"hi htmlSpecialChar cterm=underline ctermbg=black  ctermfg=Darkyellow
"hi perlPOD cterm=none ctermbg=black  ctermfg=lightgreen
"hi shCommandSub cterm=none ctermbg=black  ctermfg=lightred
"hi shConditional cterm=none ctermbg=black  ctermfg=brown
"hi shDerefPattern cterm=none ctermbg=black  ctermfg=yellow
"hi shOperator cterm=none ctermbg=black  ctermfg=green
"hi shSetList cterm=none ctermbg=black  ctermfg=magenta
"hi shShellVariables cterm=none ctermbg=black  ctermfg=yellow
"hi shStatement cterm=none ctermbg=black ctermfg=DarkCyan
"hi vimCommand cterm=none ctermbg=black ctermfg=white
"hi vimGroupName cterm=bold ctermbg=black  ctermfg=yellow
"hi Number cterm=bold ctermbg=black  ctermfg=white
"
""
""hi Error cterm=none  ctermbg=DarkBlue ctermfg=Cyan
"
"" if cterm=reverse, probably can't find desired effect...
""hi Operator cterm=bold,reverse ctermbg=black ctermfg=cyan
""hi Function cterm=reverse,none ctermbg=black  ctermfg=red
""hi Tag cterm=underline ctermbg=black  ctermfg=Darkyellow
""hi ShellVariables cterm=reverse ctermbg=black ctermfg=lightred
""hi Variable cterm=reverse ctermbg=grey ctermfg=lightred
""hi Label cterm=reverse,bold ctermbg=black ctermfg=yellow
""hi Keyword cterm=reverse,bold ctermbg=black ctermfg=yellow
""hi Exception cterm=reverse,bold ctermbg=black ctermfg=yellow
"
""hi PreProc ctermfg=yellow  
""hi NonText ctermfg=yellow 
""hi TabLineSel   ctermfg=yellow
"
"
""" Syntax group
""hi Comment      gui=NONE guifg=#c0c0d0 guibg=NONE
""hi Error        gui=BOLD guifg=#ffffff guibg=#ff0088 cterm=none ctermfg=white ctermbg=DarkBlue
""hi Identifier   gui=NONE guifg=#40f0f0 guibg=NONE
""hi Ignore       gui=NONE guifg=#000000 guibg=NONE
""hi PreProc      gui=NONE guifg=#40f0a0 guibg=NONE
""hi Special      gui=NONE guifg=#e0e080 guibg=NONE
""hi Statement    gui=NONE guifg=#ffa0ff guibg=NONE
""hi Todo         gui=BOLD,UNDERLINE guifg=#ffa0a0 guibg=NONE
""hi Type         gui=NONE guifg=#ffc864 guibg=NONE
""hi Underlined   gui=UNDERLINE guifg=#f0f0f8 guibg=NONE
""
""" HTML
""hi htmlLink                 gui=UNDERLINE
""hi htmlBold                 gui=BOLD
""hi htmlBoldItalic           gui=BOLD,ITALIC
""hi htmlBoldUnderline        gui=BOLD,UNDERLINE
""hi htmlBoldUnderlineItalic  gui=BOLD,UNDERLINE,ITALIC
""hi htmlItalic               gui=ITALIC
""hi htmlUnderline            gui=UNDERLINE
""hi htmlUnderlineItalic      gui=UNDERLINE,ITALIC
"
""               *cterm-colors*
"0Black
""DarkBlue
""DarkGreen
""DarkCyan
""DarkRed
""DarkMagenta
""Brown
""LightGray, LightGrey, Gray, Grey
""DarkGray, DarkGrey
""Blue, LightBlue
""Green, LightGreen
""Cyan, LightCyan
""Red, LightRed
""LightMagenta
""Yellow
""White
"
"" White =LightGray =LightGrey  Gray =Grey  Black =DarkGray =DarkGrey
"" Blue =DarkBlue  LightBlue
"" Green DarkGreen =LightGreen
"" Cyan DarkCyan =LightCyan
"" Red =DarkRed LightRed
"" DarkMagenta LightMagenta
"" Yellow Brown =Darkyellow
""
"" 00=none 01=bold 04=underscore 05=blink 07=reverse 08=concealed
""
"" black blue brown cyan darkBlue darkcyan darkgray darkgreen darkgrey
"" darkmagenta darkred darkyellow gray green grey lightblue lightcyan
"" lightgray lightgreen lightgrey lightmagenta lightred magenta red white
"" yellow
""
""0=Black =DarkGray =DarkGrey
""1=Red =DarkRed LightRed
""2=Green DarkGreen =LightGreen
""3=Yellow Brown =Darkyellow
""4=Blue =DarkBlue  LightBlue
""5=LightMagenta DarkMagenta
""6=Cyan DarkCyan =LightCyan
""7=White =LightGray =LightGrey  Gray =Grey
"
"" The color terminal (cterm) palette  (and bash escape codes)
"" The forground Colors (background colors begin with 4 verses 3)
"" Black       0;30     Dark Gray     1;30
"" Red         0;31     Light Red     1;31
"" Green       0;32     Light Green   1;32
"" Brown       0;33     Yellow        1;33
"" Blue        0;34     Light Blue    1;34
"" Purple      0;35     Light Purple  1;35
"" Cyan        0;36     Light Cyan    1;36
"" Light Gray  0;37     White         1;37
"" Attribute codes:
"" 00=none 01=bold 04=underscore 05=blink 07=reverse 08=concealed
"
"
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
