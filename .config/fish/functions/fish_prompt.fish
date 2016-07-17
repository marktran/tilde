set __fish_git_prompt_char_dirtystate '⚡'
set __fish_git_prompt_color_branch yellow
set __fish_git_prompt_showdirtystate 'yes'

function fish_prompt
  set_pwd_color
  printf '%s' (prompt_pwd)
  set_color normal
  printf '%s ' (__fish_git_prompt)
end

function set_pwd_color
  if [ $SSH_CLIENT ]
     set_color blue
   else
     set_color magenta
  end
end
