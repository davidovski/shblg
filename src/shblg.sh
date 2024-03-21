#!/bin/sh

INPUT_DIR=blog
OUTPUT_DIR=dist

usage () {
    printf "%s\n" "Usage: shblg [-i input_dir] [-o output_dir]"
    exit 1
}

# check if a file has changed since last generating
#
newer () {
    # TODO account for dependencies that have change
    [ ! -e "$2" ] || [ "$1" -nt "$2" ]
}

while getopts ":o:i:h" opt; do
    case "$opt" in
        o)
            OUTPUT_DIR="$OPTARG/"
            mkdir -p "$OUTPUT_DIR"
            OUTPUT_DIR="$(realpath "$OUTPUT_DIR")"
            ;;
        i)
            INPUT_DIR="$(realpath "$OPTARG")"
            ;;
        *) usage
            ;;
    esac
done

# process a file to 
process () {
    path="${1#"$INPUT_DIR"}"
    dirpath="${1%"${1##*/}"}"
    out_file="${OUTPUT_DIR}${path}"


    [ -d "$1" ] && {

        mkdir -p "$out_file"
        for f in "$1"/*; do
            process "$f"
        done

        return 0
    } || [ -x "$1" ] && {
        newer "$1" "$out_file" && (
                # execute the file
                cd $dirpath
                printf "#!%s\n" "$path"
                "$1" > "$out_file"
            )
        return 0
    } || {
        newer "$1" "$out_file" && (
            # just copy the file as is
            printf "%s\n" "$path"
            cp "$1" "$out_file"
        )
        return 0
    }
}

process "$INPUT_DIR"
