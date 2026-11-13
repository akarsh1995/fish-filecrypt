# A comprehensive file encryption and management tool for fish shell
function filecrypt
    # Check if a subcommand is provided
    if test (count $argv) -lt 1
        echo "Usage: filecrypt [config|encrypt|decrypt|list|delete|restore-all|version] [arguments...]"
        return 1
    end

    set -l subcommand $argv[1]
    set -l subcommand_args $argv[2..-1]

    switch $subcommand
        case config
            # Call the config function
            _filecrypt_config $subcommand_args
        case encrypt
            # Call the encrypt function
            _filecrypt_encrypt $subcommand_args
        case decrypt restore
            # Call the decrypt/restore function (both names supported)
            _filecrypt_restore $subcommand_args
        case delete
            # Call the delete function
            _filecrypt_delete $subcommand_args
        case list ls
            # Call the list function (both names supported)
            _filecrypt_list $subcommand_args
        case restore-all
            # Call the restore-all function
            _filecrypt_restore_all $subcommand_args
        case version
            # Display version information
            echo "filecrypt version 1.0.1"
        case '*'
            echo "Unknown subcommand: $subcommand"
            echo "Available subcommands: config, encrypt, decrypt/restore, delete, list/ls, restore-all, version"
            return 1
    end
end
