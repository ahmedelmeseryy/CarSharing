# Backend Issues & Feature Requests

**Date:** January 9, 2026  
**Priority:** High  
**From:** Mobile Team  

---

## 1. 🔍 Trip Search: Flexible Date/Time Matching

**Current Behavior:**  
The `/trip-service/api/trips/match-ride` endpoint requires **exact date and time** parameters to return matching trips.

**Issue:**  
Users cannot find trips unless they search with the precise departure time, which is unrealistic for real-world usage.

**Requested Change:**  
- Allow **date range** searches (e.g., "trips on January 10, 2026 between 8:00 AM - 12:00 PM")
- Support **time window** parameter (e.g., ±2 hours from requested time)
- Return trips that depart within a reasonable timeframe of the search criteria

**API Suggestion:**
```json
{
  "sourceLatitude": 48.8566,
  "sourceLongitude": 2.3522,
  "destinationLatitude": 48.8606,
  "destinationLongitude": 2.2945,
  "searchDate": "2026-01-10",
  "timeWindow": {
    "startTime": "08:00:00",
    "endTime": "12:00:00"
  },
  "radius": 5000
}
```

---

## 2. 🎫 Multiple Bookings Per Ride

**Current Behavior:**  
The system prevents booking the same trip multiple times (returns 409 ALREADY_BOOKED).

**Issue:**  
Users should be able to:
- Book multiple seats in a **single booking** (e.g., booking 3 seats for a family)
- Create multiple separate bookings for the same trip if needed (different pickup points, split payments, etc.)

**Requested Changes:**

### Option A: Multiple Seats in One Booking (Preferred)
- `POST /trip-service/api/bookings/join` already accepts `requestedSeats` parameter
- Ensure backend processes multi-seat bookings correctly
- Deduct all requested seats from `availableSeats` atomically

### Option B: Multiple Independent Bookings
- Remove or modify the duplicate booking check
- Allow same `passengerId` to create multiple bookings for the same `tripId`
- Each booking should have a unique `rideId`

**Current Request Format:**
```json
{
  "tripId": "trip-123",
  "passengerId": "user-456",
  "driverId": "driver-789",
  "requestedSeats": 2,  // ← Should work for multiple seats
  "pickupPoint": {...},
  "destinationPoint": {...}
}
```

---

## 3. 🐛 Critical Bug: Bookings Not Appearing in Lists

**Affected Endpoints:**  
- `GET /trip-service/api/bookings/active/passenger/{passengerId}` (passenger side)
- Presumably also driver-side endpoint for viewing trip passengers

**Current Behavior:**  
1. User successfully creates booking: `POST /trip-service/api/bookings/join`
   - Returns **HTTP 201 Created** with booking details
   - Response includes `rideId`, `tripId`, `rideStatus`, etc.

2. Querying bookings list: `GET /trip-service/api/bookings/active/passenger/{passengerId}`
   - Returns **HTTP 404 Not Found**
   - Endpoint does **NOT exist** on the backend

**Expected Behavior:**  
- Endpoint should return `HTTP 200` with list of bookings
- Newly created bookings should **immediately appear** in list
- Driver should see all passengers who booked their trips

**Root Cause:**
- **The `/trip-service/api/bookings/active/passenger/{passengerId}` endpoint is not implemented/deployed on the backend**

**Test Case:**
```bash
# 1. Create booking (works)
curl -X POST http://34.160.91.182/trip-service/api/bookings/join \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "tripId": "test-trip-123",
    "passengerId": "rhPRMNYhfAbi82xzbuYvKySEvWw1",
    "requestedSeats": 1,
    ...
  }'
# Response: 201 Created, rideId: "abc-123"

# 2. Query bookings (FAILS with 404)
curl http://34.160.91.182/trip-service/api/bookings/active/passenger/rhPRMNYhfAbi82xzbuYvKySEvWw1 \
  -H "Authorization: Bearer ${TOKEN}"
# Response: 404 Not Found  ← ENDPOINT DOESN'T EXIST
```

**Action Required:**
Please implement and deploy the following endpoints:
- `GET /trip-service/api/bookings/active/passenger/{passengerId}` - List passenger's active bookings
- `GET /trip-service/api/trips/{tripId}/bookings` - List passengers for a driver's trip

**Workaround Implemented (Client-Side):**  
We've added local caching to show bookings immediately after creation, but this is a **temporary fix**. The backend endpoints must be implemented.

---

## 4. � Critical Bug: Trip Search Returns Internal Server Error

**Affected Endpoint:**  
`GET /trip-service/api/trips/search/matching-route`

**Current Behavior:**  
The endpoint returns **HTTP 400 Bad Request** with an internal server error when valid parameters are provided.

**Test Case:**
```bash
curl "http://34.160.91.182/trip-service/api/trips/search/matching-route?\
sourceLatitude=50.8090106&\
sourceLongitude=8.7704695&\
sourceRadiusKm=10.0&\
destinationLatitude=50.1106444&\
destinationLongitude=8.6820917&\
destinationRadiusKm=10.0&\
earliestDepartureTime=2026-01-11T16:21:00.000Z&\
requestedSeats=1" \
  -H "Authorization: Bearer ${TOKEN}"

# Response: 400 Bad Request
{
  "status": 400,
  "code": "INTERNAL_SERVER_ERROR",
  "message": "An unexpected error occurred",
  "timestamp": "2026-01-11T16:21:18.677226165Z"
}
```

**Expected Behavior:**  
Should return **HTTP 200** with a list of matching trips (or empty array if no matches).

**Parameters Sent (All Required by OpenAPI Spec):**
- `sourceLatitude`: 50.8090106 (double) ✓
- `sourceLongitude`: 8.7704695 (double) ✓
- `sourceRadiusKm`: 10.0 (double) ✓
- `destinationLatitude`: 50.1106444 (double) ✓
- `destinationLongitude`: 8.6820917 (double) ✓
- `destinationRadiusKm`: 10.0 (double) ✓
- `earliestDepartureTime`: 2026-01-11T16:21:00.000Z (ISO string) ✓
- `requestedSeats`: 1 (integer) ✓

**Root Cause:**  
Backend has an internal error/exception when processing the search request. The client is sending correct parameters according to the OpenAPI specification.

**Workaround Implemented (Client-Side):**  
Using alternative endpoints `/search/near-source` and `/search/near-destination` with client-side filtering as a temporary solution.

**Action Required:**  
Debug and fix the `/matching-route` endpoint to handle the search parameters correctly without throwing internal errors.

---

## 5. �🔐 Authentication: Driver/User Role Selection

**Current Behavior:**  
- Authentication endpoints exist (`/api/auth/register`, `/api/auth/login`)
- No role differentiation between drivers and passengers

**Requested Changes:**

### A. Registration Enhancement
Add `userType` field to registration:

**Endpoint:** `POST /api/auth/register`
```json
{
  "name": "John Doe",
  "email": "john@example.com",
  "phone": "+1234567890",
  "password": "securePassword123",
  "userType": "driver" | "passenger"  // ← NEW FIELD
}
```

### B. Login Response Enhancement
Include user role in login response:

**Endpoint:** `POST /api/auth/login`  
**Response:**
```json
{
  "data": {
    "accessToken": "eyJhbGc...",
    "refreshToken": "eyJhbGc...",
    "userId": "user-123",
    "userType": "driver",  // ← NEW FIELD
    "name": "John Doe",
    "email": "john@example.com"
  }
}
```

### C. User Profile Endpoint
Create/update profile endpoint to include role:

**Endpoint:** `GET /api/users/{userId}`  
**Response:**
```json
{
  "userId": "user-123",
  "name": "John Doe",
  "email": "john@example.com",
  "phone": "+1234567890",
  "userType": "driver",  // ← NEW FIELD
  "createdAt": "2026-01-01T10:00:00Z"
}
```

### D. Database Schema
Ensure `users` table/collection has:
- `userType` field (enum: 'driver', 'passenger')
- Optional: Allow users to be **both** driver and passenger (use array or separate table)

---

## Priority Summary

| Issue | Priority | Impact | Estimated Effort |
|-------|----------|--------|------------------|
| **#3** Bookings not appearing | 🔴 **CRITICAL** | Blocks core functionality | Medium |
| **#4** Driver/User roles | 🟠 **HIGH** | Required for app flow | Low |
| **#2** Multiple bookings | 🟡 **MEDIUM** | UX improvement | Low |
| **#1** Flexible date search | 🟡 **MEDIUM** | UX improvement | Medium |

---

## Additional Notes

- **Testing Credentials:** Available upon request
- **API Base URL:** `http://34.160.91.182`
- **Mobile Platform:** Flutter (Android/iOS)
- **Authentication:** JWT Bearer tokens

Please confirm receipt and provide ETAs for fixes. Happy to jump on a call to discuss implementation details.

---

**Contact:**  
Mobile Development Team  
[Your contact information]
