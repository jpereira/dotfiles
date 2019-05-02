" +------------------------------------------------+
" File: .vimrc
" Author: Jorge Pereira <jpereiran@gmail.com>
" Last Change: qua 23 jan 2019 18:28:53 -02
" +------------------------------------------------+

set backspace=indent,eol,start

set modeline
" corrigindo bug ao abrir vim+nerdtree a partir do screen
if match($TERM, "screen") !=- 1 || match($TERM, "screen.linux") != -1
  set term=xterm
endif

" coloca a data tipo Ter 26/Out/2004 hs 10:53 na linha atual
iab ,d <C-R>=strftime("%a %d/%b/%Y hs %H:%M")<CR>
iab ,m <jpereiran@gmail.com>

set textwidth=0
set title
set titlestring=%<Nome=%t%m%r%h%w
"\%=
"\BUFFER=%n
"\%(\ %a%)
"\%28([]))

" =============== DATA AUTOMÁTICA ===========================
" insira na em seus arquivos =   "ultima modificação:"
" em qualquer das três primeiras linhas
fun! SetDate()
   mark z
   if getline(1) =~ ".*ultima modificação:" ||
                           \ getline(2) =~ ".*ultima modificação:"  ||
                           \ getline(3) =~ ".*ultima modificação:"  ||
                           \ getline(4) =~ ".*ultima modificação:"  ||
                           \ getline(5) =~ ".*ultima modificação:"
      exec "1,5s/\s*ultima modificação: .*$/ultima modificação: " .
strftime("%c") . "/"
   endif
   exec "'z"
endfun

"  abaixo a chamada a função de data que é chamada toda vez que você
"  salva um arquivo preexistente

fun! LastChange()
   mark z
   if getline(1) =~ ".*Last Change:" ||
                           \ getline(2) =~ ".*Last Change:"  ||
                           \ getline(3) =~ ".*Last Change:"  ||
                           \ getline(4) =~ ".*Last Change:"  ||
                           \ getline(5) =~ ".*Last Change:"
      exec "1,5s/\s*Last Change: .*$/Last Change: " . strftime("%c") . "/"
   endif
   exec "'z"
endfun

" coloquei duas opções (alteração e modificação), assim
" não tem perigo de você esquecer e o sistema
" não atualizar a data do salvamento, outra melhoria na função
" é que agora é válida para qualquer tipo de arquivo. se usar
" num html por exemplo insira um começo de comentário na linha
" da data e feche o comentário na próxima linha

"  abaixo a chamada a função de data que é chamada toda vez que você
"  salva um arquivo preexistente
au BufWritePre * call SetDate()
au BufWritePre * call LastChange()

"============ Fim da Data Automática ===================

" === Cria um registro de alterações de arquivo ========
" ChangeLog entry convenience
" Função para inserir um status do arquivo
" cirado: data de criação, alteração, autor etc
fun! InsertChangeLog()
    normal(1G)
    call append(0, "File: ")
    call append(1, "Created: " . strftime("%a %d/%b/%Y hs %H:%M"))
    call append(2, "Last Change: " . strftime("%a %d/%b/%Y hs %H:%M"))
    call append(3, "Author: Jorge Pereira <jorge.pereira@schibsted.com.br>")
    normal($)
endfun
map ,cl :call InsertChangeLog()<cr>A

" Cria um cabeçalho para scripts bash
fun! InsertHeadBash()
    normal(1G)
    call append(0, "#!bin/bash")
    call append(1, "# Created:" . strftime("%a %d/%b/%Y hs %H:%M"))
    call append(2, "# Last Change:" . strftime("%a %d/%b/%Y hs %H:%M"))
    call append(3, "# Author: Jorge Pereira <jorge.pereira@schibsted.com.br>")
    call append(3, "# ")
    normal($)
endfun
map ,sh :call InsertHeadBash()<cr>A

" Remove Ctrl+M do final de linhas do DOS
" get rid of
if has("user_commands")
  " remove ^M from the file
  com! RemoveCtrlM :%s/^M/\r/g
  " change to directory of current file
  com! CD cd %:p:h
endif

" Ao editar um arquivo será aberto no ultimo ponto em
" que foi editado
  autocmd BufReadPost *
    \ if line("'\"") > 0 && line("'\"") <= line("$") |
    \   exe "normal g`\"" |
    \ endif

" Configura o encoding do arquivo
set encoding=iso-8859-1

" Syntax Highlight
syntax enable

"fundo preto
set bg=dark

" 4 spaces for indenting
set shiftwidth=4

" 4 stops
set tabstop=8

call pathogen#runtime_append_all_bundles()
call pathogen#helptags()

" Give a shortcut key to NERD Tree
map <F5> :NERDTreeToggle<CR>

" Spaces instead of tabs
"set expandtab

" Always  set auto indenting on
set autoindent

" select when using the mouse
set selectmode=mouse
set mouse=a
set ttymouse=xterm2 

" Line Numbers
set nu

" Comments color
highlight Comment ctermfg=green

set tags=tags;/
map <C-\> :tab split<CR>:exec("tag ".expand("<cword>"))<CR>
map <A-]> :vsp <CR>:exec("tag ".expand("<cword>"))<CR>

"desabilita highlight do search
nnoremap <F6> :noh<CR>

"<ctrl><tab> pula de tab
nnoremap <S-Tab> gT

" Deleta linha com CTRL+D
noremap <C-D> dd
vnoremap <C-D> <C-C>dd
inoremap <C-D> <C-O>dd

" Command-line com CTRL+ALT+C
noremap <C-A-C> :
vnoremap <C-A-C> <C-Q>:
inoremap <C-A-C> <C-O>:

" Busca com CTRL+F
noremap <C-F> /
vnoremap <C-F> <C-Q>/
inoremap <C-F> <C-O>/

" Abre arquivos com CTRL+O
noremap <C-O> :tabnew 
vnoremap <C-O> <C-Q>:tabnew 
inoremap <C-O> <C-O>:tabnew 

" Função que usa o omnicomplete apenas com o CTRL+SPACE
inoremap <C-SPACE> <C-X><C-O>
filetype plugin on

" Fechamento automático de parênteses
imap { {}<left>
imap ( ()<left>
imap [ []<left>

"""""""""""""""""""""""""""""
" Atalhos comuns de teclado "
"""""""""""""""""""""""""""""

" Permite selecionar com SHIFT + SETA como no Windows
"set selectmode=mouse,key
"set mousemodel=popup
"set keymodel=startsel,stopsel
"set selection=exclusive

" Backspace no modo de visão apaga a seleção
vnoremap <BS> d

" CTRL-Z desfaz
noremap <C-Z> u
vnoremap <C-Z> <C-C>u
inoremap <C-Z> <C-O>u

" CTRL-Y refaz
noremap <C-Y> <C-R>
inoremap <C-Y> <C-O><C-R>

" CTRL-A seleciona tudo
noremap <C-A> gggH<C-O>G
inoremap <C-A> <C-O>gg<C-O>gH<C-O>G
cnoremap <C-A> <C-C>gggH<C-O>G
onoremap <C-A> <C-C>gggH<C-O>G
snoremap <C-A> <C-C>gggH<C-O>G
xnoremap <C-A> <C-C>ggVG

" CTRL-F4 fecha a janela
noremap <C-F4> <C-W>c
inoremap <C-F4> <C-O><C-W>c
cnoremap <C-F4> <C-C><C-W>c
onoremap <C-F4> <C-C><C-W>c

function! FindBconfKey()
    let key = expand("<cWORD>")
    let key = substitute(key, "[^a-zA-Z0-9._]\\+", "", "g")
    echo "Searching: " . key 
    let options = split(system("grep -n " . key . " $(find conf/bconf/ -type f -name bconf\\.* \| grep -v '/\\.svn/')"), "\n")
    if len(options) == 0
        echo "No results found!"
        return
    endif
    let num_options = []
    for line in options 
        call add(num_options, ((len(num_options) + 1) . " " . line) )
    endfor
    let answer = input(join(num_options, "\n") . "\n")
    if !empty(answer)
        let selected = split(options[answer - 1], ":")
        execute "tabe " . selected[0]
        execute ":" . selected[1]
    endif
endfunction
noremap <C-b> :call FindBconfKey() <CR>

set wrap

" new options
" navigation
autocmd BufEnter * lcd %:p:h
set wildmode=longest:list
set path=.;~,/usr/include
set includeexpr=substitute(v:fname,'^\\(.*\\)$','templates/\\1.tmpl',)

" cursor line
se cursorline
hi CursorLine term=none cterm=none ctermbg=4
autocmd InsertLeave * hi CursorLine term=none cterm=none ctermbg=4
autocmd InsertEnter * hi CursorLine term=none cterm=none ctermbg=1 ctermfg=7

set runtimepath^=~/.vim/bundle/ctrlp.vim

" custom files: *.tmpl
augroup filetype
    au!
    au! BufRead,BufNewFile bconf.txt.* set filetype=cfg
    au! BufRead,BufNewFile mod_*.conf set filetype=apache
    au! BufRead,BufNewFile *.pgsql set filetype=sql
    au! BufRead,BufNewFile *.tmpl set filetype=tmpl
    au BufNewFile,BufRead Makefile set tw=0             " Makefile: ele adora usar linhas compridas malas
augroup END

