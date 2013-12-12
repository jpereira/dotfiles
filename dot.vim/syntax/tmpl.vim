" Vim syntax file
" Language: BlocketTemplates
" Maintainer:   Boris Cruchet <boris@schibsted.cl>
" Last Change: Wed 03 Apr 2013 10:33:10 AM BRT
"
" For version 0.3: 2013-03-01: Fix some errors and improve the vars recognition
" For version 0.2: 2012-10-03: Second version with a lot of improvements
" For version 0.1: 2012-06-01: first version.

syn match    tmplFilters    '|[a-zA-Z_]\+|' contained
syn region   tmplFilters    start='|[a-zA-Z_]\+' end="|" contained contains=tmplVar,tmplStringDouble

syn match    tmplFunc       '[$]\+([a-zA-Z_.*@%]\+)' contained containedin=tmplContext contains=tmplVar
syn match    tmplVar        '[%]\+[a-zA-Z_][a-zA-Z_0-9]\+' contained
syn match    tmplVar        '[@]\+[a-zA-Z_][a-zA-Z_0-9]\+' contained
syn match    tmplVar        '?[a-zA-Z_]\+' contained
syn match    tmplOperator   '[-=+^&*!.~:()]' contained containedin=tmplContext

syn region   tmplContext        matchgroup=Delimiter start='<%' end='%>' contains=tmplComment,tmplVar,tmplContext,tmplFunction,tmplFilters transparent
syn region   tmplComment        start='/\*' end='\*/' contained
syn region   tmplStringDouble   start='"' end='"' contains=allText,tmplVar,tmplBconfFunc contained containedin=tmplContext keepend
syn region   tmplFunction   start='&[a-zA-Z_]\+(' end=')' contained contains=tmplBconfFunc,tmplVar,tmplStringDouble

hi def link tmplFilters     Structure
hi def link tmplFunc        statement
hi def link tmplVar     Identifier
hi def link tmplOperator    delimiter

hi def link tmplContext        None
hi def link tmplComment        Comment
hi def link tmplStringDouble   String
hi def link tmplFunction       Function
