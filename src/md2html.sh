#!/bin/sh

# replace all * with _ for easier processing
#
_pre_emph () {
    while IFS= read -r line; do
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
        # TODO: avoid this problem entirely?

        local wrong="</strong></em>" right="</em></strong>"

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
    local bound="$1"
    local lefttag="$2" righttag="$3"

    while IFS= read -r line; do
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
    local num=$1
    while IFS= read -r line; do
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
            "#"*|">"*|"``"*)
                printf "%s\n" "$line"
                ;;
            "") 
                $empty ||
                    printf "</p>\n"
                
                empty=true ;;
            *) 
                $empty &&
                    printf "<p>%s " "$line" ||
                    printf "%s " "$line"

                empty=false ;;
        esac

    done

    $empty || {
        printf "</p>\n"
    }
}

# parse ref-style links
#
_ref () {
}

# parse links
#
_a_img () {
    local open="[" mid="](" close=")"
    while IFS= read -r line; do
                next="$line"
                while [ "$next" != "${next#*$close}" ]; do
                    before="${next%%$open*}"
                    text=${next#*$open} text=${text%%$mid*}
                    url=${next#*$mid} url=${url%%$close*}

                    title=${url#* } url=${url%% *}

                    [ "$title" != "$url" ] \
                        && title=" title=$title" \
                        || title=

                    case "$before" in
                        *!) h="%s<img src=\"%s\"%s alt=\"%s\"></img>" 
                            before="${before%!}" ;;
                        *) h="%s<a href=\"%s\"%s>%s</a>" ;;
                    esac

                    printf "$h" "$before" "$url" "$title" "$text"

                    next="${next#*$close}"
                done
                printf "%s\n" "$next";
    done
}

# parse unordered lists
#
_ul () {
}

# parse ordered lists
#
_ol () {
}

# parse mutliline codeblocks
#
_code () {
}

# parse quotes
#
_quote () {
}


# convert the markdown from stdin into html
#
md2html () {

            _p \
            | _pre_emph \
            | _emph '__' "<strong>" "</strong>" \
            | _emph '_' "<em>" "</em>" \
            | _emph '`' "<code>" "</code>" \
            | _post_emph \
            | _a_img \
            | _h 6 \
            | _h 5 \
            | _h 4 \
            | _h 3 \
            | _h 2 \
            | _h 1 
}

md2html

