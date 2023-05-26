" .vim-color.vim

" (c) 2017-2022 George Georgalis <george@galis.org> unlimited use with this notice

if &t_Co > 1
   syntax enable
endif

" use POSIX for shell highlighting
let g:is_posix= 1

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

hi  Comment         cterm=none       ctermfg=DarkCyan  term=none
hi  Constant        cterm=underline  ctermfg=15        term=underline
hi  Identifier      cterm=none       ctermfg=69        term=none
hi  PreProc         cterm=none       ctermfg=6         term=none
hi  Search          cterm=reverse    ctermfg=24        term=reverse
hi  Special         cterm=none       ctermfg=5         term=none
hi  Statement       cterm=none       ctermfg=3         term=none
hi  makeCommands    cterm=none       ctermfg=7         term=none
hi  makeComment     cterm=none       ctermfg=6         term=none
hi  makeIdent       cterm=none       ctermfg=5         term=none
hi  makeImplicit    cterm=none       ctermfg=2         term=none
hi  makeTarget      cterm=bold       ctermfg=3         term=bold
hi  shCmdSubRegion  cterm=none       ctermfg=1         term=none
hi  shCmdSubRegion  cterm=none       ctermfg=197       term=none
hi  shCommandSub    cterm=none       ctermfg=90        term=none
hi  shDeref         cterm=none       ctermfg=130       term=none
hi  shFunctionOne   cterm=none       ctermfg=182       term=none
hi  vim9Comment     cterm=bold       ctermfg=red       term=bold
hi  shOption        cterm=none       ctermfg=22        term=none
hi  NonText         cterm=none       ctermfg=23        term=none
hi  SpecialKey      cterm=none       ctermfg=DarkBlue  term=none
" See ~/.Xdefaults

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
"		none,bold,underline,reverse
"
"" some redefs of the default color syntax, good for dark
"" but makes very difficult with light background...
""set background=light
"
"hi  Boolean           cterm=none       ctermbg=black      ctermfg=LightGreen
"hi  CommandSub        cterm=none       ctermbg=black      ctermfg=lightred
"hi  Conditional       cterm=none       ctermbg=black      ctermfg=red
"hi  Delimiter         cterm=none       ctermbg=black      ctermfg=darkred
"hi  Delimiter         cterm=none       ctermbg=black      ctermfg=LightGreen
"hi  Directory         cterm=none       ctermbg=LightBlue  ctermfg=white
"hi  Identifier        cterm=none       ctermbg=black      ctermfg=DarkCyan
"hi  ModeMsg           cterm=none       ctermbg=green      ctermfg=black
"hi  Normal            ctermfg=Gray     ctermbg=black
"hi  PreProc           cterm=none       ctermbg=black      ctermfg=green
"hi  Repeat            cterm=none       ctermbg=black      ctermfg=magenta
"hi  Search            cterm=reverse    ctermbg=DarkBlue   ctermfg=LightCyan
"hi  Statement         cterm=none       ctermbg=black      ctermfg=none
"hi  String            cterm=underline  ctermbg=black      ctermfg=darkgreen
"hi  Title             cterm=bold       ctermbg=black      ctermfg=yellow
"hi  Todo              cterm=none       ctermbg=black      ctermfg=lightgreen
"hi  Type              cterm=none       ctermbg=black      ctermfg=darkgreen
"hi  Underlined        cterm=underline
"hi  WarningMsg        cterm=none       ctermbg=red        ctermfg=white
"hi  diffAdded         cterm=none       ctermbg=black      ctermfg=lightgreen
"hi  diffRemoved       cterm=none       ctermbg=black      ctermfg=red
"hi  htmlSpecialChar   cterm=underline  ctermbg=black      ctermfg=Darkyellow
"hi  perlPOD           cterm=none       ctermbg=black      ctermfg=lightgreen
"hi  shCommandSub      cterm=none       ctermbg=black      ctermfg=lightred
"hi  shConditional     cterm=none       ctermbg=black      ctermfg=brown
"hi  shDerefPattern    cterm=none       ctermbg=black      ctermfg=yellow
"hi  shOperator        cterm=none       ctermbg=black      ctermfg=green
"hi  shSetList         cterm=none       ctermbg=black      ctermfg=magenta
"hi  shShellVariables  cterm=none       ctermbg=black      ctermfg=yellow
"hi  shStatement       cterm=none       ctermbg=black      ctermfg=DarkCyan
"hi  vimCommand        cterm=none       ctermbg=black      ctermfg=white
"hi  vimGroupName      cterm=bold       ctermbg=black      ctermfg=yellow
"hi  Number            cterm=bold       ctermbg=black      ctermfg=white
"
""
""hi Error cterm=none  ctermbg=DarkBlue ctermfg=Cyan
"
"" if cterm=reverse, probably can't find desired effect...
""hi  Operator        cterm=bold,reverse  ctermbg=black  ctermfg=cyan
""hi  Function        cterm=reverse,none  ctermbg=black  ctermfg=red
""hi  Tag             cterm=underline     ctermbg=black  ctermfg=Darkyellow
""hi  ShellVariables  cterm=reverse       ctermbg=black  ctermfg=lightred
""hi  Variable        cterm=reverse       ctermbg=grey   ctermfg=lightred
""hi  Label           cterm=reverse,bold  ctermbg=black  ctermfg=yellow
""hi  Keyword         cterm=reverse,bold  ctermbg=black  ctermfg=yellow
""hi  Exception       cterm=reverse,bold  ctermbg=black  ctermfg=yellow
"
""hi PreProc ctermfg=yellow
""hi NonText ctermfg=yellow
""hi TabLineSel   ctermfg=yellow
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
"" 00=none 01=bold 04=underscore 05=blinYk 07=reverse 08=concealed
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

" gray
" for c in {232..256} ; do
"     printf "\x1b[38;5;${c}m" ; printf "%4d" "${c}"
"     done
"
" 4 bit color
" 0 Black     1 DarkBlue   2 DarkGreen   3 DarkCyan   4 DarkRed   5 DarkMagenta    6 Brown    7 Grey
" 8 DarkGrey  9 Blue      10 Green      11 Cyan      12 Red      13 LightMagenta  14 Yellow  15 White
" for c in {0..15} ; do
"     printf "\x1b[38;5;${c}m" ; printf "%3d" "${c}"
"     test "$c" -lt "16" && { test "$(( ( c ) % 8 ))" -ne "7" && printf "" || printf "\n" ;}
"     done
" for c in {0..15} ; do  printf "\x1b[38;5;${c}m" ; printf "%3d" "${c}" ; test "$c" -lt "16" && { test "$(( ( c ) % 8 ))" -ne "7" && printf "" || printf "\n" ;} ; done

" 255 colors
" for c in {16..231} ; do printf "\x1b[48;5;${c}m" ; printf "%4d" "${c}" ; test "$(( ( c - 15 ) % 36 ))" -ne "0" && printf "" || printf "\n" ;  done
" 
" for c in 1 196  130 202 209 220 226 156 49 27 57 ;  do printf "\x1b[38;5;${c}m" ; printf "%4d" "${c}" ; done ; echo
" for c in 139 198 94 222 112 34 123 141 91 ;  do printf "\x1b[48;5;${c}m" ; printf "%4d" "${c}" ; done ; echo
" for c in 0 94 166  167 208 214 112 34  ;  do printf "\x1b[48;5;${c}m" ; printf "%4d\x1b[38;5;7m\x1b[48;5;0m" "${c}" ; done ; echo

" for c in 0 1 9 3 11 15 14 6 2 10 12 8 4  ; do printf "\x1b[48;5;${c}m" ; printf "%3d" "${c}" ; done ; echo ;
" for c in {16..231} ; do printf "\x1b[48;5;${c}m" ; printf "%4d" "${c}" ; test "$(( ( c - 15 ) % 36 ))" -ne "0" && printf "" || printf "\n" ;  done ;
" for c in {232..255} ;  do printf "\x1b[48;5;${c}m" ; printf "%4d\x1b[38;5;7m\x1b[48;5;0m" "${c}" ; done ; echo ;
" for c in 1 196 208 221 11 123 32 20 91  0 94 166  167 208 214 112 34 ; do printf "\x1b[48;5;${c}m" ; printf "%4d\x1b[38;5;7m\x1b[48;5;0m" "${c}" ; done ; echo
" 
" for c in 0 1 9 3 11 15 14 6 2 10 12 8 4  ; do printf "\x1b[48;5;${c}m" ; printf "%3d" "${c}" ; done ; echo ; 
" 
" for c in {16..51} ; do export c ; for d in {1..6} ; do export d ; for e in {1..5} ; do export e ; f=$((c+35*d*e)) ; printf "\x1b[48;5;${f}m" ; printf "%4d" "${f}" ; test "$(( ( f - 15 ) % 36 ))" -ne "0" && printf "" || printf "\n" ;  done ; done; done
" for c in {232..255} ;  do printf "\x1b[48;5;${c}m" ; printf "%4d\x1b[38;5;7m\x1b[48;5;0m" "${c}" ; done ; echo ; for c in 1 196 208 221 11 123 32 20 91  0 94 166  167 208 214 112 34 ; do printf "\x1b[48;5;${c}m" ; printf "%4d\x1b[38;5;7m\x1b[48;5;0m" "${c}" ; done ; echo
" 
" for f in 38 48; do 
" for c in {16..231} ; do printf "\x1b[${f};5;${c}m" ; printf "%4d" "${c}" ; test "$(( ( c - 15 ) % 36 ))" -eq "0" && { tput sgr0 ; printf "\n" ;} ;  done
" n=0 ; for c in \
"   16  17  18  19  20  21 52  53  54  55  56  57 88  89  90  91  92  93  124 125 126 127 128 129 160 161 162 163 164 165 196 197 198 199 200 201 \
"   22  23  24  25  26  27 58  59  60  61  62  63 94  95  96  97  98  99  130 131 132 133 134 135 166 167 168 169 170 171 202 203 204 205 206 207 \
"   28  29  30  31  32  33 64  65  66  67  68  69 100 101 102 103 104 105 136 137 138 139 140 141 172 173 174 175 176 177 208 209 210 211 212 213 \
"   34  35  36  37  38  39 70  71  72  73  74  75 106 107 108 109 110 111 142 143 144 145 146 147 178 179 180 181 182 183 214 215 216 217 218 219 \
"   40  41  42  43  44  45 76  77  78  79  80  81 112 113 114 115 116 117 148 149 150 151 152 153 184 185 186 187 188 189 220 221 222 223 224 225 \
"   46  47  48  49  50  51 82  83  84  85  86  87 118 119 120 121 122 123 154 155 156 157 158 159 190 191 192 193 194 195 226 227 228 229 230 231 \
" ; do n=$((n+1)) ; printf "\x1b[${f};5;${c}m" ; printf "%4d" "${c}" ; test $((n % 36)) -eq 0 && { tput sgr0 ; printf "\n" ;} ; done \
" done # f
" 
" for f in 38 48 ; do
" for c in {16..231} ; do printf "\x1b[${f};5;${c}m" ; printf "%4d" "${c}" ; test "$(( ( c - 15 ) % 36 ))" -eq "0" && { tput sgr0 ; printf "\n" ;} ;  done 
" n=0 ; for c in \
"   46  47  48  49  50  51 82  83  84  85  86  87 118 119 120 121 122 123 154 155 156 157 158 159 190 191 192 193 194 195 226 227 228 229 230 231 \
"   40  41  42  43  44  45 76  77  78  79  80  81 112 113 114 115 116 117 148 149 150 151 152 153 184 185 186 187 188 189 220 221 222 223 224 225 \
"   34  35  36  37  38  39 70  71  72  73  74  75 106 107 108 109 110 111 142 143 144 145 146 147 178 179 180 181 182 183 214 215 216 217 218 219 \
"   28  29  30  31  32  33 64  65  66  67  68  69 100 101 102 103 104 105 136 137 138 139 140 141 172 173 174 175 176 177 208 209 210 211 212 213 \
"   22  23  24  25  26  27 58  59  60  61  62  63 94  95  96  97  98  99  130 131 132 133 134 135 166 167 168 169 170 171 202 203 204 205 206 207 \
"   16  17  18  19  20  21 52  53  54  55  56  57 88  89  90  91  92  93  124 125 126 127 128 129 160 161 162 163 164 165 196 197 198 199 200 201 \
" ; do n=$((n+1)) ; printf "\x1b[${f};5;${c}m" ; printf "%4d" "${c}" ; test $((n % 36)) -eq 0 && { tput sgr0 ; printf "\n" ;} ; done \
" ; done # f

"" 24 bit
"for a in {0..63} ; do r=$(( 4 * a ))
"for b in {0..63} ; do g=$(( 4 * b ))
"for c in {0..63} ; do b=$(( 4 * c ))
"    printf "\x1b[48;2;$r;$g;${b}m $r $g $b "
"    done ; echo ; done ; done
"

" Grays
" for c in {232..255} ; do printf "\x1b[48;5;${c}m" ; printf "%4d\x1b[38;5;7m\x1b[48;5;0m" "${c}" ; done ; echo && \
" for c in {232..255} ; do printf "\x1b[38;5;${c}m" ; printf "%4d\x1b[48;5;7m\x1b[48;5;0m" "${c}" ; done ; echo

"set termguicolors

"hi  User1   ctermbg=196    ctermfg=15     cterm=none  guibg=#D0B1AF  guifg=#110001
"hi  User2   ctermbg=198    ctermfg=1      cterm=none  guibg=#F3B3B0  guifg=#110001
"hi  User3  ctermbg=209  ctermfg=7   cterm=bold  guibg=#F9D8B4  guifg=#110001
""hi  User4   ctermbg=124    ctermfg=0      cterm=none  guibg=#FEFDB9  guifg=#110001
""hi  User4   ctermbg=141    ctermfg=1      cterm=none  guibg=#B6D6FB  guifg=#110001
""hi  User4   ctermbg=222    ctermfg=1      cterm=none  guibg=#FEFDB9  guifg=#110001
"hi  User4  ctermbg=91   ctermfg=1   cterm=none  guibg=#AFAFF9  guifg=#110001
"hi  User5   ctermbg=112    ctermfg=1      cterm=none  guibg=#DEFBB7  guifg=#110001
""hi  User6   ctermbg=107    ctermfg=6      cterm=none  guibg=#BEFBB6  guifg=#110001
"hi  User6   ctermbg=34     ctermfg=1      cterm=none  guibg=#BEFBB6  guifg=#110001
"hi  User7   ctermbg=123    ctermfg=1      cterm=none  guibg=#BFFCFF  guifg=#110001
"hi  User8  ctermbg=23   ctermfg=15  cterm=none  guibg=#B6D6FB  guifg=#110001
"hi  User9  ctermbg=19   ctermfg=15  cterm=none  guibg=#AFAFF9  guifg=#110001

" hi  User1  ctermbg=139  ctermfg=1   cterm=none  guibg=#D0B1AF  guifg=#110001
" hi  User2  ctermbg=202  ctermfg=7   cterm=bold  guibg=#F3B3B0  guifg=#110001
" hi  User3  ctermbg=209  ctermfg=7   cterm=bold  guibg=#F9D8B4  guifg=#110001
" hi  User4  ctermbg=57   ctermfg=1   cterm=none  guibg=#AFAFF9  guifg=#110001
" hi  User5  ctermbg=226  ctermfg=0   cterm=bold  guibg=#DEFBB7  guifg=#110001
" hi  User6  ctermbg=94   ctermfg=1   cterm=none  guibg=#F9D8B4  guifg=#110001
" hi  User7  ctermbg=215  ctermfg=15  cterm=bold  guibg=#BFFCFF  guifg=#110001
" hi  User8  ctermbg=23   ctermfg=15  cterm=none  guibg=#B6D6FB  guifg=#110001
" hi  User9  ctermbg=19   ctermfg=15  cterm=none  guibg=#AFAFF9  guifg=#110001

" cterm: none,bold,underline,reverse
hi User1 ctermbg=1   cterm=bold
hi User2 ctermbg=196 cterm=bold
hi User3 ctermbg=208 cterm=bold
hi User4 ctermbg=221 cterm=bold
hi User5 ctermbg=11  cterm=bold
hi User6 ctermbg=123 cterm=bold
hi User7 ctermbg=32  cterm=bold
hi User8 ctermbg=20  cterm=bold ctermfg=15
hi User9 ctermfg=91  cterm=bold

set statusline=
"set statusline+=%1*1\ %2*2\ %3*3\ %4*4\ %5*5\ %6*6\ %7*7\ %8*8\ %9*9\ 
set statusline+=%9*%n                                  " buffer number
set statusline+=%6*\ %<%F\                             " left, File+path
set statusline+=%1*%{(&bomb?\",\ BOM\ \":\"\")}        " BOM status (Byte Order Mark, for utf-8, or the little/big endian variants)
set statusline+=%7*\ %M%R%Y\                           " Modified? Readonly? Help?
set statusline+=%3*\ %{&ff}\                           " FileFormat (dos/unix..)
set statusline+=%4*\ %{''.(&fenc!=''?&fenc:&enc).''}\  " FileType Encoding
set statusline+=%5*\ %{&spelllang}\                    " spell language
set statusline+=%5*\ %=%o,0x%B\                        " begin right, with (under cursor) 'file byte, hex value'
set statusline+=%8*\ %v,%l\ %P/%L\                     " column,line line-percent/line-total
