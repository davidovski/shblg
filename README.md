# shblg

a static site generator written (entirely) in posix shell

this repository contains two parts: md2html and shblg

## md2html

md2html provides a simple and lightweight way to render a markdown file into html

most standard markdown syntax works

### usage

when using standalone:

    md2html file.md > output.html

when using with shblg, prepend a shebang to your markdown file:

    #!/usr/bin/env md2html

## shblg

shblg is a static site generator that generates a site using a directory full of executable files

shblg recurses through this directory and executes files, sending their stdout to the rendered directory

the intended use is to use various interpreters for input pages to generate an output, for example `md2html` can be added through a shebang to allow the input markdown to be *"executed"* to output html.

shblg will ignore any files that are not executable and instead copy them directly, so ensure that any input files that need to be executed have the `+x` mode

shblg does not make any changes to the source filenames when generating its output, so ensure that you keep file extensions to match the output file's format

### example usage

for example, if you would like to use shblg to generate the site in `example/` and save the output in `html/`

    shblg -i example/ html/

