function cppath --description 'Print a file/dir absolute path and copy it to the clipboard'
    if test (count $argv) -eq 0
        set argv .
    end

    set -l target $argv[1]

    if not test -e $target
        echo "No such file or directory: $target" >&2
        return 1
    end

    set -l abspath (realpath -- $target)

    echo $abspath
    echo -n $abspath | pbcopy
end
