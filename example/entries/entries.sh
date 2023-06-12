#!/bin/sh

# add a special header to all entries
cat << EOF
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>$1</title>
</head>
<body>
<h1>my blog</h1>
EOF

# make this page be the index if it is called with no arguments
[ -z "$1" ] && {
    cat << EOF
    <h2>blog entries</h2>
    <ul>
EOF
    # list all the files in the directory
    for file in *.md; do
        printf "<li><a href=\"%s\">%s</a></li>" "${file%.*}.html" "$file"
    done

    cat << EOF
    </ul>
EOF

} || {
    # convert the markdown page to html text
    md2html $1

    # add a back button
    cat << EOF
<span><a href="entries.html">go back to list</a></span>
EOF
}

# and a footer
cat << EOF
</body>
</html>
EOF

