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
