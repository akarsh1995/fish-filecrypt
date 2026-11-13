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
