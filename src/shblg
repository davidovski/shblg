#!/bin/sh

INPUT_DIR=blog
OUTPUT_DIR=dist
PAGE_TEMPLATE=blog/template.html

while getopts ":o:i:t:" opt; do
    case "$opt" in
        o)
            OUTPUT_DIR=$OPTARG/
            mkdir -p $OUTPUT_DIR
            OUTPUT_DIR=$(realpath $OUTPUT_DIR)
            ;;
        i)
            INPUT_DIR=$(realpath $OPTARG)
            ;;
        t)
            PAGE_TEMPLATE=$(realpath $OPTARG)
            ;;
    esac
done

# process a file to 
process () {
    path="${1#$INPUT_DIR}"
    dirpath="${1%${1##*/}}"
    out_file="${OUTPUT_DIR}${path}"

    [ -d "$1" ] && {
        mkdir -p "$out_file"
        for f in "$1"/*; do
            process "$f"
        done 
        return 0
    } || [ -x "$1" ] && {
        # execute the file
        cd $dirpath
        "$1" > "${out_file%.*}.html"
        cd -
        return 0
    } || {
        # just output the file as is
        while IFS= read -r line; do printf "%s\n" "$line"; done < "$1" > "$out_file"
        return 0
    }
}

process "$INPUT_DIR"
