" .vim-color.vim

" (c) 2017-2023 George Georgalis <george@galis.org> unlimited use with this notice

if &t_Co > 1
   syntax enable
endif

" use POSIX for shell highlighting
let g:is_posix= 1

" light background has less saturation...
set background=dark

" https://stackoverflow.com/questions/9464844/how-to-get-group-name-of-highlighting-under-cursor-in-vim/58244921#58244921
function! SynStack ()
    for i1 in synstack(line("."), col("."))
        let i2 = synIDtrans(i1)
        let n1 = synIDattr(i1, "name")
        let n2 = synIDattr(i2, "name")
        echo n1 "->" n2
    endfor
endfunction
map gm :call SynStack()<CR>

" :scriptnames all the files sourced in the configuratioon
" :highlight (:hi) shows all highlight settings, with arg1 the settings for that highlight, otherwise sets arg1 settings
" level the deck, least artifacts remain...
highlight clear
syntax reset
set background=dark
set termguicolors
syntax on

"1   2               3          4                5                 6             7         8              9
"hi  name            term=none  cterm=none       ctermfg=none      ctermbg=none  gui=none  guifg=none     guibg=none
hi   Comment         term=NONE  cterm=NONE       ctermfg=DarkCyan  ctermbg=NONE  gui=NONE  guifg=NONE     guibg=NONE
hi   Identifier      term=NONE  cterm=NONE       ctermfg=69        ctermbg=NONE  gui=NONE  guifg=NONE     guibg=NONE
hi   NonText         term=NONE  cterm=NONE       ctermfg=23        ctermbg=NONE  gui=NONE  guifg=NONE     guibg=NONE
hi   Search          term=NONE  cterm=reverse    ctermfg=24        ctermbg=NONE  gui=NONE  guifg=#600982  guibg=NONE
hi   CurSearch       term=NONE  cterm=reverse    ctermfg=24        ctermbg=NONE  gui=NONE  guifg=#c77a0e  guibg=NONE
hi   Special         term=NONE  cterm=NONE       ctermfg=5         ctermbg=NONE  gui=NONE  guifg=NONE     guibg=NONE
hi   Statement       term=NONE  cterm=NONE       ctermfg=3         ctermbg=NONE  gui=NONE  guifg=NONE     guibg=NONE
hi   makeCommands    term=NONE  cterm=NONE       ctermfg=7         ctermbg=NONE  gui=NONE  guifg=NONE     guibg=NONE
hi   makeComment     term=NONE  cterm=NONE       ctermfg=6         ctermbg=NONE  gui=NONE  guifg=NONE     guibg=NONE
hi   makeIdent       term=NONE  cterm=NONE       ctermfg=5         ctermbg=NONE  gui=NONE  guifg=NONE     guibg=NONE
hi   makeImplicit    term=NONE  cterm=NONE       ctermfg=2         ctermbg=NONE  gui=NONE  guifg=NONE     guibg=NONE
hi   makeTarget      term=NONE  cterm=bold       ctermfg=3         ctermbg=NONE  gui=NONE  guifg=NONE     guibg=NONE
hi   shCmdSubRegion  term=NONE  cterm=NONE       ctermfg=197       ctermbg=NONE  gui=NONE  guifg=NONE     guibg=NONE
hi   shCommandSub    term=NONE  cterm=NONE       ctermfg=90        ctermbg=NONE  gui=NONE  guifg=NONE     guibg=NONE
hi   shDeref         term=NONE  cterm=underline  ctermfg=130       ctermbg=NONE  gui=NONE  guifg=NONE     guibg=NONE
hi   shFunctionOne   term=NONE  cterm=NONE       ctermfg=182       ctermbg=NONE  gui=NONE  guifg=NONE     guibg=NONE
hi   shOption        term=NONE  cterm=NONE       ctermfg=22        ctermbg=NONE  gui=NONE  guifg=NONE     guibg=NONE
hi   vim9Comment     term=NONE  cterm=bold       ctermfg=red       ctermbg=NONE  gui=NONE  guifg=NONE     guibg=NONE
hi   SpecialKey      term=NONE  cterm=reverse    ctermfg=237       ctermbg=NONE  gui=NONE  guifg=#36261a  guibg=NONE
hi   Constant        term=NONE  cterm=underline  ctermfg=109       ctermbg=NONE  gui=NONE  guifg=NONE     guibg=NONE
hi   PreProc         term=NONE  cterm=NONE       ctermfg=NONE      ctermbg=NONE  gui=NONE  guifg=#5f30a1  guibg=NONE
hi   shParen         term=NONE  cterm=NONE       ctermfg=NONE      ctermbg=NONE  gui=NONE  guifg=#b499bf  guibg=NONE
hi   shDerefPattern  term=NONE  cterm=NONE       ctermfg=NONE      ctermbg=NONE  gui=NONE  guifg=#6e6c64  guibg=NONE
hi   shExpr          term=NONE  cterm=NONE       ctermfg=NONE      ctermbg=NONE  gui=NONE  guifg=#8f8029  guibg=NONE

" cterm: none,bold,underline,reverse
hi  User1  guibg=NONE  guifg=NONE  gui=NONE  ctermbg=1     ctermfg=NONE  cterm=bold
hi  User2  guibg=NONE  guifg=NONE  gui=NONE  ctermbg=196   ctermfg=NONE  cterm=bold
hi  User3  guibg=NONE  guifg=NONE  gui=NONE  ctermbg=208   ctermfg=NONE  cterm=bold
hi  User4  guibg=NONE  guifg=NONE  gui=NONE  ctermbg=221   ctermfg=NONE  cterm=bold
hi  User5  guibg=NONE  guifg=NONE  gui=NONE  ctermbg=11    ctermfg=NONE  cterm=bold
hi  User6  guibg=NONE  guifg=NONE  gui=NONE  ctermbg=123   ctermfg=NONE  cterm=bold
hi  User7  guibg=NONE  guifg=NONE  gui=NONE  ctermbg=32    ctermfg=NONE  cterm=bold
hi  User8  guibg=NONE  guifg=NONE  gui=NONE  ctermbg=20    ctermfg=15    cterm=bold
hi  User9  guibg=NONE  guifg=NONE  gui=NONE  ctermbg=none  ctermfg=91    cterm=bold

set statusline=
"set statusline+=%1*1\ %2*2\ %3*3\ %4*4\ %5*5\ %6*6\ %7*7\ %8*8\ %9*9\ 
set statusline+=%9*%n                                  " buffer number
set statusline+=%6*\ %<%F\                             " left, File+path
set statusline+=%1*%{(&bomb?\",\ BOM\ \":\"\")}        " BOM status (Byte Order Mark, for utf-8, or the little/big endian variants)
set statusline+=%7*\ %M%R%Y\                           " Modified? Readonly? Help?
set statusline+=%3*\ %{&ff}\                           " FileFormat (dos/unix..)
set statusline+=%5*\ %{''.(&fenc!=''?&fenc:&enc).''}\  " FileType Encoding
set statusline+=%4*\ %{&spelllang}\                    " spell language
set statusline+=%4*\ %=%o,0x%B\                        " begin right, with (under cursor) 'file byte, hex value'
set statusline+=%8*\ %v,%l\ %P/%L\                     " column,line line-percent/line-total


" 8 bit colors
" for c in {0..16} ; do printf "\x1b[48;5;${c}m" ; printf "%3d" "${c}" ; done ; echo
"  n  normal   bright
"  0  black    8
"  1  red      9
"  2  green    10
"  3  yellow   11
"  4  blue     12
"  5  megenta  13
"  6  cyan     14
"  7  white    15

" interface color and attribute varables
"
"	term		attributes in a B&W terminal
"	cterm		attributes in a color terminal
"	ctermfg		foreground color in a color terminal
"	ctermbg		background color in a color terminal
"	gui		    attributes in the GUI
"	guifg		foreground color in the GUI
"	guibg		background color in the GUI
"
" atributes:  none,bold,underline,reverse
" color (per term capacity): name,8-bit,16-bit,web
"
"
""" Syntax group
""hi  Comment     gui=NONE            guifg=#c0c0d0  guibg=NONE
""hi  Error       gui=BOLD            guifg=#ffffff  guibg=#ff0088  cterm=none  ctermfg=white  ctermbg=DarkBlue
""hi  Identifier  gui=NONE            guifg=#40f0f0  guibg=NONE
""hi  Ignore      gui=NONE            guifg=#000000  guibg=NONE
""hi  PreProc     gui=NONE            guifg=#40f0a0  guibg=NONE
""hi  Special     gui=NONE            guifg=#e0e080  guibg=NONE
""hi  Statement   gui=NONE            guifg=#ffa0ff  guibg=NONE
""hi  Todo        gui=BOLD,UNDERLINE  guifg=#ffa0a0  guibg=NONE
""hi  Type        gui=NONE            guifg=#ffc864  guibg=NONE
""hi  Underlined  gui=UNDERLINE       guifg=#f0f0f8  guibg=NONE
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
"" Black  =DarkGray  =DarkGrey
""  White        =LightGray    =LightGrey
""  Blue         =DarkBlue     LightBlue
""  Green        DarkGreen     =LightGreen
""  Cyan         DarkCyan      =LightCyan
""  Red          =DarkRed      LightRed
""  DarkMagenta  LightMagenta
""  Yellow       Brown         =Darkyellow
""
"" black blue brown cyan darkBlue darkcyan darkgray darkgreen darkgrey
"" darkmagenta darkred darkyellow gray green grey lightblue lightcyan
"" lightgray lightgreen lightgrey lightmagenta lightred magenta red white
"" yellow
""
""0=Black         =DarkGray     =DarkGrey
""1=Red           =DarkRed      =LightRed
""2=Green         =DarkGreen    =LightGreen
""3=Yellow        =Brown 
""4=Blue          =DarkBlue     =LightBlue
""5=LightMagenta  =DarkMagenta
""6=Cyan          =DarkCyan     =LightCyan
""7=White         =LightGray    =LightGrey

"" 0  Black        8   DarkGrey
"" 1  DarkBlue     9   Blue
"" 2  DarkGreen    10  Green
"" 3  DarkCyan     11  Cyan
"" 4  DarkRed      12  Red
"" 5  DarkMagenta  13  LightMagenta
"" 6  Brown        14  Yellow
"" 7  Grey         15  White

"" The color terminal (cterm) palette (and bash escape codes)
"" 
"" (background colors begin with 40 verses 30)
"" Black       0;30     Dark Gray     1;30
"" Red         0;31     Light Red     1;31
"" Green       0;32     Light Green   1;32
"" Brown       0;33     Yellow        1;33
"" Blue        0;34     Light Blue    1;34
"" Purple      0;35     Light Purple  1;35
"" Cyan        0;36     Light Cyan    1;36
"" Light Gray  0;37     White         1;37
""
"" Attribute codes: 00=none 01=bold 04=underscore 05=blink 07=reverse 08=concealed

" see xterm-true-color
" let &t_8f = "^[[38;2;%lu;%lu;%lum"
" let &t_8b = "^[[48;2;%lu;%lu;%lum"
" let &t_8f = "\<Esc>[38:2:%lu:%lu:%lum"
" let &t_8b = "\<Esc>[48:2:%lu:%lu:%lum"

" for c in 1 196  130 202 209 220 226 156 49 27 57 ;  do printf "\x1b[38;5;${c}m" ; printf "%4d" "${c}" ; done ; echo
" for c in 139 198 94 222 112 34 123 141 91 ;  do printf "\x1b[48;5;${c}m" ; printf "%4d" "${c}" ; done ; echo
" for c in 0 94 166  167 208 214 112 34  ;  do printf "\x1b[48;5;${c}m" ; printf "%4d\x1b[38;5;7m\x1b[48;5;0m" "${c}" ; done ; echo

" for c in {16..51} ; do export c ; for d in {1..6} ; do export d ; for e in {1..5} ; do export e ; f=$((c+35*d*e)) ; printf "\x1b[48;5;${f}m" ; printf "%4d" "${f}" ; test "$(( ( f - 15 ) % 36 ))" -ne "0" && printf "" || printf "\n" ;  done ; done; done
" for c in {232..255} ;  do printf "\x1b[48;5;${c}m" ; printf "%4d\x1b[38;5;7m\x1b[48;5;0m" "${c}" ; done ; echo ; for c in 1 196 208 221 11 123 32 20 91  0 94 166  167 208 214 112 34 ; do printf "\x1b[48;5;${c}m" ; printf "%4d\x1b[38;5;7m\x1b[48;5;0m" "${c}" ; done ; echo

" for c in {0..16} ; do printf "\x1b[48;5;${c}m" ; printf "%3d" "${c}" ; done ; echo ;
" for c in 0 1 9 3 11 15 14 6 2 10 12 8 4  ; do printf "\x1b[48;5;${c}m" ; printf "%3d" "${c}" ; done ; echo ;
" for c in {16..231} ; do printf "\x1b[48;5;${c}m" ; printf "%4d" "${c}" ; test "$(( ( c - 15 ) % 36 ))" -ne "0" && printf "" || printf "\n" ;  done ;
" for c in {232..255} ;  do printf "\x1b[48;5;${c}m" ; printf "%4d\x1b[38;5;7m\x1b[48;5;0m" "${c}" ; done ; echo ;
" for c in 1 196 208 221 11 123 32 20 91  0 94 166  167 208 214 112 34 ; do printf "\x1b[48;5;${c}m" ; printf "%4d\x1b[38;5;7m\x1b[48;5;0m" "${c}" ; done ; echo

