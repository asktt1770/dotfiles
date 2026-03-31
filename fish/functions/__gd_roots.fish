function __gd_roots --description "Navigate to folders within Google Drive"
    set -l selected (find -L ~/gd -mindepth 1 -maxdepth 2 -type d | fzf --height 40% --reverse)
    if test -n "$selected"
        cd "$selected"
        commandline -f repaint
    end
end
