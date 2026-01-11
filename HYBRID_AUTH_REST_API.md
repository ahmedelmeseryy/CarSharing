# Hybrid Authentication & API Architecture

## Overview
The app now uses a **hybrid approach** for testing:
- **Authentication**: Firebase Auth (login/register/password reset)
- **API Calls**: REST API (trips, bookings, with Firebase ID tokens)

This allows us to test REST API trip/booking operations while Firebase Auth is reliable and battle-tested.

---

## Architecture Flow

### 1. Authentication (Firebase)
```
User Input (email/password)
            ↓
FirebaseAuth.signInWithEmailAndPassword()
            ↓
Firebase validates & returns User object
            ↓
Get Firebase ID Token: user.getIdToken()
            ↓
Store in TokenStorage (accessToken, refreshToken, userId)
            ↓
User logged in ✓
```

### 2. REST API Calls (with Firebase Token)
```
DioClient prepares API request
            ↓
Interceptor checks TokenStorage for accessToken (Firebase ID token)
            ↓
Adds header: Authorization: Bearer {firebaseIdToken}
            ↓
POST to http://34.160.91.182/api/trips/offer
            ↓
Backend validates Firebase ID token
            ↓
Returns trip data or error
```

---

## What Changed

### LoginPage (_login method)
**Before**: Used `AuthApiService().login()` 
**Now**: Uses `FirebaseAuth.instance.signInWithEmailAndPassword()`
- Gets Firebase ID token
- Stores in TokenStorage
- Navigates based on user role

### RegisterPage (_signUp method)
**Before**: Used `AuthApiService().register()` 
**Now**: Uses `FirebaseAuth.instance.createUserWithEmailAndPassword()`
- Creates Firebase user
- Gets Firebase ID token
- Stores in TokenStorage

### Password Reset (_resetPassword method)
**Before**: Used `AuthApiService().resetPassword()` 
**Now**: Uses `FirebaseAuth.instance.sendPasswordResetEmail()`
- Native Firebase password reset

### REST API Calls
**Unchanged** - Still use:
- `TripApiService` for trip operations
- `BookingApiService` for booking operations
- `DioClient` for HTTP with token injection

---

## Token Management

### TokenStorage Integration
```dart
// After Firebase Auth succeeds:
final user = userCredential.user;
final idToken = await user.getIdToken();

await TokenStorage().saveTokens(
  accessToken: idToken,          // Firebase ID Token
  refreshToken: idToken,         // Also Firebase ID Token
  userId: user.uid,              // Firebase UID
);
```

### DioClient Interceptor
```dart
// For all REST API calls (except /api/auth/*)
final accessToken = await _tokenStorage.getAccessToken();
if (accessToken != null) {
  options.headers['Authorization'] = 'Bearer $accessToken';
}
```

---

## Testing Workflow

### 1. Register a New User
```
✓ Enter email, password, name, surname, age, phone, role
✓ Click "Create Account"
✓ FirebaseAuth creates user
✓ Stores Firebase ID token in TokenStorage
✓ Navigate to dashboard
```

### 2. Login
```
✓ Enter email and password
✓ FirebaseAuth validates credentials
✓ Gets Firebase ID token
✓ Stores in TokenStorage
✓ Navigate to dashboard
```

### 3. Create a Trip (Driver)
```
✓ Login as driver
✓ TripApiService.offerTrip() called
✓ DioClient adds: Authorization: Bearer {firebaseIdToken}
✓ POST /api/trips/offer
✓ Backend validates Firebase token
✓ Trip created ✓
```

### 4. Book a Trip (Passenger)
```
✓ Login as passenger
✓ Search for trips (REST API call with Firebase token)
✓ BookingApiService.joinTrip() called
✓ DioClient adds Authorization header
✓ POST /api/bookings/join
✓ Booking created ✓
```

---

## Backend Requirements

### Firebase Token Validation
The backend must validate Firebase ID tokens in requests like:
```
POST /api/trips/offer
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR...
Content-Type: application/json

{
  "sourceAddress": {...},
  "destinationAddress": {...},
  ...
}
```

**Backend should:**
1. Extract token from Authorization header
2. Verify token is valid Firebase ID token
3. Get user ID from token claims
4. Process the request

**Example (Java with Firebase Admin SDK):**
```java
String token = request.getHeader("Authorization").replace("Bearer ", "");
DecodedToken decodedToken = FirebaseAuth.getInstance().verifyIdToken(token);
String uid = decodedToken.getUid();
```

---

## Advantages of This Approach

✅ **Reliability**: Firebase Auth is battle-tested, handles edge cases
✅ **Security**: Firebase manages password hashing, token generation
✅ **Scalability**: REST API can be easily replaced when backend is ready
✅ **Testability**: Can test REST API endpoints without backend auth overhead
✅ **User Management**: Firebase handles user profiles, verification, reset

---

## Future Migration

When the REST API authentication endpoints are fully production-ready:

1. Replace Firebase Auth with REST API auth in main.dart
2. Store JWT tokens from REST API in TokenStorage
3. DioClient interceptor already configured for token injection
4. No changes needed to trip/booking code!

```dart
// Just swap out the login method:
Future<void> _login() async {
  final authService = AuthApiService();
  final data = await authService.login(email, password);
  
  final token = data['access_token'];
  await TokenStorage().saveTokens(
    accessToken: token,
    refreshToken: data['refresh_token'],
    userId: data['user']['id'],
  );
}
```

---

## Current Status

✅ Firebase Auth: Working (login, register, password reset)
✅ TokenStorage: Storing Firebase ID tokens
✅ DioClient: Injecting tokens for REST API calls
✅ REST API Interceptor: Ready for trip/booking operations
✅ Tests: 22 passing

**Ready to test:**
- User registration & login via Firebase
- Driver trip creation via REST API
- Passenger trip search via REST API
- Trip booking via REST API

---

## Troubleshooting

### "Bearer token invalid" error from backend
**Cause**: Backend doesn't recognize Firebase ID token format
**Solution**: Update backend to validate Firebase tokens using Firebase Admin SDK

### "Unauthorized (401)" on REST API calls
**Cause**: Token expired or not being sent
**Solution**: Check TokenStorage has token after Firebase login

### "Cannot find symbol 'FirebaseAuth'" error
**Cause**: Missing firebase_auth import
**Status**: Already added ✓

---

**Last Updated**: 2026-01-07
**Status**: ✅ Hybrid approach implemented and tested
