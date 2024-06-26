#!/bin/sh

ESC_SEQ='\0'

cat () {
    while IFS= read -r line; do printf "%s\n" "$line"; done < "$1"
}

# remove a shebang from the start of the file
_remove_shebang () {
    IFS= read -r line
    case "$line" in
        "#!"*) ;;
        *) printf "%s\n" "$line"
    esac

    while IFS= read -r line; do
        printf "%s\n" "$line"
    done
}

# remove traling whitespace from empty lines
#
_pre_strip () {
    while IFS= read -r line; do
        set -- $line
        [ "$*" ] && {
            l="$line"
            line=
            while [ "$l" != "${l#?}" ]; do
                c="${l%*"${l#?}"}"
                case "$c" in
                    "    ") line="$line    ";;
                    *) line="$line$c" ;;
                esac
                l="${l#?}"
            done

            printf "%s\n" "$line"
        } || printf "\n"
    done
}

# replace all * with _ for easier processing
#
_pre_emph () {
    while IFS= read -r line; do
        case "$line" in "$ESC_SEQ"*) printf "%s\n" "$line" && continue;; esac
        while [ "$line" != "${line%%\**}" ]; do
            printf "%s_" "${line%%\**}"
            line="${line#*\*}"
        done
        printf "%s\n" "${line}"
    done
}


# fix any misaligned <em> and <strong> closign tags
#
_post_emph () {
    while IFS= read -r line; do
        case "$line" in "$ESC_SEQ"*) printf "%s\n" "$line" && continue;; esac
        # TODO: avoid this problem entirely?

        wrong="</strong></em>" right="</em></strong>"

        while [ "$line" != "${line%%${wrong}*}" ]; do
            printf "%s${right}" "${line%%${wrong}*}"
            line="${line#*${wrong}}"
        done
        printf "%s\n" "${line}"
    done
}

# parse emphasis in a line
#
#   emph [bound] <lefttag> <righttag>
#
_emph () {
    bound="$1"
    lefttag="$2"
    righttag="$3"

    while IFS= read -r line; do
        case "$line" in "$ESC_SEQ"*) printf "%s\n" "$line" && continue;; esac
        next="${line}"
        line=
        rightofbold=

        while [ "$next" != "${next#*${bound}}" ]; do
            leftofbold="${next%%${bound}*}"
            rightofbold="${next#$leftofbold${bound}*}"
            bold="${rightofbold%%${bound}*}"
            next="${rightofbold#*${bound}}"
            printf "%s%s%s%s" "${leftofbold}" "${lefttag}" "${bold}" "${righttag}"
        done
        printf "%s\n" "${next}"
    done
}

# parse heading
#
#   h [heading no.]
#
_h () {
    num=$1
    while IFS= read -r line; do
        case "$line" in "$ESC_SEQ"*) printf "%s\n" "$line" && continue;; esac
        s=

        n=$num
        while [ "$n" -gt "0" ]; do
            s="#$s"
            n=$((n-1))
        done

        case "$line" in
            "$s "*)
                printf "<h$num>%s</h$num>\n" "${line#$s }"
                ;;
            *)
                printf "%s\n" "$line"
                ;;
        esac
    done
}

# parse paragraphs
#
_p () {
    empty=true
    while IFS= read -r line; do
        case "$line" in
            "$ESC_SEQ"*) printf "%s\n" "$line" && continue;;
            "#"*|">"*|'``'*|'<'*'>'*)
                $empty || {
                    printf "</p>\n"
                    empty=true 
                }
                printf "%s\n" "$line"
                ;;
            "")
                $empty || {
                    printf "</p>\n"
                    empty=true
                }
                ;;
            *)
                $empty &&
                    printf "<p>\n%s\n" "$line" ||
                    printf "%s\n" "$line"

                empty=false ;;
        esac
    done

    $empty || {
        printf "</p>\n"
    }
}

# parse ref-style links
#
#_ref () {
#}

# parse links
#
_a_img () {
    open="[" mid="](" close=")"
    while IFS= read -r line; do
        case "$line" in "$ESC_SEQ"*) printf "%s\n" "$line" && continue; esac
        next="$line"
        while [ "$next" != "${next#*$close}" ]; do
            case "$next" in
                *"["*"]("*")"*);;
                *) break;
            esac
            before="${next%%$open*}"
            text=${next#*$open} text=${text%%$mid*}
            url=${next#*$mid} url=${url%%$close*}

            title=${url#* } url=${url%% *}

            [ "$title" != "$url" ] \
                && title=" title=$title" \
                || title=

            case "$before" in
                *!) h="%s\n%s<img src=\"%s\"%s alt=\"%s\"></img>\n"
                    before="${before%!}" ;;
                *) h="%s\n%s<a href=\"%s\"%s>\n%s</a>\n" ;;
            esac

            printf "$h" "$before" "$ESC_SEQ" "$url" "$title" "$text"

            next="${next#*$close}"
        done
        printf "%s\n" "$next";
    done
}

# get indentation level of a line
#
_get_indent () {
    indent=0
    l="$*"
    while [ "$l" ]; do
        c="${l%*"${l#?}"}"
        case "$c" in
            " ") indent=$((indent+1)) ;;
            *) 
                l="${l#?}"
                break
            ;;
        esac
        l="${l#?}"
    done
    printf "%s" "$indent"
}

# print a string x times
#
#   print_x x "string"
print_x () {
    x=$1; shift
    until [ "$((x=x-1))" -lt "0" ]; do
        printf "%s" "$*"
    done
}


# parse unordered lists
#
_ul () {
    indent_level=-1
    to_close=0
    while IFS= read -r line; do
        case "$line" in "$ESC_SEQ"*) printf "%s\n" "$line" && continue;; esac
        set -- $line
        case "$1" in 
            "-"|"_"|"+")
                indent=$(_get_indent "$line")

                [ "$indent_level" -lt "$indent" ] && {
                    printf "<ul>\n"
                    to_close=$((to_close+1))
                }
                [ "$indent_level" -gt "$indent" ] && {
                    printf "</ul>\n" 
                    to_close=$((to_close-1))
                }
                indent_level=$indent

                printf "<li>%s</li>\n" "${line#*$1 }"
                ;;
            *)
                [ $to_close -gt 0 ] && {
                    print_x $to_close "</ul>\n"
                    to_close=0
                    indent_level=-1
                }
                printf "%s\n" "$line"
                ;;
        esac
    done
    print_x $to_close "</ul>\n"
}

# parse ordered lists
#
_ol () {
    indent_level=-1
    to_close=0
    while IFS= read -r line; do
        case "$line" in "$ESC_SEQ"*) printf "%s\n" "$line" && continue;; esac
        set -- $line
        case "$1" in
            *.|*\))
                indent=$(_get_indent "$line")

                [ "$indent_level" -lt "$indent" ] && {
                    printf "<ol>\n"
                    to_close=$((to_close+1))
                }
                [ "$indent_level" -gt "$indent" ] && {
                    printf "</ol>\n"
                    to_close=$((to_close-1))
                }
                indent_level=$indent

                printf "<li>%s</li>\n" "${line#*$1 }"
                ;;
            *)
                [ $to_close -gt 0 ] && {
                    print_x $to_close "</ol>\n"
                    to_close=0
                    indent_level=-1
                }
                printf "%s\n" "$line"
                ;;
        esac
    done
    print_x $to_close "</ol>\n"
}

# parse inline codeblocks
#
_inline_code () {
    _emph '`' "
$ESC_SEQ<code>" "</code>
"
}

# parse multiline codeblocks
#
_code () {
    codeblock=false content=true
    while IFS= read -r line; do
        case "$line" in
            "    "*)
                # prefix lines with newline to avoid trailing newline
                $codeblock &&
                    printf "\n%s" "$ESC_SEQ${line#    }" ||
                $content || {
                    printf "%s<pre><code>%s" "$ESC_SEQ" "${line#    }"
                    codeblock=true
                }
                ;;
            "")
                $codeblock \
                    && printf "\n%s" "$ESC_SEQ" \
                    || printf "\n"
                    ;;
            *)
                $codeblock && {
                    printf "</code></pre>\n"
                    codeblock=false
                }

                printf "%s\n" "$line"
                ;;
        esac
        case "$line" in
            "") content=false ;;
            *) content=true ;;
        esac
    done
}

# parse quotes
#
_blockquote () {
    indent_level=0
    while IFS= read -r line; do
        case "$line" in "$ESC_SEQ"*) printf "%s\n" "$line" && continue;; esac
        set - $line
        case "$1" in
            ">"*)
                indent=0
                while [ "$line" ]; do
                    c="${line%*${line#?}}"
                    case "$c" in
                        ">") indent=$((indent+1)) ;;
                        " "*) 
                            line="${line#?}"
                            break
                        ;;
                    esac
                    line="${line#?}"
                done

                print_x $((indent-indent_level)) "<blockquote>\n"
                print_x $((indent_level-indent)) "</blockquote>\n"
                indent_level=$indent
                ;;
        esac
        printf "%s\n" "$line"
    done
    print_x $((indent_level)) "</blockquote>\n"
}

# add html header
#
_html () {
    printf "<!DOCTYPE html>\n"
    while IFS= read -r line; do
        printf "%s\n" "$line"
    done
}

# remove all unecessary newlines
#
_squash () {
    while IFS= read -r line; do
        case "$line" in
            "$ESC_SEQ"*)
                printf "\n%s" "${line#??}"
                ;;
            *)
                printf "%s" "$line"
                ;;
        esac
    done
    printf "\n"
}


# convert the markdown from stdin into html
#
md2html () {
    _remove_shebang \
    | _pre_strip \
    | _code \
    | _pre_emph \
    | _blockquote \
    | _ul \
    | _ol \
    | _p \
    | _a_img \
    | _inline_code \
    | _emph '__' "<strong>" "</strong>" \
    | _emph '_' "<em>" "</em>" \
    | _post_emph \
    | _h 6 \
    | _h 5 \
    | _h 4 \
    | _h 3 \
    | _h 2 \
    | _h 1 \
    | _squash
}

[ -z "$*" ] \
    && md2html \
    || md2html < "$1"
