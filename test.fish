#!/usr/bin/env fish

# Test script to validate fish-filecrypt plugin structure
# This script checks if all required files are present and properly structured

function test_plugin_structure
    set -l plugin_dir (dirname (status --current-filename))
    set -l errors 0

    echo "Testing fish-filecrypt plugin structure..."
    echo "Plugin directory: $plugin_dir"
    echo

    # Check required directories
    set -l required_dirs functions completions conf.d
    for dir in $required_dirs
        if test -d "$plugin_dir/$dir"
            echo "✓ Directory $dir exists"
        else
            echo "✗ Missing directory: $dir"
            set errors (math $errors + 1)
        end
    end

    # Check required files
    set -l required_files functions/filecrypt.fish completions/filecrypt.fish conf.d/filecrypt.fish README.md LICENSE
    for file in $required_files
        if test -f "$plugin_dir/$file"
            echo "✓ File $file exists"
        else
            echo "✗ Missing file: $file"
            set errors (math $errors + 1)
        end
    end

    # Check function definitions
    echo
    echo "Checking function definitions..."

    set -l expected_functions filecrypt _filecrypt_encrypt _filecrypt_restore _filecrypt_delete _filecrypt_list _filecrypt_restore_all _filecrypt_config __filecrypt_registry_entries
    for func in $expected_functions
        if grep -q "function $func" $plugin_dir/functions/*.fish
            if test -f "$plugin_dir/functions/$func.fish"
                echo "✓ Function $func defined in functions/$func.fish"
            else
                echo "✗ Function $func is not in its own file functions/$func.fish"
                set errors (math $errors + 1)
            end
        else
            echo "✗ Missing function: $func"
            set errors (math $errors + 1)
        end
    end

    # Check event handlers
    echo
    echo "Checking Fisher event handlers..."

    set -l event_handlers _filecrypt_install _filecrypt_update _filecrypt_uninstall
    for handler in $event_handlers
        if grep -q "function $handler --on-event" "$plugin_dir/conf.d/filecrypt.fish"
            echo "✓ Event handler $handler defined"
        else
            echo "✗ Missing event handler: $handler"
            set errors (math $errors + 1)
        end
    end

    # Check completions
    echo
    echo "Checking completions..."

    if grep -q "complete -c filecrypt" "$plugin_dir/completions/filecrypt.fish"
        echo "✓ Completions defined"
    else
        echo "✗ No completions found"
        set errors (math $errors + 1)
    end

    # Summary
    echo
    if test $errors -eq 0
        echo "🎉 All tests passed! Plugin structure is valid."
        return 0
    else
        echo "❌ $errors error(s) found. Plugin structure needs fixes."
        return 1
    end
end

# Run the test
test_plugin_structure
