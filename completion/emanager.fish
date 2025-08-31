complete -c emanager -n "__fish_use_subcommand" -a "use" -d "Switch to a preset, loading its environment variables"
complete -c emanager -n "__fish_use_subcommand" -a "clear" -d "Clear any active environment variables set by emanager"
complete -c emanager -n "__fish_use_subcommand" -a "list" -d "List all available presets"
complete -c emanager -n "__fish_use_subcommand" -a "show" -d "Show the contents of a specific preset"
complete -c emanager -n "__fish_use_subcommand" -a "add" -d "Add or update a variable in a preset"
complete -c emanager -n "__fish_use_subcommand" -a "remove" -d "Remove a preset"
complete -c emanager -n "__fish_use_subcommand" -a "config" -d "Manage the configuration file path"

# Complete preset names for use, show, and remove commands
complete -c emanager -n "__fish_seen_subcommand_from use show remove" -a "(emanager list 2>/dev/null | grep '^- ' | sed 's/^- //')"

# Complete preset names for add command (second argument)
complete -c emanager -n "__fish_seen_subcommand_from add; and test (count (commandline -opc)) -eq 2" -a "(emanager list 2>/dev/null | grep '^- ' | sed 's/^- //')"

# Complete config subcommands
complete -c emanager -n "__fish_seen_subcommand_from config" -a "set-path" -d "Set the path to the presets JSON file"
complete -c emanager -n "__fish_seen_subcommand_from config" -a "get-path" -d "Get the current path of the presets JSON file"
