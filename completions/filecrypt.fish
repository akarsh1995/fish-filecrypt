# Completions for the filecrypt command

# Define subcommands with descriptions
set -l subcommands "config encrypt decrypt restore delete list ls restore-all"

# Complete subcommands
complete -c filecrypt -f -n "__fish_use_subcommand" -a "config" -d "Configure filecrypt settings"
complete -c filecrypt -f -n "__fish_use_subcommand" -a "encrypt" -d "Encrypt a file and add to registry"
complete -c filecrypt -f -n "__fish_use_subcommand" -a "decrypt" -d "Restore an encrypted file (alias for restore)"
complete -c filecrypt -f -n "__fish_use_subcommand" -a "restore" -d "Restore an encrypted file"
complete -c filecrypt -f -n "__fish_use_subcommand" -a "delete" -d "Delete an entry from registry"
complete -c filecrypt -f -n "__fish_use_subcommand" -a "list" -d "List all encrypted files"
complete -c filecrypt -f -n "__fish_use_subcommand" -a "ls" -d "List all encrypted files (alias for list)"
complete -c filecrypt -f -n "__fish_use_subcommand" -a "restore-all" -d "Restore multiple or all encrypted files"

# Reuse the registry entries function from the main script
# This is defined in filecrypt.fish

# Completions for specific subcommands
# For 'config' subcommand
complete -c filecrypt -f -n "__fish_seen_subcommand_from config" -a "set-recipient" -d "Set GPG recipient for encryption"

# For 'encrypt' subcommand
complete -c filecrypt -f -n "__fish_seen_subcommand_from encrypt" -a "(find . -type f -not -path '*/\.git/*')" -d "File to encrypt"
complete -c filecrypt -f -n "__fish_seen_subcommand_from encrypt" -l remove -d "Remove original file after encryption"

# For 'decrypt/restore' subcommand - complete with registry entries
complete -c filecrypt -f -n "__fish_seen_subcommand_from decrypt restore" -a "(__filecrypt_registry_entries)" -d "File to restore"

# For 'delete' subcommand - complete with registry entries
complete -c filecrypt -f -n "__fish_seen_subcommand_from delete" -a "(__filecrypt_registry_entries)" -d "Registry entry to delete"
complete -c filecrypt -f -n "__fish_seen_subcommand_from delete" -l force -d "Delete without confirmation"

# For 'list/ls' subcommand - complete with options
complete -c filecrypt -f -n "__fish_seen_subcommand_from list ls" -l details -d "Show additional details including modification times"

# For 'restore-all' subcommand - complete with options
complete -c filecrypt -f -n "__fish_seen_subcommand_from restore-all" -l pattern -d "Only restore files matching the glob pattern" -r
complete -c filecrypt -f -n "__fish_seen_subcommand_from restore-all" -l output-dir -d "Restore all files to this directory" -r -a "(__fish_complete_directories)"
complete -c filecrypt -f -n "__fish_seen_subcommand_from restore-all" -l help -d "Display help message"
