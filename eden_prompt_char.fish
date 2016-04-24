function eden_prompt_char -d "Set custom prompt char, or reset to \"»\" without argument."
  switch (count $argv)
    case 0
      set -U THEME_EDEN_PROMPT_CHAR '»'
      echo 'Using default prompt char: »'
    case 1
      set -U THEME_EDEN_PROMPT_CHAR $argv[1]
      echo $argv[1]
  end
end
