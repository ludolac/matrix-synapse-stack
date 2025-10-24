# Two-Factor Authentication (2FA) User Guide
# Matrix Synapse - WAADOO

## Table of Contents
1. [What is Two-Factor Authentication?](#what-is-two-factor-authentication)
2. [Why Enable 2FA?](#why-enable-2fa)
3. [Supported Authenticator Apps](#supported-authenticator-apps)
4. [How to Enable 2FA](#how-to-enable-2fa)
5. [How to Use 2FA When Logging In](#how-to-use-2fa-when-logging-in)
6. [Recovery Codes](#recovery-codes)
7. [How to Disable 2FA](#how-to-disable-2fa)
8. [Troubleshooting](#troubleshooting)
9. [Security Best Practices](#security-best-practices)

---

## What is Two-Factor Authentication?

Two-Factor Authentication (2FA), also known as Multi-Factor Authentication (MFA), adds an extra layer of security to your Matrix account. Instead of just entering your password to log in, you'll also need to provide a 6-digit code from an authenticator app on your phone.

### How it works:
1. **Something you know**: Your password
2. **Something you have**: Your phone with the authenticator app

Even if someone steals your password, they won't be able to access your account without the 6-digit code from your phone.

---

## Why Enable 2FA?

✅ **Protect your account** from unauthorized access
✅ **Prevent password theft** - stolen passwords alone won't work
✅ **Secure your conversations** - keeps your messages private
✅ **Meet security requirements** - some organizations require 2FA
✅ **Industry standard** - used by banks, email providers, and social media

---

## Supported Authenticator Apps

You'll need an authenticator app on your phone to use 2FA. We recommend:

### 📱 iOS & Android
- **Google Authenticator** (Free, easy to use)
  - iOS: https://apps.apple.com/app/google-authenticator/id388497605
  - Android: https://play.google.com/store/apps/details?id=com.google.android.apps.authenticator2

- **Microsoft Authenticator** (Free, cloud backup)
  - iOS: https://apps.apple.com/app/microsoft-authenticator/id983156458
  - Android: https://play.google.com/store/apps/details?id=com.azure.authenticator

- **Authy** (Free, multi-device sync)
  - iOS: https://apps.apple.com/app/authy/id494168017
  - Android: https://play.google.com/store/apps/details?id=com.authy.authy

### 🔐 Password Managers (with TOTP)
- **1Password** (Paid, all-in-one)
- **Bitwarden** (Free/Paid, open-source)
- **LastPass** (Free/Paid)

---

## How to Enable 2FA

### Step 1: Install Authenticator App
1. Download one of the [recommended apps](#supported-authenticator-apps) above
2. Open and set up the app (follow its setup wizard)

### Step 2: Access Element Web Settings
1. Open Element Web: **https://element.waadoo.ovh**
2. Log in with your username and password
3. Click your **profile picture** (top-left corner)
4. Click **All settings**

### Step 3: Navigate to Security Settings
1. In the left sidebar, click **Security & Privacy**
2. Scroll down to find the **Two-factor authentication** section
   - You may see it as "Secure Backup" or "Security"

### Step 4: Set Up TOTP Authentication
1. Click **Set up** or **Enable** next to "Authenticator app"
2. A QR code will appear on your screen

### Step 5: Scan the QR Code
1. Open your authenticator app on your phone
2. Tap **Add** or **+** button
3. Choose **Scan QR code**
4. Point your camera at the QR code on your computer screen
5. The app will add "Matrix" (or your server name) to your list

> **Can't scan the QR code?**
> Click "Can't scan?" or "Enter manually" and type in the code shown below the QR code.

### Step 6: Verify Setup
1. Your authenticator app will show a 6-digit code
2. Type this code into Element Web
3. Click **Verify** or **Continue**

### Step 7: Save Recovery Codes ⚠️ IMPORTANT!
1. Element will show you **recovery codes**
2. **Copy these codes** and save them somewhere safe:
   - Password manager
   - Encrypted notes
   - Printed paper in a safe place
3. **DO NOT lose these codes!** You'll need them if you lose your phone

---

## How to Use 2FA When Logging In

Once 2FA is enabled, here's how logging in works:

### Login Process:
1. Go to **https://element.waadoo.ovh**
2. Enter your **username**
3. Enter your **password**
4. Click **Sign in**
5. You'll be prompted for a **6-digit code**
6. Open your **authenticator app**
7. Find "Matrix" in the list
8. **Type the 6-digit code** shown
9. Click **Continue**

### ⏰ Time-based Codes
- Codes change every **30 seconds**
- If a code expires, just wait for the next one
- Codes are synchronized with atomic clocks (very accurate)

---

## Recovery Codes

### What are Recovery Codes?
Recovery codes are backup codes that let you log in if:
- You lose your phone
- Your authenticator app gets deleted
- Your phone breaks or is stolen

### How to Use a Recovery Code:
1. When prompted for your 6-digit code, click **Use recovery code**
2. Enter one of your saved recovery codes
3. Click **Verify**

⚠️ **Important**:
- Each recovery code can only be used **once**
- After using a code, generate new recovery codes
- Store recovery codes securely (encrypted password manager recommended)

### How to View/Regenerate Recovery Codes:
1. Go to **Settings** → **Security & Privacy**
2. Find **Two-factor authentication**
3. Click **Manage** or **View recovery codes**
4. Generate new codes if needed

---

## How to Disable 2FA

⚠️ **Warning**: Disabling 2FA makes your account less secure.

### Steps to Disable:
1. Log in to Element Web
2. Go to **Settings** → **Security & Privacy**
3. Find **Two-factor authentication**
4. Click **Disable** or **Turn off**
5. Confirm by entering your password
6. You may need to enter a 6-digit code one last time

---

## Troubleshooting

### Problem: "Invalid code" error

**Causes & Solutions**:

1. **Time synchronization issue**
   - Your phone's time is incorrect
   - **Fix**: Enable "Automatic date & time" in phone settings
   - iOS: Settings → General → Date & Time → Set Automatically
   - Android: Settings → System → Date & time → Use network-provided time

2. **Code expired**
   - Codes change every 30 seconds
   - **Fix**: Wait for the next code to appear

3. **Wrong account**
   - You might have multiple Matrix accounts in your app
   - **Fix**: Make sure you're using the code from the correct account

### Problem: Lost phone / Can't access authenticator app

**Solution**: Use a recovery code
1. Click **Use recovery code** at login
2. Enter one of your saved recovery codes
3. Log in successfully
4. **Immediately** set up 2FA again with a new device

### Problem: Lost recovery codes

**If you can still log in**:
1. Log in to Element Web
2. Go to Settings → Security & Privacy
3. Generate new recovery codes
4. Save them securely

**If you cannot log in**:
- Contact your Matrix administrator
- Email: admin@waadoo.ovh
- They can disable 2FA for your account

### Problem: QR code won't scan

**Solutions**:
1. **Manual entry**: Click "Can't scan?" and enter the code manually
2. **Adjust brightness**: Make your screen brighter
3. **Try different app**: Some authenticator apps scan better than others
4. **Clean camera**: Make sure your phone camera lens is clean

### Problem: Codes don't work for SSO login

**Note**: If you use SSO (Single Sign-On) with Authelia:
- 2FA should be configured in Authelia, not in Element
- Contact your administrator about Authelia 2FA setup

---

## Security Best Practices

### ✅ DO:
- **Enable 2FA immediately** for admin accounts
- **Use a reputable authenticator app** from the list above
- **Save recovery codes** in a password manager
- **Enable automatic time sync** on your phone
- **Set up 2FA on multiple devices** (if your app supports it)
- **Keep your authenticator app updated**

### ❌ DON'T:
- **Don't share your 6-digit codes** with anyone
- **Don't email or text** recovery codes to yourself
- **Don't take screenshots** of QR codes (unless encrypted)
- **Don't use SMS-based 2FA** if TOTP is available (TOTP is more secure)
- **Don't disable 2FA** unless absolutely necessary

### 🔐 Extra Security:
1. **Use a password manager** to generate strong passwords
2. **Use different passwords** for different services
3. **Enable 2FA on your email** (protects password reset)
4. **Consider a hardware key** (YubiKey) for maximum security

---

## Frequently Asked Questions

### Q: Will 2FA work on all my devices?
**A**: Yes! Once enabled, you'll need to authenticate on each device you log in from. Your authenticator app stays on your phone.

### Q: Can I use the same authenticator app for multiple accounts?
**A**: Yes! You can add multiple accounts (Matrix, Google, GitHub, etc.) to the same authenticator app.

### Q: What happens if I upgrade my phone?
**A**: You'll need to:
1. Set up your authenticator app on the new phone
2. Re-add your Matrix account using the QR code
3. Or use a recovery code to log in, then set up 2FA again

### Q: Can I back up my authenticator app?
**A**: Depends on the app:
- **Authy**: Yes, cloud backup
- **Microsoft Authenticator**: Yes, cloud backup
- **Google Authenticator**: Yes, on newer versions
- **1Password/Bitwarden**: Yes, as part of your password vault

### Q: Is 2FA required?
**A**: Currently optional, but **strongly recommended** for all users, especially administrators.

### Q: Can I use a hardware security key instead?
**A**: WebAuthn/FIDO2 support can be enabled by your administrator. Contact them if you want to use a YubiKey or similar hardware key.

---

## Need Help?

If you encounter any issues not covered in this guide:

- **Email**: admin@waadoo.ovh
- **Matrix Room**: #support:waadoo.ovh
- **Documentation**: https://docs.waadoo.ovh/matrix

---

## Technical Details (for administrators)

### TOTP Configuration:
- **Algorithm**: SHA-1 (standard)
- **Digits**: 6
- **Period**: 30 seconds
- **Issuer**: Matrix

### Compatibility:
- Compatible with RFC 6238 (TOTP standard)
- Works with any authenticator app supporting TOTP
- No internet connection required for code generation

---

**Last Updated**: 2025-10-23
**Version**: 1.0
**Matrix Server**: matrix.waadoo.ovh
