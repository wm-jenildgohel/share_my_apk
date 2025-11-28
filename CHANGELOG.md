## 1.2.1-beta

**Simplified Configuration Release**

### Changed
- **BREAKING:** Simplified Firebase configuration - removed `firebase_project_id` requirement
- Firebase now only requires `FIREBASE_APP_ID` (project ID is auto-extracted or optional)
- Updated `.shareMyApk` config template with clearer, simpler structure
- Improved configuration comments with "EASIEST", "Simple", "Advanced" labels
- Better error messages for Firebase setup

### Fixed
- Firebase provider no longer requires project ID (CLI doesn't need it)
- Project ID is now auto-extracted from App ID for console URLs
- Clearer setup instructions in error messages

**Migration from 1.2.0-beta:**
If using Firebase, remove `FIREBASE_PROJECT_ID` from config (no longer needed).

---

## 1.2.0-beta

**Beta Release - Pending Testing**

### Added
- Production deployment validation and pub.dev compliance improvements
- Interactive provider selection with user-friendly prompts
- Cross-platform sound notifications with universal fallback support
- Firebase App Distribution enterprise-grade integration
- Enhanced package description for better discoverability
- Comprehensive API documentation and examples

### Changed
- SDK constraint now includes proper upper bound for Dart SDK compatibility
- Package description enhanced to 170 characters with relevant keywords

### Fixed
- All critical issues from previous beta releases resolved
- Version synchronization across all package files
- pub.dev validation compliance issues

**Breaking Changes:** None

**Migration from 1.1.x-beta:**
No code changes required. Configuration files remain fully compatible.

---

## 1.1.4-beta

**Critical Fix Release**

### Fixed
- Resolved critical issue where build service files (`lib/src/services/build/`) were accidentally excluded from the package due to incorrect `.pubignore` rules
- Fixed `dartdoc` generation failure caused by missing files
- Resolved static analysis errors in the published package

---

## 1.1.3-beta

**Interactive Mode Release**

### Added
- Interactive provider selection that prompts users to choose distribution method
  - Choose between Diawi, Gofile, Firebase App Distribution, or skip upload
  - Smart detection: automatically skips prompts if provider is already configured
  - User-friendly descriptions for each provider option
- Firebase Configuration Wizard for complete interactive setup
  - Prompts for Project ID, App ID, service account path
  - Interactive collection of release notes, testers, and groups
  - Option to save configuration for future use
- CLI Integration with `--interactive` / `-i` flag (enabled by default)
  - `--no-interactive` for non-interactive/CI-CD mode
  - Maintains backward compatibility with existing workflows
- YAML Configuration: Added `interactive: true/false` option
- New `prompt_util.dart` with reusable interactive prompt utilities
  - `askYesNo()` - Yes/no questions with defaults
  - `askChoice()` - Multiple choice selection
  - `askText()` - Validated text input
  - `promptForFirebaseConfig()` - Full Firebase setup wizard

### Changed
- Comprehensive documentation updates for interactive mode in README and walkthrough

**Usage Examples:**
```bash
share_my_apk                   # Interactive mode (shows prompts if not configured)
share_my_apk --no-interactive  # Skip all prompts, use config only
share_my_apk --provider firebase  # Use Firebase with existing config
```

---

## 1.1.0-beta

**Sound Notification Release**

### Added
- Cross-platform sound notification feature that plays beep/notification sound after successful APK upload (enabled by default)
- Universal compatibility across Windows, Linux, and macOS with multiple fallback mechanisms
- Multiple implementation strategies:
  - Primary: ASCII bell character (`\x07`) for terminal beep
  - Windows: `rundll32` system beep + PowerShell fallback
  - Linux: `pactl` + `beep` + `speaker-test` fallbacks
  - macOS: `afplay` system sound + `osascript` fallback
- CLI Integration: New `--sound` / `-s` flag for enabling sound notifications
- YAML Configuration: Added `sound: true/false` option
- Comprehensive testing with unit tests and examples
- Graceful degradation: fails silently if sound cannot be played without breaking main workflow

**Usage Examples:**
```bash
share_my_apk                   # Sound enabled by default
share_my_apk --no-sound        # Disable sound notification
```

---

## 1.0.0

**First Stable Production Release**

### Added
- Production ready upgrade from beta to stable 1.0.0 release
- Comprehensive audit completed with 100+ tests passing
- Complete documentation for production release status

### Changed
- Code cleanup: removed unused imports and resolved all static analysis warnings
- Configuration fix: removed hardcoded 'diawi' default that was overriding YAML configuration priority

### Fixed
- Package validation: passed all pub.dev validation checks for production publishing

---

## 1.0.1

**Maintenance & Polish Release**

### Changed
- Updated package version to `1.0.1` in `pubspec.yaml`
- Improved `README.md` structure and content for better clarity and `pub.dev` compliance
- Confirmed all unit tests pass and static analysis shows no issues
- Ensured package passes `pub.dev` validation checks

---

## 0.5.0

**Fully Automated & Comprehensive Release**

### Added
- Fully automated uploads: removed pre-upload confirmation dialog for streamlined operation
- Automatic FVM detection: uses `fvm flutter` if `.fvm` directory exists
- Integrated `flutter clean` before builds for fresh, reliable builds
- Automatic `flutter pub get` to ensure dependencies are up-to-date
- Automatic localization generation (`flutter gen-l10n`) when `lib/l10n` exists
- New CLI flags: `--no-clean`, `--no-pub-get`, `--no-gen-l10n` to disable individual steps
- Colorful log messages with better structure and readability
- Timestamps in friendly format
- Highlighted box for final success message

### Changed
- Tool now proceeds directly to upload after build completion
- Improved layout with indentation and spacing for readability

### Fixed
- Critical bug where the `provider` from `share_my_apk.yaml` was ignored
- Corrected the Diawi upload success status code to prevent timeouts

---

## 0.4.0-beta

**Rock-Solid & Ready Release**

### Added
- 100+ unit tests covering all major components
- 6 test categories: Upload services, build services, CLI, error handling, integration
- 19 test files ensuring reliability and preventing regressions
- Added `TESTING.md` with complete testing documentation
- Production-ready validation with real upload testing

### Changed
- Enhanced Diawi API integration with proper asynchronous job polling
- Improved upload service factory with better validation
- Case-insensitive provider matching
- Enhanced error messages for better debugging

### Fixed
- Gofile API integration: corrected server endpoint to `https://api.gofile.io/servers`
- Fixed upload endpoint to use proper `/contents/uploadfile` path
- Improved response parsing for download links
- Successfully handles large files (tested with 113.4MB APKs)
- Timeout handling (30 attempts with 5-second intervals)
- Status checking with proper error handling

---

## 0.3.2

### Changed
- Improved code readability and consistency
- Enhanced project documentation

---

## 0.3.1

### Changed
- Updated dependencies to latest versions

### Fixed
- Critical issue that could cause build process to fail
- Added detailed code comments

---

## 0.3.0

### Changed
- Major refactor: reorganized codebase for better maintainability
- Updated all dependencies to latest versions
- Improved `README.md` structure
- Enhanced examples for better clarity

---

## 0.2.0-alpha

### Added
- `init` command to create configuration file automatically
- Support for `share_my_apk.yaml` configuration file
- Separate API tokens for Diawi and Gofile

### Changed
- Redesigned `--help` command for better usability

### Fixed
- Bug causing issues with API tokens

---

## 0.1.0-alpha

**Initial Release**

### Added
- Upload APKs to Diawi or Gofile.io
- Automatic provider switching for large files (>70MB)
- Custom APK naming
- Build folder organization
- Custom output directory support
- Comprehensive logging
