# Firebase Renewal Guide for Car Sharing App

## Method 1: Using FlutterFire CLI (Recommended)

### Prerequisites
1. Install FlutterFire CLI globally:
   ```bash
   dart pub global activate flutterfire_cli
   ```

2. Login to Firebase:
   ```bash
   firebase login
   ```

3. Make sure you're in the project directory:
   ```bash
   cd E:\flutter\cloned\carsharing
   ```

### Regenerate Firebase Configuration

1. **Configure Firebase for your app:**
   ```bash
   flutterfire configure
   ```

2. **During configuration:**
   - Select your Firebase project (carshare-3dc21 or create a new one)
   - Select platforms: Android, iOS, Web, macOS, Windows (as needed)
   - The CLI will automatically update:
     - `lib/firebase_options.dart`
     - `android/app/google-services.json` (Android)
     - `ios/Runner/GoogleService-Info.plist` (iOS)

3. **Update dependencies:**
   ```bash
   flutter pub get
   ```

4. **Clean and rebuild:**
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

---

## Method 2: Manual Update from Firebase Console

### Step 1: Download Configuration Files

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: `carshare-3dc21`
3. Click the gear icon ⚙️ → Project Settings

### For Android:
1. In **Your apps** section, click on your Android app
2. Download the `google-services.json` file
3. Replace `android/app/google-services.json` with the downloaded file

### For iOS:
1. In **Your apps** section, click on your iOS app
2. Download the `GoogleService-Info.plist` file
3. Place it in `ios/Runner/GoogleService-Info.plist`

### Step 2: Update `firebase_options.dart`

You'll need to manually update the values in `lib/firebase_options.dart` with the new configuration from your Firebase project.

---

## Method 3: Connect to a Different Firebase Project

If you want to switch to a completely different Firebase project:

1. **Create or select a new Firebase project** at [Firebase Console](https://console.firebase.google.com/)

2. **Run FlutterFire CLI:**
   ```bash
   flutterfire configure
   ```
   - Select the new Firebase project
   - Select all platforms you need

3. **Update your collections** in Firestore:
   - Ensure you have: `users`, `trips`, `bookings` collections
   - Set up Firestore Security Rules if needed
   - Enable Firestore in your Firebase project

4. **Enable Authentication:**
   - Go to Firebase Console → Authentication
   - Enable Email/Password authentication
   - Configure any additional providers if needed

---

## Important Notes

### After Renewing Firebase:

1. **Verify Firebase services are enabled:**
   - ✅ Authentication (Email/Password)
   - ✅ Firestore Database
   - ✅ The collections: `users`, `trips`, `bookings`

2. **Update Firestore Security Rules** (if needed):
   ```javascript
   rules_version = '2';
   service cloud.firestore {
     match /databases/{database}/documents {
       match /{document=**} {
         allow read, write: if request.auth != null;
       }
     }
   }
   ```

3. **For production builds**, make sure to:
   - Update signing configurations in `android/app/build.gradle.kts`
   - Add proper bundle IDs for iOS
   - Configure OAuth redirect URLs if using social login

---

## Troubleshooting

### If you get "Firebase App not initialized" errors:
1. Run `flutter clean`
2. Delete `build` folder
3. Run `flutter pub get`
4. Run `flutter run`

### If Android build fails:
1. Check that `google-services.json` is in `android/app/`
2. Verify the `google-services` plugin is in `android/app/build.gradle.kts`
3. Make sure your package name matches in Firebase Console

### If iOS build fails:
1. Check that `GoogleService-Info.plist` is in `ios/Runner/`
2. Make sure it's added to Xcode project
3. Run `pod install` in the `ios/` directory

---

## Current Firebase Project Details

- **Project ID:** carshare-3dc21
- **Android Package:** com.example.carsharing
- **iOS Bundle ID:** com.example.flutterApplication3

---

## Need Help?

If you're still having issues:
1. Check Firebase Console for any service updates
2. Review Firebase documentation for Flutter
3. Make sure your Flutter and Firebase package versions are compatible



