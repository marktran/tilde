function ls
    if command ls --version 1>/dev/null 2>/dev/null
        # GNU ls
        set -l param --color=auto
        if isatty 1
            set param $param --indicator-style=classify
        end

        if not set -q LS_COLORS; and type -f dircolors >/dev/null
            eval (dircolors -c)
        end

        command ls -N -F $param $argv
    else if command ls -G / 1>/dev/null 2>/dev/null
        # BSD/macOS ls
        command ls -FG $argv
    else
        command ls $argv
    end
end
