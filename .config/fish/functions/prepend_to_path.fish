function prepend_to_path -d "Prepend the given directory, if it exists, to \$PATH"
  if test -d $argv[1]
    set -gx PATH "$argv[1]" $PATH
  end
end
