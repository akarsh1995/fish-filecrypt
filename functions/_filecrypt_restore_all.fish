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
