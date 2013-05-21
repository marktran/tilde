function prepend_to_path
  if test -d $argv[1]
    set -gx PATH "$argv[1]" $PATH
  end
end
