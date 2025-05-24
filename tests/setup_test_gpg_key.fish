#!/usr/bin/env fish

# only run this following code if gpg key test@example.com does not exist
# check if the GPG key exists
set -l gpg_key_exists (gpg --list-keys)
if echo $gpg_key_exists | grep -q "test@example.com"
    echo "GPG key for test@example.com already exists. Skipping key generation."
    return 0
end

# Create GPG key configuration file
echo "Key-Type: RSA
Key-Length: 2048
Subkey-Type: RSA
Subkey-Length: 2048
Name-Real: CI Test
Name-Email: test@example.com
Expire-Date: 0
%no-protection
%commit" >gpg_key_details.txt

gpg --batch --gen-key gpg_key_details.txt

rm gpg_key_details.txt

# list the keys to verify creation
gpg --list-keys

echo "✓ GPG key generated"
