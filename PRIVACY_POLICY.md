# Privacy Policy for DNS Manager

**Last Updated:** December 14, 2025

## Overview

DNS Manager ("the App") is a free Android application that helps users manage Private DNS (DNS over TLS) settings on their devices. This privacy policy explains how we handle your information.

## Data Collection

**We do not collect any personal data.**

The App operates entirely on your device and does not transmit any personal information to external servers. All data stays on your phone.

## Information Stored Locally

The following information is stored **only on your device**:

- **DNS Server Settings:** Names, hostnames, and preferences for DNS servers you configure
- **Usage History:** Records of when DNS servers were activated/deactivated (stored locally for your reference)
- **App Preferences:** Theme settings, notification preferences, and display options

This data is stored using Android's SharedPreferences and never leaves your device.

## Permissions Explained

### WRITE_SECURE_SETTINGS
- **Purpose:** Configure the system's Private DNS setting
- **Note:** This permission must be granted manually via ADB and allows the app to change your Android DNS configuration

### POST_NOTIFICATIONS
- **Purpose:** Display an optional persistent notification showing DNS status and latency
- **Note:** You can enable/disable this in the app settings

### FOREGROUND_SERVICE
- **Purpose:** Keep the optional latency monitoring notification active
- **Note:** Only runs when you enable the persistent notification feature

### INTERNET
- **Purpose:** Test latency to DNS servers
- **Note:** Only used to measure connection time to DNS servers. No personal data is transmitted

### READ_EXTERNAL_STORAGE / READ_MEDIA_IMAGES
- **Purpose:** Allow importing custom logos for DNS servers
- **Note:** Only accessed when you choose to add a custom image

## Third-Party Services

The App does not use any third-party analytics, advertising, or tracking services.

## Data Security

- All data is stored locally on your device
- No data is transmitted to external servers
- No account or registration required
- The app works completely offline after initial setup

## Children's Privacy

The App does not collect any information from anyone, including children under 13 years of age.

## Changes to This Policy

We may update this Privacy Policy from time to time. Any changes will be posted on this page with an updated revision date.

## Open Source

DNS Manager is open source. You can review the complete source code at:
https://github.com/Vini-Paixao/dns-manager

## Contact

If you have any questions about this Privacy Policy, please contact us through:
- GitHub Issues: https://github.com/Vini-Paixao/dns-manager/issues

---

**Summary:** DNS Manager respects your privacy. We don't collect, store, or transmit any of your personal data. Everything stays on your device.
