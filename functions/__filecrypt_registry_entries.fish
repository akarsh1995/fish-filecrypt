# Function to get all registry entries
function __filecrypt_registry_entries
    set -l registry_path $XDG_CONFIG_HOME/fish/secure/files/registry.json.gpg
    if test -f $registry_path
        gpg --quiet --decrypt $registry_path 2>/dev/null | jq -r 'keys[]'
    end
end
