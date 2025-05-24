# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2024-12-28

### Added
- Initial release of fish-filecrypt Fisher plugin
- Core encryption functionality with GPG backend
- File registry system for tracking encrypted files
- Comprehensive subcommands:
  - `config` - Configure plugin settings
  - `encrypt` - Encrypt files and add to registry
  - `restore`/`decrypt` - Restore encrypted files
  - `list`/`ls` - List all encrypted files
  - `delete` - Remove entries from registry
  - `restore-all` - Batch restore operations
- Configurable GPG recipient with `filecrypt config set-recipient`
- Automatic GPG key detection when no recipient is configured
- Tab completion support for all commands and options
- Secure file deletion with shred when available
- Pattern matching for batch operations
- Custom output directory support for restore operations
- Metadata preservation (modification times)
- Automatic directory structure creation
- Fisher event system integration for proper plugin lifecycle
- Dependency checking on plugin installation

### Security
- All registry data encrypted with GPG
- Configurable GPG recipient for enhanced security
- Secure file deletion option with shred
- Restrictive permissions on secure directories (700)
- No plaintext storage of sensitive data
- Proper error handling for GPG operations

### Fisher Compliance
- Follows Fisher plugin directory structure
- Uses Fisher event system (`_install`, `_update`, `_uninstall`)
- Proper plugin topics for discoverability
- Professional documentation and README
- MIT license for open source compatibility