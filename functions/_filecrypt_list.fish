# Function to list all encrypted files in the registry
function _filecrypt_list
    set -l registry_path $XDG_CONFIG_HOME/fish/secure/files/registry.json.gpg
    set -l show_details false

    # Parse arguments
    for arg in $argv
        switch $arg
            case --details
                set show_details true
        end
    end

    if test ! -f $registry_path
        echo "No encrypted files registry found."
        return 1
    end

    # Decrypt the registry file directly to memory
    set -l decrypted_content (gpg --quiet --decrypt $registry_path 2>/dev/null)
    if test $status -ne 0
        echo "Failed to decrypt registry file"
        return 1
    end

    # Create a formatted list of encrypted files and their descriptions
    echo "Encrypted Files:"
    echo --------------------------------------------------------------------------------

    if $show_details
        # Parse the JSON and format the output with additional details
        echo $decrypted_content | jq -r 'to_entries | .[] | "\(.key) - \(.value.description) (Modified: \(.value.modified_time // "unknown"))"' | sort
    else
        # Parse the JSON and format the output with just path and description
        echo $decrypted_content | jq -r 'to_entries | .[] | "\(.key) - \(.value.description)"' | sort
    end
end
