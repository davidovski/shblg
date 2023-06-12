#!/bin/sh


line="hell 			o world"
# replace tabs with spaces
l="$line"
line=
while [ "$l" ]; do
    c="${l%*${l#?}}"
    case "$c" in
        "\t") line="$line    ";;
        *) line="$line$c" ;;
    esac
    l="${l#?}"
    printf "%s\n" "$c"
done
printf "%s\n" "$line"

