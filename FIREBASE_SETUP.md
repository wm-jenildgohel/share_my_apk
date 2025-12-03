# Firebase App Distribution Setup Guide

This guide explains how to set up and use Firebase App Distribution with Share My APK.

## Overview

Firebase App Distribution is a **free** enterprise-grade beta testing platform that provides:
- ✅ **2GB file size limit** (vs Diawi's 70MB)
- ✅ **Unlimited testers** with group management
- ✅ **Release notes** and email notifications
- ✅ **Crashlytics integration** for crash reporting
- ✅ **150-day build retention**
- ✅ **Completely free** - no paid tiers

## Quick Start

### Option 1: Local Development (Recommended)

```bash
# 1. Install Firebase CLI
npm install -g firebase-tools

# 2. Login to Firebase
firebase login

# 3. Use Share My APK with Firebase
share_my_apk --provider firebase --firebase-app-id "YOUR_APP_ID"
```

### Option 2: CI/CD with Service Account

```bash
# 1. Download service account JSON from Firebase Console
# 2. Set environment variable
export GOOGLE_APPLICATION_CREDENTIALS=/path/to/service-account.json

# 3. Use Share My APK with Firebase
share_my_apk --provider firebase --firebase-app-id "YOUR_APP_ID"
```

## Step-by-Step Setup

### 1. Create Firebase Project

1. Visit [Firebase Console](https://console.firebase.google.com)
2. Click "Add project"
3. Enter project name and follow the wizard
4. Project is created!

### 2. Register Your Android App

1. In Firebase Console, click "Add app" → Android icon
2. Enter your app's package name (must match `applicationId` in `build.gradle`)
3. Download `google-services.json` (optional for CLI uploads)
4. Click "Register app"

### 3. Get Your Firebase App ID

1. Go to Firebase Console → Project Settings
2. Scroll to "Your apps" section
3. Copy the App ID (format: `1:123456789:android:abc123def456`)

### 4. Enable Firebase App Distribution API

1. Visit [Google Cloud Console](https://console.cloud.google.com)
2. Select your Firebase project
3. Go to "APIs & Services" → "Library"
4. Search for "Firebase App Distribution API"
5. Click "Enable"

### 5. Authentication Setup

Choose **ONE** of these authentication methods:

#### Method A: User Login (Local Development)

```bash
# Login once - credentials are cached locally
firebase login

# Now you can use Share My APK without service account
share_my_apk --provider firebase --firebase-app-id "YOUR_APP_ID"
```

#### Method B: Service Account (CI/CD)

1. **Create Service Account**:
   - Go to Google Cloud Console → IAM & Admin → Service Accounts
   - Click "Create Service Account"
   - Name: `app-distribution-uploader`
   - Click "Create and Continue"

2. **Assign Role**:
   - Role: `Firebase App Distribution Admin`
   - Click "Continue" → "Done"

3. **Generate Key**:
   - Click on the service account
   - Go to "Keys" tab
   - Click "Add Key" → "Create new key"
   - Choose JSON format
   - Download the key file

4. **Use with Share My APK**:
   ```bash
   share_my_apk \
     --provider firebase \
     --firebase-app-id "YOUR_APP_ID" \
     --firebase-service-account /path/to/service-account.json
   ```

## Configuration File

Create or edit `share_my_apk.yaml` in your project root:

```yaml
# Set Firebase as the provider
provider: firebase

# Firebase configuration
firebase:
  # Required: Your Firebase App ID
  app_id: "1:123456789:android:abc123def456"

  # Optional: Service account (only needed for CI/CD)
  # Leave commented if using "firebase login"
  # service_account_path: ~/.firebase/service-account.json

  # Optional: Distribute to specific tester groups
  tester_groups:
    - qa-team
    - beta-testers
    - internal

  # Optional: Release notes for testers
  release_notes: "Bug fixes and performance improvements"

# Other settings...
path: .
release: true
```

Then simply run:
```bash
share_my_apk
```

## Usage Examples

### Basic Usage
```bash
# Uses configuration from share_my_apk.yaml
share_my_apk --provider firebase
```

### With Custom Release Notes
```bash
share_my_apk \
  --provider firebase \
  --firebase-app-id "1:123:android:abc" \
  --firebase-release-notes "Fixed login bug, improved performance"
```

### Distribute to Specific Tester Groups
```bash
share_my_apk \
  --provider firebase \
  --firebase-app-id "1:123:android:abc" \
  --firebase-tester-groups "qa-team,urgent-hotfix"
```

### Debug Build for Testing
```bash
share_my_apk \
  --provider firebase \
  --firebase-app-id "1:123:android:abc" \
  --no-release
```

### CI/CD Example (GitHub Actions)
```yaml
name: Deploy to Firebase

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.x'

      - name: Install Share My APK
        run: dart pub global activate share_my_apk

      - name: Setup Firebase Service Account
        run: echo '${{ secrets.FIREBASE_SERVICE_ACCOUNT }}' > service-account.json

      - name: Build and Upload to Firebase
        run: |
          share_my_apk \
            --provider firebase \
            --firebase-app-id "${{ secrets.FIREBASE_APP_ID }}" \
            --firebase-service-account service-account.json \
            --firebase-tester-groups "qa-team" \
            --firebase-release-notes "Build from commit ${{ github.sha }}"
```

## Creating Tester Groups

1. Go to Firebase Console → App Distribution
2. Click "Testers & Groups" tab
3. Click "Add Group"
4. Enter group name (e.g., `qa-team`, `beta-testers`)
5. Add tester emails
6. Click "Save"

Now you can distribute to these groups using `--firebase-tester-groups`.

## Comparison: Firebase vs Other Providers

| Feature | Firebase | Diawi | Gofile |
|---------|----------|-------|--------|
| **File Size Limit** | 2048 MB | 70 MB | Unlimited |
| **Price** | FREE | Free + Paid | FREE |
| **Setup Complexity** | Medium | Low | Minimal |
| **Tester Management** | ✅ Yes | ❌ No | ❌ No |
| **Email Notifications** | ✅ Auto | ❌ No | ❌ No |
| **Release Notes** | ✅ Yes | Basic | ❌ No |
| **Crashlytics** | ✅ Yes | ❌ No | ❌ No |
| **Build Retention** | 150 days | 3-7 days | 7-30 days |
| **Best For** | Team testing | Quick shares | Large files |

## Troubleshooting

### Error: "Firebase CLI not found"

**Solution:**
```bash
# Install Firebase CLI
npm install -g firebase-tools

# Verify installation
firebase --version
```

### Error: "not logged in" or "authentication"

**Solution:**
```bash
# Login to Firebase
firebase login

# Or use service account
export GOOGLE_APPLICATION_CREDENTIALS=/path/to/service-account.json
```

### Error: "App ID not found"

**Solution:**
1. Verify your App ID format: `1:PROJECT_NUMBER:android:APP_ID_HASH`
2. Make sure app is registered in Firebase Console
3. Check that you've enabled Firebase App Distribution API

### Error: "Permission denied"

**Solution:**
1. Ensure your account/service account has `Firebase App Distribution Admin` role
2. Re-run `firebase login` if using user authentication
3. Verify service account JSON file is valid and readable

### Upload is Very Slow

**Cause:** Large APK files can take time to upload.

**Tips:**
- Use `--no-release` for faster debug builds during testing
- Check your internet connection
- Firebase has 2GB limit but uploads can be slow for large files

## Advanced Configuration

### Environment-Specific Distributions

```yaml
# share_my_apk.yaml
provider: firebase

firebase:
  app_id: "1:123:android:abc"

  # Development builds
  # tester_groups: [dev-team]
  # release_notes: "Development build - not for production"

  # Staging builds
  tester_groups: [qa-team, internal]
  release_notes: "Staging build for QA testing"

  # Production builds
  # tester_groups: [beta-testers, early-access]
  # release_notes: "Production candidate build"
```

### Using Environment Variables

```bash
# Set App ID via environment
export FIREBASE_APP_ID="1:123456789:android:abc123def456"

# Set service account via environment
export GOOGLE_APPLICATION_CREDENTIALS="/path/to/service-account.json"

# Run without additional flags
share_my_apk --provider firebase --firebase-app-id "$FIREBASE_APP_ID"
```

## Best Practices

1. **Use `firebase login` for local development** - It's simpler and more secure than service accounts
2. **Use service accounts for CI/CD** - Store the JSON in secrets/environment variables
3. **Create meaningful tester groups** - Organize testers by role (QA, internal, beta, etc.)
4. **Write descriptive release notes** - Help testers understand what changed
5. **Test with debug builds first** - Faster builds during development
6. **Keep service account JSON secure** - Never commit it to version control

## Resources

- [Firebase App Distribution Documentation](https://firebase.google.com/docs/app-distribution)
- [Firebase Console](https://console.firebase.google.com)
- [Google Cloud Console](https://console.cloud.google.com)
- [Firebase CLI Reference](https://firebase.google.com/docs/cli)

## Support

If you encounter issues:
1. Check this troubleshooting guide
2. Run with `--verbose` flag for detailed logs
3. Verify Firebase CLI is working: `firebase projects:list`
4. Open an issue on [GitHub](https://github.com/wm-jenildgohel/share_my_apk/issues)
