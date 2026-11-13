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
