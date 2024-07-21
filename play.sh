#!/bin/sh

# Half-cooked REPL to play with dsv.awk.

usage() {
    echo "usage: $0 [-h] [--] [<prog> ...]"
    [ "$1" == -h ] && cat <<-'END'
Runs the input Awk program in DSV mode.

The program can be given on the command line as a sequence of fragments. All
fragments will be joined together with interleaved spaces. If nothing is given
on the command line, the program will be read from standard input.

The input to Awk will always be read from standard input.

To read both the program and the input from standard input, send an EOF (^D)
after the program, then type the input.
END
    exit 2
}

getopts h _ && usage "-$o"
[ "$1" == -- ] && shift

if [ $# -eq 0 ]; then
    cat
else
    echo "$@"
fi |
awk -f dsv.awk -f- /dev/tty
