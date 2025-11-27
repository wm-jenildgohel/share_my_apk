## 🐛 1.1.4-beta - The "Missing Files Fix" Release

**🚑 Critical Fix**

-   **🐛 Fixed Missing Files:** Resolved a critical issue where build service files (`lib/src/services/build/`) were accidentally excluded from the package due to incorrect `.pubignore` rules.
-   **📄 Documentation:** Fixed `dartdoc` generation failure caused by missing files.
-   **✅ Static Analysis:** Resolved static analysis errors in the published package.

---

## 🎯 1.1.3-beta - The "Interactive Mode" Release

**🎨 Interactive Provider Selection & Firebase Wizard**

-   **🎯 Interactive Mode:** Added interactive provider selection that prompts users to choose how they want to distribute their APK
    -   Choose between Diawi, Gofile, Firebase App Distribution, or skip upload
    -   Smart detection: automatically skips prompts if provider is already configured
    -   User-friendly descriptions for each provider option
-   **🔥 Firebase Configuration Wizard:** Complete interactive setup for Firebase App Distribution
    -   Prompts for Project ID, App ID, service account path
    -   Interactive collection of release notes, testers, and groups
    -   Option to save configuration for future use
-   **⚙️ CLI Integration:** New `--interactive` / `-i` flag (enabled by default)
    -   `--no-interactive` for non-interactive/CI-CD mode
    -   Maintains backward compatibility with existing workflows
-   **📄 YAML Configuration:** Added `interactive: true/false` option to configuration files
-   **🛠️ Utility Creation:** New `prompt_util.dart` with reusable interactive prompt utilities
    -   `askYesNo()` - Yes/no questions with defaults
    -   `askChoice()` - Multiple choice selection
    -   `askText()` - Validated text input
    -   `promptForFirebaseConfig()` - Full Firebase setup wizard
-   **📚 Documentation Updates:** Comprehensive documentation for interactive mode in README and walkthrough

**Usage Examples:**
```bash
share_my_apk                   # Interactive mode (shows prompts if not configured)
share_my_apk --no-interactive  # Skip all prompts, use config only
share_my_apk --provider firebase  # Use Firebase with existing config
```

**First-Time User Experience:**
```
📤 How would you like to distribute your APK?
  → 1. Diawi - Quick team sharing (70MB limit, 30-day expiry)
    2. Gofile - Large files (no size limit, permanent links)
    3. Firebase App Distribution - Enterprise distribution
    4. Skip upload - Just build the APK

Select option (1-4) [1]:
```

---

## 🎵 1.1.0-beta - The "Sound Notification" Release

**🔔 Cross-Platform Sound Notifications**

-   **🎵 Sound Notifications:** Added cross-platform sound notification feature that plays a beep/notification sound after successful APK upload (enabled by default).
-   **🌍 Universal Compatibility:** Works on Windows, Linux, and macOS with multiple fallback mechanisms for maximum reliability.
-   **⚙️ Multiple Implementation Strategies:**
    -   Primary: ASCII bell character (`\x07`) for terminal beep
    -   Windows: `rundll32` system beep + PowerShell fallback
    -   Linux: `pactl` + `beep` + `speaker-test` fallbacks
    -   macOS: `afplay` system sound + `osascript` fallback
-   **🎛️ CLI Integration:** New `--sound` / `-s` flag for enabling sound notifications
-   **📄 YAML Configuration:** Added `sound: true/false` option to configuration files
-   **🧪 Comprehensive Testing:** Added unit tests and example for sound notification functionality
-   **🔇 Graceful Degradation:** Fails silently if sound cannot be played without breaking main workflow

**Usage Examples:**
```bash
share_my_apk                   # Sound enabled by default
share_my_apk --no-sound        # Disable sound notification
```

**YAML Configuration:**
```yaml
sound: false                   # Disable sound (enabled by default)
provider: gofile
```

---

## 🎉 1.0.0 - The "Production Ready" Release

**🚀 First Stable Production Release**

-   **✅ Production Ready:** Upgraded from beta to stable 1.0.0 release after comprehensive testing and validation.
-   **🧹 Code Cleanup:** Removed unused imports and resolved all static analysis warnings.
-   **📦 Package Validation:** Passed all pub.dev validation checks for production publishing.
-   **🏆 Quality Assurance:** Comprehensive audit completed with 100+ tests passing and zero issues.
-   **📚 Documentation Complete:** All documentation updated for production release status.
-   **🐛 Configuration Fix:** Removed hardcoded 'diawi' default that was overriding YAML configuration priority.

---

## 🎉 1.0.1 - The "Maintenance & Polish" Release

**✨ Minor Improvements & Quality Assurance**

-   **⬆️ Version Bump:** Updated package version to `1.0.1` in `pubspec.yaml`.
-   **📚 Documentation Refinement:** Improved `README.md` structure and content for better clarity and `pub.dev` compliance.
-   **✅ Quality Checks:** Confirmed all unit tests pass and static analysis shows no issues.
-   **📦 Package Validation:** Ensured package passes `pub.dev` validation checks.

---

## 🚀 0.5.0 - The "Fully Automated & Comprehensive" Release

**✨ Major UI/UX & Automation Improvements**

-   **🚀 Fully Automated Uploads:**
    -   Removed pre-upload confirmation dialog for streamlined, non-interactive operation.
    -   Tool now proceeds directly to upload after build completion.
    -   Perfect for CI/CD pipelines and automated workflows.

-   **🔧 Comprehensive Build Pipeline:**
    -   Added automatic FVM detection - uses `fvm flutter` if `.fvm` directory exists.
    -   Integrated `flutter clean` before builds for fresh, reliable builds.
    -   Added automatic `flutter pub get` to ensure dependencies are up-to-date.
    -   Implemented automatic localization generation (`flutter gen-l10n`) when `lib/l10n` exists.
    -   New CLI flags: `--no-clean`, `--no-pub-get`, `--no-gen-l10n` to disable individual steps.

-   **🎨 Colorful & Fun Logs:**
    -   Added emojis and colors to log messages for a more engaging experience.
    -   Assigned specific emojis and colors to each log level for better structure.
    -   Re-introduced timestamps in a friendly format.
    -   Improved layout with indentation and spacing for readability.
    -   Created a special, highlighted box for the final success message.

-   **🔧 Bug Fixes & Configuration Improvements:**
    -   Fixed a critical bug where the `provider` from `share_my_apk.yaml` was ignored.
    -   Corrected the Diawi upload success status code to prevent timeouts.

-   **📦 Dependency Updates:**
    -   Added the `intl` package for date formatting.

## 🚀 0.4.0-beta - The "Rock-Solid & Ready" Release

**🎯 Major API Integration Fixes & Comprehensive Testing**

-   **🔧 Fixed Gofile API Integration:** 
    - Corrected server endpoint to `https://api.gofile.io/servers`
    - Fixed upload endpoint to use proper `/contents/uploadfile` path
    - Improved response parsing for download links
    - Now successfully handles large files (tested with 113.4MB APKs)

-   **🔧 Enhanced Diawi API Integration:**
    - Implemented proper asynchronous job polling mechanism
    - Added timeout handling (30 attempts with 5-second intervals)
    - Improved status checking with proper error handling
    - Fixed response parsing for final download links

-   **🧪 Comprehensive Testing Suite:**
    - Added **100+ unit tests** covering all major components
    - Created **6 test categories**: Upload services, build services, CLI, error handling, integration
    - **19 test files** ensuring reliability and preventing regressions
    - Added `TESTING.md` with complete testing documentation

-   **🛡️ Enhanced Error Handling:**
    - Improved upload service factory with better validation
    - Added case-insensitive provider matching
    - Enhanced error messages for better debugging
    - Robust handling of null/empty inputs and edge cases

-   **✅ Production-Ready Validation:**
    - Successfully tested real uploads to both Diawi and Gofile
    - Verified automatic provider switching for large files
    - Validated configuration loading and CLI argument parsing
    - All code passes static analysis (`dart analyze`)

-   **📚 Updated Documentation:**
    - Comprehensive testing documentation
    - Updated API integration details
    - Enhanced troubleshooting guide
    - Better error handling examples

**⚠️ Beta Release Note:** This version includes significant API fixes and comprehensive testing. While thoroughly tested in development, we recommend testing in your specific environment before production use.

## 🚀 0.3.2 - The "Polished & Perfected" Release

-   **✨ Improved Readability:** We've polished the code to make it cleaner and more consistent. You won't see the changes, but you'll feel the love.
-   **📝 Better Documentation:** Added more details to our project documentation, making it easier for everyone to contribute.

## 🚀 0.3.1 - The "Oops, We Fixed It" Release

-   **🐛 Bug Fix:** Fixed a critical issue that could cause the build process to fail. Now, it's smooth sailing!
-   **⬆️ Under the Hood:** Updated our dependencies to the latest versions for better performance and security.
-   **📝 Clearer Instructions:** We've added more detailed comments to the code to make it easier to understand.

## 🚀 0.3.0 - The "Let's Get Serious (About Fun)" Release

-   **✨ Major Refactor:** We've completely reorganized the codebase to make it more robust and easier to maintain.
-   **⬆️ Fresher Than Ever:** All our dependencies have been updated to the latest versions.
-   **📝 Fun New Docs:** Our `README.md` is now more engaging and easier to read.
-   **💡 Clearer Examples:** Our examples are now so simple that anyone can follow along.

## 🎉 0.2.0-alpha - The "We're Getting Fancy" Release

-   **🚀 Quick Start:** You can now use the `init` command to create a configuration file automatically.
-   **🎨 Better Help:** The `--help` command has been redesigned to be more intuitive and helpful.
-   **⚙️ Easy Configuration:** We now support a `share_my_apk.yaml` file, so you can set your preferences once and forget about it.
-   **🔑 Separate Tokens:** You can now use different API tokens for Diawi and Gofile.
-   **🐛 Bug Fix:** Fixed a bug that was causing issues with API tokens.

---

## 🐣 0.1.0-alpha - The "Hello, World!" Release

-   **☁️ More Choices:** You can now upload your APKs to either Diawi or Gofile.io.
-   **🔄 Smart Uploads:** If your APK is too large for Diawi, we'll automatically switch to Gofile.io.
-   **🎨 Custom Names:** You can now give your APK a custom name.
-   **📁 Tidy Folders:** We've made it easier to keep your build folders organized.
-   **📝 You're in Control:** You can now specify a custom output directory for your APK.
-   **🪵 Stay Informed:** We've added logging so you can see what's happening behind the scenes.