# fish-filecrypt 🔐

[![GitHub](https://img.shields.io/github/license/akarsh1995/fish-filecrypt)](LICENSE)
[![GitHub release](https://img.shields.io/github/v/release/akarsh1995/fish-filecrypt)](https://github.com/akarsh1995/fish-filecrypt/releases)

> A comprehensive file encryption and management tool for [Fish shell](https://fishshell.com/), distributed as a [Fisher](https://github.com/jorgebucaran/fisher) plugin.

## Features

- **🔒 Encrypt files**: Securely encrypt files and store them in an encrypted registry
- **🔓 Decrypt/Restore files**: Restore encrypted files to their original location or custom destination
- **📋 File management**: List, delete, and manage encrypted files through a centralized registry
- **🚀 Batch operations**: Restore multiple files with pattern matching
- **🗑️ Secure deletion**: Option to securely shred original files after encryption
- **⚡ Tab completion**: Full Fish shell tab completion support for all commands
- **🎯 Zero configuration**: Works out of the box with sensible defaults

## Installation

Install using [Fisher](https://github.com/jorgebucaran/fisher):

```fish
fisher install akarsh1995/fish-filecrypt
```

## Prerequisites

- **GPG** (GNU Privacy Guard) - must be installed and configured
- **jq** - command-line JSON processor
- **base64** - utility (usually pre-installed)
- **shred** - for secure file deletion (optional but recommended)

## Quick Start

```fish
# Configure GPG recipient (first time setup)
filecrypt config set-recipient "your.email@example.com"

# Encrypt a file
filecrypt encrypt secret.txt "My secret document"

# List encrypted files
filecrypt list

# Restore a file
filecrypt restore secret.txt

# Delete from registry
filecrypt delete secret.txt
```

## Usage

### Encrypt a file

```fish
filecrypt encrypt /path/to/file.txt "Optional description"
```

**Options:**
- `--remove` - Automatically remove the original file after encryption

### Restore/Decrypt a file

```fish
# Restore to original location
filecrypt restore /path/to/original/file.txt

# Restore to custom location
filecrypt decrypt /path/to/original/file.txt /custom/destination/path
```

> **Note:** `decrypt` and `restore` are aliases for the same operation.

### List encrypted files

```fish
# Basic list
filecrypt list

# List with modification times
filecrypt list --details

# You can also use 'ls' as an alias
filecrypt ls --details
```

### Delete an entry from registry

```fish
# Interactive deletion (with confirmation)
filecrypt delete /path/to/original/file.txt

# Force delete without confirmation
filecrypt delete /path/to/original/file.txt --force
```

### Restore multiple files

```fish
# Restore all files
filecrypt restore-all

# Restore files matching a pattern
filecrypt restore-all --pattern "*.txt"

# Restore all files to a specific directory
filecrypt restore-all --output-dir /backup/restored

# Get help
filecrypt restore-all --help
```

## Configuration

### Initial Setup

1. **Configure GPG recipient** (required for first use):
   ```fish
   filecrypt config set-recipient "your.email@example.com"
   ```

2. **View current configuration**:
   ```fish
   filecrypt config
   ```

### Storage Location

The encrypted registry is stored at `$XDG_CONFIG_HOME/fish/secure/files/registry.json.gpg`.

### GPG Requirements

- A GPG key pair must be generated and available
- The recipient email/key must match your GPG identity
- You must be able to encrypt and decrypt with your key

If no recipient is configured, filecrypt will attempt to use your default GPG key.

## Security Features

- **🔐 GPG encryption**: Files are encrypted using GPG with your configured recipient
- **📅 Metadata preservation**: Original file modification times are preserved
- **🛡️ Encrypted registry**: The registry itself is encrypted and stored securely
- **🔥 Secure deletion**: When using `--remove`, files are securely shredded if available
- **🔒 Restrictive permissions**: Secure directories have 700 permissions

## Tab Completion

The plugin provides comprehensive tab completion for:

- All subcommands with descriptions
- File paths for encryption (excludes `.git` directories)
- Registry entries for restore/delete operations
- All command-line options and flags
- Directory completion for `--output-dir` option

## Plugin Topics

Add this plugin to GitHub with the following topics for better discoverability:
- `fish-plugin`
- `encryption`
- `security`
- `file-management`
- `gpg`

## Troubleshooting

### GPG Issues

**Generate a GPG key** (if you don't have one):
```fish
gpg --gen-key
```

**Check available keys**:
```fish
gpg --list-keys
gpg --list-secret-keys
```

**Test encryption/decryption**:
```fish
echo "test" | gpg --encrypt --recipient "your.email@example.com" | gpg --decrypt
```

**Configure filecrypt with your GPG key**:
```fish
filecrypt config set-recipient "your.email@example.com"
```

### Missing Dependencies
The plugin will warn you on installation if required dependencies are missing.

## Contributing

Contributions are welcome! Please feel free to submit issues and pull requests.

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## License

[MIT License](LICENSE) © [Akarsh Jain](https://github.com/akarsh1995)

## Related

- [Fisher](https://github.com/jorgebucaran/fisher) - Plugin manager for Fish
- [Fish Shell](https://fishshell.com/) - The user-friendly command line shell

---

<p align="center">
Made with ❤️ for the Fish shell community
</p>