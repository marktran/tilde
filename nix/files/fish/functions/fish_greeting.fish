function fish_greeting
    echo

    if type -q fortune
        fortune
    else if test -x /usr/games/fortune
        /usr/games/fortune
    end
end
