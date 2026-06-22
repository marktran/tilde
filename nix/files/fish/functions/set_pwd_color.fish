function set_pwd_color
    if test -n "$SSH_CLIENT"
        set_color blue
    else
        set_color magenta
    end
end
