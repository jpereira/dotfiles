#!/bin/bash
# Author: Jorge Pereira <jpereiran@gmail.com>
# Data: Qui Dez 12 15:44:15 BRST 2013
###

batch_prefix="/tmp/jorge_settings"
batch="${batch_prefix}.$$"

# limpando...
ls /tmp/${batch_prefix//*\//}.* 1> /dev/null 2>&1 && {
    rm -f /tmp/${batch_prefix//*\//}.*
};

if [ -z "$1" ]; then
    cat <<EOF
Usage: $0 <opcao>

    push- Copia os arquivos do seu $HOME para $PWD
    pull - Copia os arquivos de $PWD para seu $HOME

EOF
    exit
fi

case $1 in
    pull)
        DIR_SRC="./dot."
        DIR_DST="$HOME/."

        #git pull
    ;;

    push)
        DIR_SRC="$HOME/."
        DIR_DST="./dot."

        #git push
    ;;

    *)
    echo "Opcao $1 invalida!"
    exit
esac

echo "Copiando os arquivos de ${DIR_SRC}* para $DIR_DST"

# main
all=0
for dot in $(find ./ -iname "dot.*"); do {
    dot="${dot//.\/dot./}"
    src="${DIR_SRC}${dot}"
    dst="${DIR_DST}${dot}"

    #echo "Debug: dot='$dot' src='$src' dst='$dst'"

    if [ "$src" = "." -o "$src" = ".." -o "$src" = "/" ] || [ "$dst" = "." -o "$dst" = ".." -o "$dst" = "/" ]; then
        echo "Algum problema na configuracao, saindo!"
        exit
    fi

    if [ ! -e "$src" ]; then
        echo "Arquivo de origem '$src' nao existe."
        exit
    fi

    #if [ -d "$src" ]; then
    #    echo "find $src -type d -iname .git -exec rm -rf {} \;"
    #fi

    if [ "$all" = "0" -a -f "$dst" ];then
        echo -n "AVISO: Arquivo de origem '$dst' existe, continuar? [s/n/A]"
        read opt
        if [ "$opt" = "A" ]; then
            all=1
        elif [ "$opt" != "s" ]; then
            rm -f "$batch"
            break
        fi
    fi

    echo "rm -rf '$dst'" >> $batch
    echo "cp -pRf '$src' '$dst'" >> $batch
} done

if [ ! -f "$batch" ]; then
    echo "Arquivo de batch '$batch' nao encontrado, saindo..."
    exit
fi

echo "Executando os comandos abaixo!"
cat -n $batch

echo -n "Deseja continuar? [s/n]"
read opt

if [ "$opt" != "s" ];then
    echo "Cancelado, saindo..."
else
    $SHELL $batch
    echo "Feito!"
fi

rm -f $batch

