# Google Places API Setup Guide

This guide will help you set up Google Places API for address autocomplete and geocoding features.

## Step 1: Get Google Cloud API Key

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select an existing one
3. Navigate to **APIs & Services** > **Credentials**
4. Click **Create Credentials** > **API Key**
5. Copy your API key

## Step 2: Enable Required APIs

Enable the following APIs in Google Cloud Console:

1. **Places API** (for autocomplete)
   - Go to **APIs & Services** > **Library**
   - Search for "Places API"
   - Click **Enable**

2. **Geocoding API** (for coordinates)
   - Search for "Geocoding API"
   - Click **Enable**

3. **Maps SDK for Android** (if using Android)
   - Search for "Maps SDK for Android"
   - Click **Enable**

4. **Maps SDK for iOS** (if using iOS)
   - Search for "Maps SDK for iOS"
   - Click **Enable**

## Step 3: Configure API Key Restrictions (Recommended)

For security, restrict your API key:

1. Go to **APIs & Services** > **Credentials**
2. Click on your API key
3. Under **Application restrictions**:
   - Select **Android apps** or **iOS apps** (for mobile)
   - Or **HTTP referrers** (for web)
4. Under **API restrictions**:
   - Select **Restrict key**
   - Choose: Places API, Geocoding API, Maps SDK

## Step 4: Add API Key to Your App

### Option 1: Update the Service File (Quick Setup)

Edit `lib/services/places_service.dart`:

```dart
static const String _apiKey = 'YOUR_ACTUAL_API_KEY_HERE';
```

### Option 2: Use Environment Variables (Recommended for Production)

1. Create a `.env` file in the project root:
```
GOOGLE_PLACES_API_KEY=your_api_key_here
```

2. Add `flutter_dotenv` package to `pubspec.yaml`:
```yaml
dependencies:
  flutter_dotenv: ^5.0.2
```

3. Update `places_service.dart`:
```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

static String get _apiKey => dotenv.env['GOOGLE_PLACES_API_KEY'] ?? '';
```

4. Load the .env file in `main.dart`:
```dart
import 'package:flutter_dotenv/flutter_dotenv.dart' as dotenv;

void main() async {
  await dotenv.load(fileName: ".env");
  runApp(MyApp());
}
```

### Option 3: Android Configuration

For Android, you can also add the API key to `android/app/src/main/AndroidManifest.xml`:

```xml
<application>
    <meta-data
        android:name="com.google.android.geo.API_KEY"
        android:value="YOUR_API_KEY_HERE"/>
</application>
```

### Option 4: iOS Configuration

For iOS, add to `ios/Runner/AppDelegate.swift`:

```swift
import GoogleMaps

GMSServices.provideAPIKey("YOUR_API_KEY_HERE")
```

## Step 5: Install Dependencies

Run:
```bash
flutter pub get
```

## Step 6: Test the Integration

1. Run your app
2. Try typing an address in the trip creation form
3. You should see address suggestions appear

## Troubleshooting

### No suggestions appearing?

1. Check that your API key is correctly set
2. Verify that Places API is enabled
3. Check API key restrictions (make sure your app is allowed)
4. Check console for error messages

### "This API project is not authorized" error?

- Make sure Places API is enabled in Google Cloud Console
- Check that billing is enabled (Google requires billing for Places API)

### Fallback mode active?

If you see the warning message about configuring the API key, the app will use a fallback geocoding method (less accurate). To get full functionality, configure the API key as described above.

## Cost Considerations

Google Places API has usage-based pricing:
- **Autocomplete (per session)**: First 1,000 requests/day free, then $2.83 per 1,000
- **Place Details**: First 1,000 requests/day free, then $0.017 per request
- **Geocoding**: First 40,000 requests/month free, then $5.00 per 1,000

Set up billing alerts in Google Cloud Console to monitor usage.

## Security Best Practices

1. **Never commit API keys to version control**
   - Add `.env` to `.gitignore`
   - Use environment variables or secure storage

2. **Restrict API keys**
   - Limit to specific APIs
   - Restrict by app package name or domain

3. **Use different keys for development and production**

4. **Monitor usage regularly**
   - Set up billing alerts
   - Review API usage in Google Cloud Console

## Alternative: Use OpenStreetMap (Free)

If you prefer a free alternative, you can use OpenStreetMap's Nominatim service. However, it has rate limits and is less accurate than Google Places API.

To use Nominatim, you would need to modify `places_service.dart` to call:
```
https://nominatim.openstreetmap.org/search?format=json&q={query}
```

Note: Nominatim requires proper attribution and has usage policies.
