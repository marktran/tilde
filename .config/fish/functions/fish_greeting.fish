function fish_greeting
  echo

  if command -s fortune > /dev/null 2>&1
    fortune
  else
    /usr/games/fortune
  end
end
