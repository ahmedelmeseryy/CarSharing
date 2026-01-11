# 🚗 Flutter Car-Sharing App - REST Backend Integration

## Welcome! 👋

You now have a **complete REST backend integration** for your Flutter car-sharing app. This replaces Firebase entirely with a microservices REST API.

**Backend**: `http://34.30.27.79:8080` (Spring Boot microservices)

---

## 📖 Getting Started (Choose One)

### ⚡ **I'm in a Hurry** (5 minutes)
→ Read: [`QUICKSTART_REST_INTEGRATION.md`](QUICKSTART_REST_INTEGRATION.md)

Quick summary:
1. Add dependencies
2. Run build_runner
3. Wrap app with ProviderScope
4. Copy example screens
5. Done!

---

### 📚 **I Want to Understand Everything** (30 minutes)
→ Read: [`REST_BACKEND_INTEGRATION.md`](REST_BACKEND_INTEGRATION.md)

Complete guide with:
- Architecture explanation
- File structure breakdown
- Core components deep-dive
- API services guide
- UI integration examples
- Common patterns
- Debugging tips

---

### 🏗️ **Show Me the Architecture** (10 minutes)
→ Read: [`ARCHITECTURE_DIAGRAMS.md`](ARCHITECTURE_DIAGRAMS.md)

Visual diagrams of:
- Complete system architecture
- Data flow (search → book workflow)
- State management flow
- File dependency graph
- Error handling flow
- Provider lifecycle

---

### 🐛 **Something is Broken** (Look Here First)
→ Read: [`TROUBLESHOOTING.md`](TROUBLESHOOTING.md)

Solutions for:
- Build errors (missing dependencies, .g.dart files)
- Runtime errors (null checks, token issues)
- API errors (connection, backend down)
- Riverpod errors (provider not found, infinite loops)
- UI issues (buttons not responding, errors not showing)

---

### 📋 **Just Show Me What Was Built**
→ Read: [`FILE_LISTING.md`](FILE_LISTING.md)

Complete file list with:
- Location of each file
- What each file does
- File statistics
- Dependencies used

---

### 📊 **Give Me a Summary**
→ Read: [`IMPLEMENTATION_SUMMARY.md`](IMPLEMENTATION_SUMMARY.md)

High-level overview including:
- What was built (25 files)
- Architecture layers
- Code statistics
- Endpoint mapping
- Getting started
- Features delivered

---

## 🎯 Next Steps

### 1. Setup (Choose Your Path)
```bash
# Quick path (5 min)
# Follow QUICKSTART_REST_INTEGRATION.md

# Thorough path (30 min)
# Read REST_BACKEND_INTEGRATION.md first
```

### 2. Test
- Navigate to `/api-debug` route in your app
- Click "Search Trips" button
- See real API calls in the test console

### 3. Integrate
- Copy `TripSearchExample` into your app
- Copy `OfferTripExample` into your app
- Update user IDs and coordinates
- Test with your backend

### 4. Customize
- Style UI to match your design
- Add more features (reviews, payments, etc.)
- Implement proper authentication

---

## 📁 Project Structure

```
Your App/
├── lib/
│   ├── core/                    # Shared infrastructure
│   │   ├── network/             # HTTP & auth
│   │   ├── storage/             # Token storage
│   │   └── providers/           # Riverpod setup
│   │
│   └── features/
│       ├── trip/                # Trip search & offering
│       └── booking/             # Booking management
│
├── QUICKSTART_REST_INTEGRATION.md    ← Start here!
├── REST_BACKEND_INTEGRATION.md       ← Learn more
├── ARCHITECTURE_DIAGRAMS.md          ← Visual guides
├── TROUBLESHOOTING.md                ← When stuck
└── FILE_LISTING.md                   ← File index
```

---

## 🔑 Key Technologies

| Tech | Purpose | Why |
|------|---------|-----|
| **Riverpod** | State management | Type-safe, powerful, modern |
| **Dio** | HTTP client | Easy, feature-rich, popular |
| **json_serializable** | JSON ↔ Dart | Type-safe, generated code |
| **flutter_secure_storage** | Token storage | Encrypted, secure |
| **Clean Architecture** | Code organization | Scalable, maintainable |

---

## 🚀 What You Get

### ✅ Networking Layer
- DioClient with automatic JWT injection
- Custom exception hierarchy
- Request/response logging
- Error handling for all HTTP codes

### ✅ Data Models
- 8 data models with json_serializable
- Proper typing and null safety
- Helper methods (calculations, getters)
- Full Swagger mapping

### ✅ API Services
- 9 endpoints fully implemented
- 6 trip operations (search, offer, cancel, etc.)
- 3 booking operations (join, cancel, view)
- Detailed documentation & examples

### ✅ State Management
- Query providers for data fetching
- Mutation providers for state changes
- Automatic loading states
- Error handling

### ✅ UI Examples
- Passenger search & booking screen
- Driver offer trip screen
- Upcoming trips view
- API testing console for debugging

### ✅ Documentation
- Comprehensive integration guide (400+ lines)
- Quick start guide (5-minute setup)
- Architecture diagrams (visual)
- Troubleshooting guide (50+ issues)
- This welcome guide

---

## 💡 Key Concepts

### Clean Architecture
```
UI (Presentation)
  ↓
State Management (Riverpod)
  ↓
Repositories (Domain + Data)
  ↓
API Services (Data)
  ↓
HTTP Client (Infrastructure)
  ↓
REST Backend
```

### Authentication
```
Save tokens after login
  ↓
TokenStorage.saveTokens()
  ↓
DioClient reads from storage
  ↓
Auto-injects: Authorization: Bearer <token>
  ↓
401 response → Clear tokens & ask re-login
```

### Data Flow
```
User Input → Provider → Repository → Service → DioClient
     ↑                                              ↓
     └──────────────────────────────────────────────┘
          Backend Response → Deserialization
```

---

## 📞 Common Questions

### Q: "What do I need to do first?"
**A**: Follow `QUICKSTART_REST_INTEGRATION.md` (5 minutes)

### Q: "How do I test if the backend integration works?"
**A**: Navigate to `/api-debug` route and click test buttons

### Q: "What if I get a 'ProviderNotFoundException'?"
**A**: Wrap your app with `ProviderScope`. See `QUICKSTART_REST_INTEGRATION.md`

### Q: "How do I handle 401 Unauthorized?"
**A**: DioClient automatically clears tokens. User needs to re-login. See `TROUBLESHOOTING.md`

### Q: "Can I modify the models?"
**A**: Yes, but run `flutter pub run build_runner build` after changes

### Q: "Where should I store user IDs?"
**A**: In `TokenStorage` via `saveTokens(accessToken, refreshToken, userId)`

### Q: "How do I add new endpoints?"
**A**: 
1. Create model in `data/models/`
2. Add method to `*ApiService`
3. Add method to `Repository`
4. Create provider in `app_providers.dart`

### Q: "Is this production-ready?"
**A**: Yes, with these additions:
- Implement your auth system
- Add SSL certificate pinning
- Add analytics & crash reporting
- Add rate limiting & caching

---

## 🎓 What You'll Learn

By working with this integration:
- Clean Architecture principles
- Riverpod state management
- REST API integration
- JSON serialization
- Error handling patterns
- Secure token management
- Testing & debugging APIs
- Flutter best practices

---

## 📚 Reading Order (Recommended)

1. **This file** (2 min) - Overview
2. **QUICKSTART_REST_INTEGRATION.md** (5 min) - Get set up
3. **API Debug Screen** (5 min) - Test endpoints
4. **trip_search_example.dart** (10 min) - See UI in action
5. **REST_BACKEND_INTEGRATION.md** (20 min) - Understand architecture
6. **ARCHITECTURE_DIAGRAMS.md** (10 min) - Visualize flow

---

## ⚡ Quick Reference

### Search for trips
```dart
final trips = ref.watch(searchMatchingRouteProvider((
  sourceLat: 52.52,
  sourceLon: 13.405,
  sourceRadiusKm: 5,
  destLat: 48.1351,
  destLon: 11.5820,
  destRadiusKm: 5,
  requestedSeats: 2,
  effectiveUserId: userId,
)));

trips.when(
  data: (tripList) => ListView(children: tripList.map((t) => TripCard(t))),
  loading: () => CircularProgressIndicator(),
  error: (e, st) => Text('Error: $e'),
);
```

### Join a trip
```dart
final notifier = ref.read(joinTripProvider.notifier);
await notifier.joinTrip(JoinTripRequest(
  tripId: trip.tripId,
  passengerId: userId,
  driverId: trip.driverId,
  pickupPoint: sourceLocation,
  destinationPoint: destLocation,
  rideStartTime: trip.tripStartDateTime,
  requestedSeats: 2,
));
```

### Offer a trip (driver)
```dart
final notifier = ref.read(offerTripProvider.notifier);
await notifier.offerTrip(OfferRideRequest(
  driverId: userId,
  vehicleNumber: 'ABC-1234',
  sourceAddress: Points(...),
  destinationAddress: Points(...),
  tripStartDateTime: '2024-01-15T10:00:00Z',
  offeredSeat: 4,
));
```

---

## 🚦 Red Flags (Check These If Stuck)

- ❌ "ProviderNotFoundException" → Add ProviderScope in main.dart
- ❌ "Cannot find .g.dart files" → Run `flutter pub run build_runner build`
- ❌ "UnauthorizedException" → Token missing, user needs to login
- ❌ "Connection refused" → Backend not running or wrong URL
- ❌ "Null check operator used" → Check nullable fields with `??` or `.when()`

See `TROUBLESHOOTING.md` for detailed solutions.

---

## ✨ You're Ready to Go!

Choose your entry point from above and dive in. The integration is production-ready and just waiting for you to customize it.

**Recommended first step:**
1. Open `QUICKSTART_REST_INTEGRATION.md`
2. Follow the 5-step setup
3. Run the app and navigate to `/api-debug`
4. Click a button to test an endpoint

Good luck! 🚀

---

**Questions?** Check these in order:
1. TROUBLESHOOTING.md (if something broke)
2. QUICKSTART_REST_INTEGRATION.md (if need setup help)
3. REST_BACKEND_INTEGRATION.md (if need explanation)
4. ARCHITECTURE_DIAGRAMS.md (if need visual help)

Happy coding! 💻
