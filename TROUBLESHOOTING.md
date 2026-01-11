# Troubleshooting Guide

## Common Issues & Solutions

### 🔴 Build Errors

#### Issue: "Cannot find packages: flutter_riverpod, dio, json_annotation"

**Cause**: Dependencies not installed

**Solution**:
```bash
flutter pub get
flutter pub run build_runner build
```

---

#### Issue: "The getter 'isLoading' is not defined for AsyncValue"

**Cause**: Incorrect AsyncValue usage

**Wrong**:
```dart
if (data.isLoading) { ... } // ❌ isLoading doesn't exist
```

**Correct**:
```dart
data.when(
  data: (value) => ...,
  loading: () => CircularProgressIndicator(),
  error: (error, stack) => ...,
);
```

---

#### Issue: "Unhandled Exception: type 'OfferRideResponse' is not a subtype of type..."

**Cause**: JSON deserialization failed, likely missing `.g.dart` file

**Solution**:
```bash
# Regenerate all .g.dart files
flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

---

#### Issue: "method not found: 'fromJson' in OfferRideResponse"

**Cause**: Model class not properly set up for json_serializable

**Check**:
```dart
// Must have this at top of file:
part 'offer_ride_response.g.dart';

// Must have this decorator:
@JsonSerializable()

// Must have this method:
factory OfferRideResponse.fromJson(Map<String, dynamic> json) =>
    _$OfferRideResponseFromJson(json);
```

---

### 🔴 Runtime Errors

#### Issue: "Null check operator used on a null value" at trip.tripId!

**Cause**: Accessing nullable field without checking

**Wrong**:
```dart
String id = trip.tripId!; // ❌ May crash if tripId is null
```

**Correct**:
```dart
String id = trip.tripId ?? 'unknown';
```

---

#### Issue: "Unhandled Exception: UnauthorizedException"

**Cause**: JWT token expired or invalid

**Debug**:
```dart
// Check if token exists
final storage = TokenStorage();
final token = await storage.getAccessToken();
print('Token: $token'); // Should print JWT, not null

// Check token format
// Should look like: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

**Solution**:
1. User needs to re-login
2. Save new tokens: `storage.saveTokens(newToken, newRefresh, userId)`
3. Retry the request

---

#### Issue: "Unhandled Exception: Connection refused"

**Cause**: Backend not running or wrong URL

**Check**:
```bash
# Test backend is running
curl http://34.30.27.79:8080/v3/api-docs/trip

# If not running, backend might be down
# Contact backend team or check server status
```

**For Emulator**:
```dart
// Use 10.0.2.2 instead of localhost or 127.0.0.1
// (Android emulator uses 10.0.2.2 to reach host machine)

// But for actual backend at 34.30.27.79, use as-is:
baseUrl: 'http://34.30.27.79:8080'
```

---

#### Issue: "ClientException: Server did not provide response after ..."

**Cause**: Request timeout or backend slow

**Solution**:
```dart
// Increase timeout in DioClient
dio.options.connectTimeout = Duration(seconds: 60);
dio.options.receiveTimeout = Duration(seconds: 60);
dio.options.sendTimeout = Duration(seconds: 60);
```

---

### 🔴 API Response Issues

#### Issue: "Expected response but got null"

**Cause**: API response parsing failed

**Debug**:
```dart
// Enable logging to see raw response
// In DioClient, logs will show full response body

// Check response format in API Debug Screen
// Navigate to /api-debug and test endpoint
```

**Common Cause**: API changed but DTO not updated

**Solution**:
1. Check latest Swagger spec: `http://34.30.27.79:8080/v3/api-docs/trip`
2. Update model fields to match
3. Regenerate `.g.dart` files
4. Test with API Debug Screen

---

#### Issue: "ApiResponse.data is null even though request succeeded"

**Cause**: API wrapper format mismatch

**Expected Format**:
```json
{
  "data": { "tripId": "...", ... },
  "error": null,
  "message": "Success",
  "timestamp": "2024-01-15T10:00:00Z"
}
```

**Verify**:
1. Use API Debug Screen to inspect raw response
2. Check if API returns different wrapper structure
3. Adjust ApiResponse model if needed

---

### 🔴 Storage Issues

#### Issue: "Unhandled Exception: PlatformException..."

**Cause**: Secure storage not properly configured

**Solution**:
```dart
// Make sure TokenStorage is created correctly:
final storage = TokenStorage();
await storage.saveTokens(token, refresh, id);

// Check on Android - need permissions in AndroidManifest.xml:
<uses-permission android:name="android.permission.INTERNET" />

// Check on iOS - need Keychain configuration in Info.plist
```

---

#### Issue: "Token saved but getAccessToken() returns null"

**Cause**: Saving to wrong key or storage issue

**Debug**:
```dart
final storage = TokenStorage();

// Save
await storage.saveTokens('test-token', 'test-refresh', 'user-123');

// Retrieve immediately
final token = await storage.getAccessToken();
print('Retrieved token: $token'); // Should print 'test-token'

// If null, check:
// 1. Platform supports secure storage
// 2. Permissions configured
// 3. Storage backend working
```

---

### 🔴 Riverpod Issues

#### Issue: "ProviderNotFoundException: Could not find a provider for..."

**Cause**: Provider not in app scope or wrong name

**Check**:
```dart
// Make sure your app is wrapped with ProviderScope:
void main() {
  runApp(
    ProviderScope(  // ← This is required
      child: MyApp(),
    ),
  );
}

// Make sure you're using exact provider name:
ref.watch(searchMatchingRouteProvider(...)) // ✅ Correct
ref.watch(searchTripProvider(...))           // ❌ Wrong name
```

---

#### Issue: "Rebuilds too frequently" or infinite loops

**Cause**: Provider is being created multiple times per frame

**Wrong**:
```dart
// ❌ Creates new provider each time - causes rebuilds
final searchAsync = ref.watch(
  FutureProvider((ref) async { ... })
);
```

**Correct**:
```dart
// ✅ Provider defined once, reused
final searchProvider = FutureProvider((ref) async { ... });
final searchAsync = ref.watch(searchProvider);
```

---

#### Issue: "ref is not available" in StateNotifier

**Cause**: Trying to use `ref` directly in StateNotifier

**Wrong**:
```dart
class MyNotifier extends StateNotifier<AsyncValue<String>> {
  MyNotifier() : super(AsyncValue.data(''));
  
  void fetch() {
    // ❌ ref is not available here
    ref.watch(provider);
  }
}
```

**Correct**:
```dart
class MyNotifier extends StateNotifier<AsyncValue<String>> {
  final RepositoryRef _ref;
  
  MyNotifier(this._ref) : super(AsyncValue.data(''));
  
  void fetch() {
    // ✅ Use _ref instead
    _ref.read(repository).method();
  }
}
```

---

### 🔴 UI Issues

#### Issue: "Loading state never completes"

**Cause**: Provider is never resolved or error is silently swallowed

**Debug**:
```dart
// Use API Debug Screen to test endpoint
// Navigate to /api-debug and tap the endpoint button

// Check logs:
// - Request should appear in console
// - Response or error should follow
// - No response = backend not reached
```

---

#### Issue: "Tap button but nothing happens"

**Cause**: `onPressed` callback has error or async not awaited

**Wrong**:
```dart
ElevatedButton(
  onPressed: () {
    notifier.joinTrip(request); // ❌ Not awaited, no error shown
  },
  child: Text('Join'),
)
```

**Correct**:
```dart
ElevatedButton(
  onPressed: () async {
    try {
      await notifier.joinTrip(request); // ✅ Await
    } catch (e) {
      print('Error: $e'); // ✅ Handle errors
    }
  },
  child: Text('Join'),
)
```

---

#### Issue: "Errors not displaying in UI"

**Cause**: Error state not handled in .when()

**Wrong**:
```dart
data.when(
  data: (value) => ...,
  loading: () => ...,
  // ❌ Missing error case
);
```

**Correct**:
```dart
data.when(
  data: (value) => ...,
  loading: () => ...,
  error: (error, stack) => Text('Error: $error'),  // ✅ Always handle
);
```

---

### 🔴 Model Issues

#### Issue: "fromJson failed: Invalid value for 'latitude': not a number"

**Cause**: API response has wrong field type

**Check Swagger spec**:
```bash
curl http://34.30.27.79:8080/v3/api-docs/trip | jq '.components.schemas.Points'
```

**Verify model matches**:
```dart
class Points {
  final double latitude;  // Should be double if Swagger says "type: number"
  final double longitude;
  
  Points({
    required this.latitude,
    required this.longitude,
  });
}
```

---

#### Issue: "Field missing in response" (e.g., tripId is null)

**Cause**: Optional field not handled or API field name mismatch

**Check**:
```dart
// Make sure field is nullable:
@JsonKey(name: 'tripId')
final String? tripId;  // ✅ Has ?

// Not:
final String tripId;  // ❌ Will fail if missing
```

**Alternative - set default**:
```dart
@JsonKey(name: 'tripId', defaultValue: '')
final String tripId;  // Gets '' if missing
```

---

### 🟡 Performance Issues

#### Issue: "App freezes for 2-3 seconds on first API call"

**Cause**: Secure storage initialization or large model deserialization

**Solution**:
```dart
// Pre-initialize secure storage
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await TokenStorage().hasValidToken(); // Warm up
  runApp(ProviderScope(child: MyApp()));
}
```

---

#### Issue: "Memory usage increases with each API call"

**Cause**: Providers not being disposed or large lists not paginated

**Solution**:
```dart
// Use .autoDispose to free memory:
final provider = FutureProvider.autoDispose<List<Trip>>(
  (ref) async { ... }
);

// Implement pagination for large results:
final page1 = await getTrips(page: 0, limit: 20);
final page2 = await getTrips(page: 1, limit: 20);
```

---

### 🟡 Integration Issues

#### Issue: "Different response format than expected"

**Solution**:
1. Print raw response: `print(response.toString());`
2. Compare with Swagger spec
3. Check ApiResponse wrapper format
4. Adjust model/parsing if needed

**Test with API Debug Screen**:
- Navigate to `/api-debug`
- Tap endpoint button
- Expand result card to see full request/response

---

#### Issue: "Works in debug but fails in release build"

**Cause**: Missing dependencies or different build config

**Solution**:
```bash
# Clean rebuild
flutter clean
flutter pub get
flutter pub run build_runner build

# Test release build
flutter run --release
```

---

### 📋 Debugging Checklist

When something breaks:

- [ ] Run `flutter pub get` (dependencies)
- [ ] Run `flutter pub run build_runner build` (.g.dart files)
- [ ] Check `flutter run` output for compile errors
- [ ] Test endpoint in API Debug Screen
- [ ] Check logs: `flutter logs`
- [ ] Verify network: `curl http://34.30.27.79:8080/v3/api-docs/trip`
- [ ] Check DioClient logs (should print requests/responses)
- [ ] Print models: `print(response.toString())`
- [ ] Verify token: `print(await TokenStorage().getAccessToken())`
- [ ] Check Swagger spec for changes
- [ ] Try `flutter clean` if nothing works

---

### 🆘 Still Stuck?

1. **Check logs**: `flutter logs` shows detailed errors
2. **Use API Debug Screen**: `/api-debug` route shows endpoint details
3. **Read docs**: 
   - `REST_BACKEND_INTEGRATION.md` - Full guide
   - `QUICKSTART_REST_INTEGRATION.md` - Quick reference
   - `IMPLEMENTATION_SUMMARY.md` - Architecture overview
4. **Inspect response**: Use API Debug Screen to see actual API response
5. **Check backend**: Verify backend is running and responding
6. **Ask for help**: Provide error message + stack trace + what you tried

---

**Good luck! Most issues are resolved by regenerating `.g.dart` files or checking the API response format.** 🚀
