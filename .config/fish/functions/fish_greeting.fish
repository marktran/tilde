function fish_greeting
  echo

  if type -q fortune
    fortune
  else
    /usr/games/fortune
  end
end
