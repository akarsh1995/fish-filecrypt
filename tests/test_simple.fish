#!/usr/bin/env fish

# Simple test for filecrypt encrypt/decrypt functionality
function test_simple_encrypt_decrypt
    echo "Testing simple encrypt/decrypt functionality..."

    # Setup
    set -l test_dir /tmp/filecrypt_simple_test_(date +%s)
    mkdir -p $test_dir
    cd $test_dir

    # Set environment
    set -x FILECRYPT_GPG_RECIPIENT test@example.com
    set -x XDG_CONFIG_HOME $test_dir/.config
    mkdir -p $XDG_CONFIG_HOME/fish/secure/files

    # Source the filecrypt function
    set -l plugin_dir (dirname (status --current-filename))
    source "$plugin_dir/functions/filecrypt.fish"

    echo "✓ Test environment set up"

    # Create a test file
    echo "This is a secret test file." >test_secret.txt
    echo "✓ Created test file"

    # Test encrypt
    echo "Testing encryption..."
    if printf "y\n" | filecrypt encrypt test_secret.txt "Test file"
        echo "✓ File encrypted successfully"
    else
        echo "✗ Failed to encrypt file"
        cd /
        rm -rf $test_dir
        return 1
    end

    # Verify original file was removed
    if test ! -f test_secret.txt
        echo "✓ Original file removed"
    else
        echo "✗ Original file still exists"
    end

    # Test list
    echo "Testing list..."
    if filecrypt list | grep -q test_secret.txt
        echo "✓ File found in registry"
    else
        echo "✗ File not found in registry"
    end

    # Test decrypt
    echo "Testing decryption..."
    set -l abs_path "$test_dir/test_secret.txt"
    if filecrypt restore "$abs_path"
        echo "✓ File restored successfully"
    else
        echo "✗ Failed to restore file"
        cd /
        rm -rf $test_dir
        return 1
    end

    # Verify content
    if test -f test_secret.txt
        set -l content (cat test_secret.txt)
        if test "$content" = "This is a secret test file."
            echo "✓ File content matches original"
        else
            echo "✗ File content does not match"
            echo "Expected: This is a secret test file."
            echo "Got: $content"
        end
    else
        echo "✗ Restored file not found"
    end

    # Test version
    echo "Testing version command..."
    if filecrypt version | grep -q "filecrypt version"
        echo "✓ Version command works"
    else
        echo "✗ Version command failed"
    end

    # Cleanup
    cd /
    rm -rf $test_dir
    echo "✓ Cleaned up test environment"

    echo "Simple encrypt/decrypt test completed!"
end

# Run the test
test_simple_encrypt_decrypt
