# Initialize filecrypt plugin using Fisher event system

function _filecrypt_install --on-event filecrypt_install
    # Initialize filecrypt plugin
    # Ensure the secure directory structure exists

    if test -z "$XDG_CONFIG_HOME"
        set -g XDG_CONFIG_HOME ~/.config
    end

    # Create the secure directory structure if it doesn't exist
    set -l secure_dir $XDG_CONFIG_HOME/fish/secure/files
    if test ! -d $secure_dir
        mkdir -p $secure_dir
        # Set restrictive permissions on the secure directory
        chmod 700 $secure_dir
    end

    # Verify required dependencies
    if not command -sq gpg
        echo "Warning: GPG is required for filecrypt but not found in PATH" >&2
    end

    if not command -sq jq
        echo "Warning: jq is required for filecrypt but not found in PATH" >&2
    end

    if not command -sq base64
        echo "Warning: base64 is required for filecrypt but not found in PATH" >&2
    end
end

function _filecrypt_update --on-event filecrypt_update
    # Update logic - ensure directories still exist with proper permissions
    if test -z "$XDG_CONFIG_HOME"
        set -g XDG_CONFIG_HOME ~/.config
    end

    set -l secure_dir $XDG_CONFIG_HOME/fish/secure/files
    if test -d $secure_dir
        chmod 700 $secure_dir
    end
end

function _filecrypt_uninstall --on-event filecrypt_uninstall
    # Clean up any temporary files or settings if needed
    # Note: We don't remove the encrypted files directory as it contains user data
    functions --erase (functions --all | string match --entire -r '^_?filecrypt')
    echo "filecrypt plugin uninstalled. Encrypted files remain in $XDG_CONFIG_HOME/fish/secure/files"
end
