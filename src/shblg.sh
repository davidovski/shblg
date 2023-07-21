#!/bin/sh

INPUT_DIR=blog
OUTPUT_DIR=dist

usage () {
    printf "%s\n" "Usage: shblg [-i input_dir] [-o output_dir]"
    exit 1
}

while getopts ":o:i:h" opt; do
    case "$opt" in
        o)
            OUTPUT_DIR=$OPTARG/
            mkdir -p $OUTPUT_DIR
            OUTPUT_DIR=$(realpath $OUTPUT_DIR)
            ;;
        i)
            INPUT_DIR=$(realpath $OPTARG)
            ;;
        h)
            usage
            ;;
    esac
done

# process a file to 
process () {
    path="${1#$INPUT_DIR}"
    dirpath="${1%${1##*/}}"
    out_file="${OUTPUT_DIR}${path}"

    printf "%s ...\n" "$path"

    [ -d "$1" ] && {
        mkdir -p "$out_file"
        for f in "$1"/*; do
            process "$f"
        done 
        return 0
    } || [ -x "$1" ] && {
        # execute the file
        cd $dirpath
        "$1" > "${out_file}"
        cd -
        return 0
    } || {
        # just copy the file as is
        cp "$1" "$out_file"
        return 0
    }
}

process "$INPUT_DIR"
