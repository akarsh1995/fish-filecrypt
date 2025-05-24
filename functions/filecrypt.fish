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
            echo "filecrypt version 1.0.0"
        case '*'
            echo "Unknown subcommand: $subcommand"
            echo "Available subcommands: config, encrypt, decrypt/restore, delete, list/ls, restore-all, version"
            return 1
    end
end

# Function to configure filecrypt settings
function _filecrypt_config
    if test (count $argv) -lt 1
        echo "Current configuration:"
        echo "  GPG Recipient: "(set -q FILECRYPT_GPG_RECIPIENT; and echo $FILECRYPT_GPG_RECIPIENT; or echo "(using default key)")
        echo ""
        echo "Usage: filecrypt config [set-recipient EMAIL]"
        echo "  set-recipient EMAIL   Set the GPG recipient for encryption"
        return 0
    end

    switch $argv[1]
        case set-recipient
            if test (count $argv) -lt 2
                echo "Please provide an email address or GPG key ID"
                return 1
            end
            set -U FILECRYPT_GPG_RECIPIENT "$argv[2]"
            echo "GPG recipient set to: $argv[2]"
        case '*'
            echo "Unknown config option: $argv[1]"
            echo "Available options: set-recipient"
            return 1
    end
end

# Function that encrypts a file and stores it in the encrypted registry
function _filecrypt_encrypt
    # Define paths for encrypted files registry
    set -l registry_path $XDG_CONFIG_HOME/fish/secure/files/registry.json.gpg

    # check if the first argument is empty (source file)
    if test -z "$argv[1]"
        echo "Please provide a source file path"
        return 1
    end

    # check if the source file exists
    if test ! -f "$argv[1]"
        echo "Source file does not exist: $argv[1]"
        return 1
    end

    # Get GPG recipient (configurable via universal variable)
    set -l gpg_recipient "$FILECRYPT_GPG_RECIPIENT"
    if test -z "$gpg_recipient"
        # Try to get default GPG key
        set gpg_recipient (gpg --list-secret-keys --keyid-format LONG | grep "^sec" | head -1 | awk '{print $2}' | cut -d'/' -f2)
        if test -z "$gpg_recipient"
            echo "Error: No GPG recipient configured. Set FILECRYPT_GPG_RECIPIENT or configure a default GPG key."
            echo "Example: set -U FILECRYPT_GPG_RECIPIENT 'your.email@example.com'"
            return 1
        end
    end

    # Get file content as base64 encoded string to store in JSON
    # set -l file_content (base64 -i "$argv[1]" | string collect)
    # Use -w 0 to disable line wrapping on Linux, string replace to remove any line breaks
    set -l file_content (cat "$argv[1]" | base64 -w 0 2>/dev/null || cat "$argv[1]" | base64 | string replace -a '\n' '')

    # Debug logging for encryption
    echo "DEBUG: Encrypting file: $argv[1]" >&2
    echo "DEBUG: File size: "(wc -c < "$argv[1]" | string trim)" bytes" >&2
    echo "DEBUG: Base64 content length: "(echo $file_content | wc -c | string trim) >&2
    echo "DEBUG: First 50 chars of base64: "(echo $file_content | head -c 50) >&2
    echo "DEBUG: Last 50 chars of base64: "(echo $file_content | tail -c 50) >&2

    # Prepare registry JSON content
    set -l json_content "{}"

    # If we have an existing registry file, decrypt it to memory
    if test -f $registry_path
        set json_content (gpg --quiet --decrypt $registry_path 2>/dev/null)
        if test $status -ne 0
            echo "Failed to decrypt registry file"
            return 1
        end
    end

    # Get description if provided, otherwise use a default
    set -l description "Encrypted file"
    if test (count $argv) -ge 2 -a ! -z "$argv[2]"
        set description "$argv[2]"
    end

    # Get absolute path for reliable storage
    set -l abs_source_path (realpath "$argv[1]")

    set -l modified_time ""
    # Get file modification time for versioning (cross-platform compatible)
    if test (uname) = Darwin
        # macOS
        set modified_time (stat -f "%Sm" -t "%Y-%m-%d %H:%M:%S" "$argv[1]")
    else
        # Linux
        set modified_time (stat -c "%y" "$argv[1]" | cut -d'.' -f1)
    end

    # Debug logging for modified time
    echo "DEBUG: Modified time: $modified_time" >&2
    echo "DEBUG: Platform: "(uname) >&2

    # Update the JSON registry with the new encrypted file info and content
    echo "DEBUG: Creating JSON entry..." >&2
    set -l new_json (echo $json_content | jq --arg source "$abs_source_path" --arg content "$file_content" \
       --arg desc "$description" --arg mtime "$modified_time" \
       '.[$source] = {"content": $content, "description": $desc, "modified_time": $mtime}')

    if test $status -ne 0
        echo "ERROR: Failed to create JSON entry" >&2
        return 1
    end

    echo "DEBUG: JSON entry created successfully" >&2
    echo "DEBUG: Encrypting to registry..." >&2
    echo "DEBUG: GPG Recipient: $gpg_recipient" >&2
    echo "DEBUG: Registry path: $registry_path" >&2

    echo $new_json | gpg --yes --recipient "$gpg_recipient" --encrypt --output $registry_path

    if test $status -ne 0
        echo "Failed to update encrypted files registry"
        return 1
    end

    echo "File encrypted successfully and stored in registry"
    echo "Original file path: $abs_source_path"

    # Check if --remove flag was used or ask the user about removing the original file
    set -l remove_file false

    for arg in $argv
        if test "$arg" = --remove
            set remove_file true
            break
        end
    end

    if not $remove_file
        read -l -P "Remove original file '$argv[1]'? [y/N] " confirm
        if string match -qi y $confirm
            set remove_file true
        end
    end

    # Securely remove the original file if requested
    if $remove_file
        # Check if shred command exists
        if command -sq shred
            # Use shred to securely delete the file (-u removes the file after overwriting)
            shred -u -z "$argv[1]"
            if test $status -eq 0
                echo "Original file securely shredded."
            else
                echo "Warning: Failed to securely shred original file."
            end
        else
            # If shred doesn't exist, use rm but warn the user
            echo "Warning: 'shred' command not found. Using standard rm which is less secure."
            rm "$argv[1]"
            if test $status -eq 0
                echo "Original file removed (not securely shredded)."
            else
                echo "Warning: Failed to remove original file."
            end
        end
    end
end

# Function to restore an encrypted file from the registry
function _filecrypt_restore
    # Define paths for encrypted files registry
    set -l registry_path $XDG_CONFIG_HOME/fish/secure/files/registry.json.gpg

    # Check if registry exists
    if test ! -f $registry_path
        echo "No encrypted files registry found."
        return 1
    end

    # Decrypt the registry directly to memory
    set -l decrypted_content (gpg --quiet --decrypt $registry_path 2>/dev/null)
    if test $status -ne 0
        echo "Failed to decrypt registry file"
        return 1
    end

    # Debug: Show registry structure
    echo "DEBUG: Registry decrypted successfully" >&2
    echo "DEBUG: Registry content length: "(echo $decrypted_content | wc -c | string trim) >&2
    echo "DEBUG: Registry keys: "(echo $decrypted_content | jq -r 'keys | join(", ")' 2>/dev/null || echo "Failed to parse JSON") >&2

    # check if the first argument is empty (original file path)
    if test -z "$argv[1]"
        echo "Please provide the original file path to restore"
        return 1
    end

    # Get absolute path for reliable lookup
    set -l abs_source_path (realpath "$argv[1]" 2>/dev/null || echo "$argv[1]")

    # Check if the file exists in registry
    if not echo $decrypted_content | jq -e --arg source "$abs_source_path" 'has($source)' >/dev/null
        echo "No entry found for: $abs_source_path"
        return 1
    end

    # Get the file content from the registry
    set -l file_content (echo $decrypted_content | jq -r --arg source "$abs_source_path" '.[$source].content')
    set -l modified_time (echo $decrypted_content | jq -r --arg source "$abs_source_path" '.[$source].modified_time')

    # Debug logging
    echo "DEBUG: Restoring file: $abs_source_path" >&2
    echo "DEBUG: Modified time: $modified_time" >&2
    echo "DEBUG: Base64 content length: "(echo $file_content | wc -c | string trim) >&2
    echo "DEBUG: First 50 chars of base64: "(echo $file_content | head -c 50) >&2
    echo "DEBUG: Last 50 chars of base64: "(echo $file_content | tail -c 50) >&2

    # Check if file_content is valid
    if test -z "$file_content"
        echo "ERROR: No file content found in registry" >&2
        return 1
    end

    # Set the destination path
    set -l dest_path "$abs_source_path"
    set -l custom_destination false

    if test (count $argv) -ge 2 -a ! -z "$argv[2]"
        set dest_path "$argv[2]"
        set custom_destination true
    end

    # Create directory structure if it doesn't exist
    set -l dir_path (dirname "$dest_path")
    mkdir -p "$dir_path"

    # Debug: Test base64 decoding first
    echo "DEBUG: Testing base64 decode..." >&2
    # Clean any whitespace from base64 content before decoding
    set -l clean_content (echo $file_content | string replace -a ' ' '' | string replace -a '\n' '' | string replace -a '\t' '')
    echo "DEBUG: Cleaned base64 length: "(echo $clean_content | wc -c | string trim) >&2
    echo "DEBUG: Cleaned base64 content: $clean_content" >&2

    set -l test_decode (echo $clean_content | base64 -d 2>&1)
    set -l decode_status $status
    echo "DEBUG: Base64 decode test status: $decode_status" >&2

    if test $decode_status -ne 0
        echo "ERROR: Base64 decode failed with error: $test_decode" >&2
        echo "DEBUG: Original base64 content that failed:" >&2
        echo "$file_content" >&2
        return 1
    end

    # Decode base64 content and write to file (use cleaned content)
    echo $clean_content | base64 -d >"$dest_path"

    if test $status -ne 0
        echo "Failed to restore file"
        return 1
    end

    # Try to set the original modification time
    if test ! -z "$modified_time"
        touch -d "$modified_time" "$dest_path" 2>/dev/null
        # If touch -d fails (e.g., on macOS), try alternative format
        if test $status -ne 0
            touch -t (echo $modified_time | string replace -a "-" "" | string replace -a ":" "" | string replace " " "") "$dest_path" 2>/dev/null
        end
    end

    if $custom_destination
        echo "File restored successfully to custom location: $dest_path"
        echo "Original file path: $abs_source_path"
    else
        echo "File restored successfully to original path: $dest_path"
    end

    if test ! -z "$modified_time"
        echo "Original modified time: $modified_time"
    end
end

# Function to delete an entry from the encrypted files registry
function _filecrypt_delete
    # Define paths for encrypted files registry
    set -l registry_path $XDG_CONFIG_HOME/fish/secure/files/registry.json.gpg

    # check if the first argument is empty (original file path)
    if test -z "$argv[1]"
        echo "Please provide the original file path to delete from registry"
        return 1
    end

    # Check if registry exists
    if test ! -f $registry_path
        echo "No encrypted files registry found."
        return 1
    end

    # Decrypt the registry directly to memory
    set -l decrypted_content (gpg --quiet --decrypt $registry_path 2>/dev/null)
    if test $status -ne 0
        echo "Failed to decrypt registry file"
        return 1
    end

    # Get absolute path for reliable lookup
    set -l abs_source_path (realpath "$argv[1]" 2>/dev/null || echo "$argv[1]")

    # Check if the file exists in registry
    if not echo $decrypted_content | jq -e --arg source "$abs_source_path" 'has($source)' >/dev/null
        echo "No entry found for: $abs_source_path"
        return 1
    end

    # Get description for reporting
    set -l description (echo $decrypted_content | jq -r --arg source "$abs_source_path" '.[$source].description')

    # Ask for confirmation if --force flag is not provided
    set -l force false
    for arg in $argv
        if test "$arg" = --force
            set force true
            break
        end
    end

    if not $force
        read -l -P "Delete entry for '$abs_source_path' ($description)? [y/N] " confirm
        if not string match -qi y $confirm
            echo "Operation cancelled."
            return 0
        end
    end

    # Get GPG recipient (configurable via universal variable)
    set -l gpg_recipient "$FILECRYPT_GPG_RECIPIENT"
    if test -z "$gpg_recipient"
        # Try to get default GPG key
        set gpg_recipient (gpg --list-secret-keys --keyid-format LONG | grep "^sec" | head -1 | awk '{print $2}' | cut -d'/' -f2)
        if test -z "$gpg_recipient"
            echo "Error: No GPG recipient configured. Set FILECRYPT_GPG_RECIPIENT or configure a default GPG key."
            return 1
        end
    end

    # Remove the entry from the registry
    echo $decrypted_content | jq --arg source "$abs_source_path" 'del(.[$source])' | gpg --quiet --yes --recipient "$gpg_recipient" --encrypt --output $registry_path

    if test $status -ne 0
        echo "Failed to update registry file"
        return 1
    end

    echo "Registry entry deleted successfully."
end

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

# Function to restore multiple or all encrypted files
function _filecrypt_restore_all
    # Define paths for encrypted files registry
    set -l registry_path $XDG_CONFIG_HOME/fish/secure/files/registry.json.gpg
    set -l pattern "*" # Default pattern to match all files
    set -l output_dir "" # Default is to restore to original locations

    # Parse arguments for flags and pattern
    for i in (seq (count $argv))
        switch $argv[$i]
            case --pattern
                if test (count $argv) -gt $i
                    set pattern $argv[(math $i + 1)]
                end
            case --output-dir
                if test (count $argv) -gt $i
                    set output_dir $argv[(math $i + 1)]
                end
            case --help
                echo "Usage: filecrypt restore-all [--pattern GLOB_PATTERN] [--output-dir DIRECTORY]"
                echo "  --pattern PATTERN    Only restore files matching the glob pattern"
                return 0
        end
    end

    # Check if registry exists
    if test ! -f $registry_path
        echo "No encrypted files registry found."
        return 1
    end

    # Decrypt the registry directly to memory
    set -l decrypted_content (gpg --quiet --decrypt $registry_path 2>/dev/null)
    if test $status -ne 0
        echo "Failed to decrypt registry file"
        return 1
    end

    # Extract all file paths from the registry
    set -l files (echo $decrypted_content | jq -r 'keys[]')

    set -l restored_count 0
    set -l failed_count 0

    echo "Restoring encrypted files..."

    # Process each file
    for file in $files
        # Apply pattern matching
        if not string match -q "$pattern" $file
            continue
        end

        echo "Restoring: $file"

        # Get the file content from the registry
        set -l file_content (echo $decrypted_content | jq -r --arg source "$file" '.[$source].content')
        set -l modified_time (echo $decrypted_content | jq -r --arg source "$file" '.[$source].modified_time')

        # Determine the output path
        set -l output_path "$file"

        # If output directory is specified, adjust the path
        if test ! -z "$output_dir"
            # For absolute paths, we need to preserve the path structure but under output_dir
            if string match -q "/*" "$file"
                # Extract the relative path by removing the leading /
                set -l relative_path (string replace -r "^/" "" "$file")
                set output_path "$output_dir/$relative_path"
            else
                set output_path "$output_dir/$file"
            end
        end

        # Create directory structure if it doesn't exist
        set -l dir_path (dirname "$output_path")
        mkdir -p "$dir_path"

        # Decode base64 content and write to file
        # Clean any whitespace from base64 content before decoding
        set -l clean_content (echo $file_content | string replace -a ' ' '' | string replace -a '\n' '' | string replace -a '\t' '')
        echo $clean_content | base64 -d >"$output_path"

        if test $status -ne 0
            echo "  ❌ Failed to restore file"
            set failed_count (math $failed_count + 1)
        else
            # Try to set the original modification time
            if test ! -z "$modified_time"
                touch -d "$modified_time" "$output_path" 2>/dev/null
                # If touch -d fails (e.g., on macOS), try alternative format
                if test $status -ne 0
                    touch -t (echo $modified_time | string replace -a "-" "" | string replace -a ":" "" | string replace " " "") "$output_path" 2>/dev/null
                end
            end

            if test "$output_path" != "$file"
                echo "  ✅ Successfully restored to: $output_path (original: $file)"
            else
                echo "  ✅ Successfully restored to: $output_path"
            end
            set restored_count (math $restored_count + 1)
        end
    end

    echo --------------------------------------------------------------------------------
    echo "Restoration complete: $restored_count files restored, $failed_count files failed"
end

# Function to get all registry entries
function __filecrypt_registry_entries
    set -l registry_path $XDG_CONFIG_HOME/fish/secure/files/registry.json.gpg
    if test -f $registry_path
        gpg --quiet --decrypt $registry_path 2>/dev/null | jq -r 'keys[]'
    end
end
