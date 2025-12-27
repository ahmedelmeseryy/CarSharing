# API Specification for Car Sharing App Backend

This document outlines all the REST API endpoints needed to replace Firebase with a custom backend.

## Base URL
```
https://your-api-domain.com/api/v1
```

## Authentication

All endpoints (except auth endpoints) require authentication via Bearer token in the Authorization header:
```
Authorization: Bearer <access_token>
```

---

## 1. Authentication Endpoints

### 1.1 Register User
**POST** `/auth/register`

**Request Body:**
```json
{
  "email": "user@example.com",
  "password": "SecurePass123!",
  "name": "John",
  "surname": "Doe",
  "age": "25",
  "phone": "+1234567890",
  "role": "user" | "driver",
  "car_model": "Toyota Camry",      // Required if role is "driver"
  "car_color": "Blue",               // Required if role is "driver"
  "car_year": "2020",                // Required if role is "driver"
  "license_number": "DL123456"       // Required if role is "driver"
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "user": {
      "id": "user-uuid",
      "email": "user@example.com",
      "name": "John",
      "surname": "Doe",
      "role": "user"
    },
    "access_token": "jwt-access-token",
    "refresh_token": "jwt-refresh-token"
  }
}
```

### 1.2 Login
**POST** `/auth/login`

**Request Body:**
```json
{
  "email": "user@example.com",
  "password": "SecurePass123!"
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "user": {
      "id": "user-uuid",
      "email": "user@example.com",
      "name": "John",
      "surname": "Doe",
      "role": "user" | "driver"
    },
    "access_token": "jwt-access-token",
    "refresh_token": "jwt-refresh-token"
  }
}
```

### 1.3 Phone Authentication (OTP)
**POST** `/auth/phone/send-otp`

**Request Body:**
```json
{
  "phone": "+1234567890"
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "verification_id": "verification-id-string"
  }
}
```

**POST** `/auth/phone/verify-otp`

**Request Body:**
```json
{
  "verification_id": "verification-id-string",
  "otp": "123456"
}
```

**Response:** Same as login response

### 1.4 Password Reset
**POST** `/auth/password/reset`

**Request Body:**
```json
{
  "email": "user@example.com"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Password reset email sent"
}
```

### 1.5 Logout
**POST** `/auth/logout`

**Headers:**
```
Authorization: Bearer <access_token>
```

**Response:**
```json
{
  "success": true,
  "message": "Logged out successfully"
}
```

### 1.6 Refresh Token
**POST** `/auth/refresh`

**Request Body:**
```json
{
  "refresh_token": "jwt-refresh-token"
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "access_token": "new-jwt-access-token"
  }
}
```

---

## 2. User Management Endpoints

### 2.1 Get Current User
**GET** `/users/me`

**Response:**
```json
{
  "success": true,
  "data": {
    "id": "user-uuid",
    "email": "user@example.com",
    "name": "John",
    "surname": "Doe",
    "age": "25",
    "phone": "+1234567890",
    "role": "user" | "driver",
    "car_model": "Toyota Camry",
    "car_color": "Blue",
    "car_year": "2020",
    "license_number": "DL123456",
    "license_image_url": "https://...",
    "created_at": "2024-01-15T10:30:00Z",
    "updated_at": "2024-01-15T10:30:00Z"
  }
}
```

### 2.2 Update User Profile
**PUT** `/users/me`

**Request Body:**
```json
{
  "name": "John",
  "surname": "Doe",
  "age": "25",
  "phone": "+1234567890",
  "car_model": "Toyota Camry",
  "car_color": "Blue",
  "car_year": "2020",
  "license_number": "DL123456"
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "id": "user-uuid",
    "email": "user@example.com",
    "name": "John",
    "surname": "Doe",
    // ... other fields
    "updated_at": "2024-01-15T10:30:00Z"
  }
}
```

### 2.3 Get User by ID
**GET** `/users/{userId}`

**Response:**
```json
{
  "success": true,
  "data": {
    "id": "user-uuid",
    "name": "John",
    "surname": "Doe",
    "role": "driver",
    "car_model": "Toyota Camry",
    "car_color": "Blue",
    "car_year": "2020",
    "license_number": "DL123456",
    "license_image_url": "https://...",
    "rating": 4.5,
    "total_reviews": 10
  }
}
```

### 2.4 Upload License Image
**POST** `/users/me/license-image`

**Content-Type:** `multipart/form-data`

**Request Body:**
```
file: <image file>
```

**Response:**
```json
{
  "success": true,
  "data": {
    "license_image_url": "https://your-cdn.com/licenses/user-uuid.jpg"
  }
}
```

---

## 3. Trip Management Endpoints

### 3.1 Create Trip
**POST** `/trips`

**Request Body:**
```json
{
  "from": "Berlin",
  "to": "Munich",
  "date": "2024-02-15T14:30:00Z",
  "seats": 4,
  "price": 35.50
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "id": "trip-uuid",
    "from": "Berlin",
    "to": "Munich",
    "date": "2024-02-15T14:30:00Z",
    "seats": 4,
    "price": 35.50,
    "driver_id": "driver-uuid",
    "driver_name": "John Doe",
    "created_at": "2024-01-15T10:30:00Z"
  }
}
```

### 3.2 Get All Available Trips
**GET** `/trips`

**Query Parameters:**
- `from` (optional): Filter by origin city
- `to` (optional): Filter by destination city
- `date` (optional): Filter by date (ISO 8601)
- `min_seats` (optional): Minimum available seats
- `max_price` (optional): Maximum price
- `page` (optional): Page number (default: 1)
- `limit` (optional): Items per page (default: 20)

**Response:**
```json
{
  "success": true,
  "data": {
    "trips": [
      {
        "id": "trip-uuid",
        "from": "Berlin",
        "to": "Munich",
        "date": "2024-02-15T14:30:00Z",
        "seats": 4,
        "price": 35.50,
        "driver_id": "driver-uuid",
        "driver_name": "John Doe",
        "created_at": "2024-01-15T10:30:00Z"
      }
    ],
    "pagination": {
      "page": 1,
      "limit": 20,
      "total": 100,
      "total_pages": 5
    }
  }
}
```

### 3.3 Get Trip by ID
**GET** `/trips/{tripId}`

**Response:**
```json
{
  "success": true,
  "data": {
    "id": "trip-uuid",
    "from": "Berlin",
    "to": "Munich",
    "date": "2024-02-15T14:30:00Z",
    "seats": 4,
    "price": 35.50,
    "driver_id": "driver-uuid",
    "driver_name": "John Doe",
    "created_at": "2024-01-15T10:30:00Z",
    "updated_at": "2024-01-15T10:30:00Z"
  }
}
```

### 3.4 Get Driver's Trips
**GET** `/trips/driver/me`

**Query Parameters:**
- `page` (optional): Page number
- `limit` (optional): Items per page

**Response:**
```json
{
  "success": true,
  "data": {
    "trips": [
      {
        "id": "trip-uuid",
        "from": "Berlin",
        "to": "Munich",
        "date": "2024-02-15T14:30:00Z",
        "seats": 4,
        "price": 35.50,
        "driver_id": "driver-uuid",
        "driver_name": "John Doe",
        "created_at": "2024-01-15T10:30:00Z"
      }
    ],
    "pagination": {
      "page": 1,
      "limit": 20,
      "total": 10
    }
  }
}
```

### 3.5 Update Trip
**PUT** `/trips/{tripId}`

**Request Body:**
```json
{
  "seats": 3,
  "price": 40.00
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "id": "trip-uuid",
    "from": "Berlin",
    "to": "Munich",
    "date": "2024-02-15T14:30:00Z",
    "seats": 3,
    "price": 40.00,
    "driver_id": "driver-uuid",
    "driver_name": "John Doe",
    "updated_at": "2024-01-15T10:30:00Z"
  }
}
```

### 3.6 Delete Trip
**DELETE** `/trips/{tripId}`

**Response:**
```json
{
  "success": true,
  "message": "Trip deleted successfully"
}
```

---

## 4. Booking Management Endpoints

### 4.1 Create Booking
**POST** `/bookings`

**Request Body:**
```json
{
  "trip_id": "trip-uuid",
  "seats": 2,
  "payment_method": "cash" | "card"
}
```

**Note:** This endpoint should:
1. Check if trip exists
2. Check if enough seats are available
3. Atomically decrement trip seats
4. Create booking record
5. Return booking with calculated total price

**Response:**
```json
{
  "success": true,
  "data": {
    "id": "booking-uuid",
    "trip_id": "trip-uuid",
    "user_id": "user-uuid",
    "driver_id": "driver-uuid",
    "seats": 2,
    "total_price": 71.00,
    "payment_method": "cash",
    "status": "confirmed",
    "trip_from": "Berlin",
    "trip_to": "Munich",
    "trip_date": "2024-02-15T14:30:00Z",
    "passenger_name": "Jane Smith",
    "created_at": "2024-01-15T10:30:00Z"
  }
}
```

### 4.2 Get User's Bookings
**GET** `/bookings/me`

**Query Parameters:**
- `status` (optional): Filter by status (confirmed, cancelled, pending)
- `page` (optional): Page number
- `limit` (optional): Items per page

**Response:**
```json
{
  "success": true,
  "data": {
    "bookings": [
      {
        "id": "booking-uuid",
        "trip_id": "trip-uuid",
        "user_id": "user-uuid",
        "driver_id": "driver-uuid",
        "seats": 2,
        "total_price": 71.00,
        "payment_method": "cash",
        "status": "confirmed",
        "trip_from": "Berlin",
        "trip_to": "Munich",
        "trip_date": "2024-02-15T14:30:00Z",
        "passenger_name": "Jane Smith",
        "created_at": "2024-01-15T10:30:00Z"
      }
    ],
    "pagination": {
      "page": 1,
      "limit": 20,
      "total": 5
    }
  }
}
```

### 4.3 Get Driver's Bookings
**GET** `/bookings/driver/me`

**Query Parameters:**
- `status` (optional): Filter by status
- `trip_id` (optional): Filter by trip ID
- `page` (optional): Page number
- `limit` (optional): Items per page

**Response:** Same structure as 4.2

### 4.4 Get Bookings for a Trip
**GET** `/trips/{tripId}/bookings`

**Response:**
```json
{
  "success": true,
  "data": {
    "bookings": [
      {
        "id": "booking-uuid",
        "trip_id": "trip-uuid",
        "user_id": "user-uuid",
        "seats": 2,
        "total_price": 71.00,
        "payment_method": "cash",
        "status": "confirmed",
        "passenger_name": "Jane Smith",
        "created_at": "2024-01-15T10:30:00Z"
      }
    ]
  }
}
```

### 4.5 Get Booking by ID
**GET** `/bookings/{bookingId}`

**Response:**
```json
{
  "success": true,
  "data": {
    "id": "booking-uuid",
    "trip_id": "trip-uuid",
    "user_id": "user-uuid",
    "driver_id": "driver-uuid",
    "seats": 2,
    "total_price": 71.00,
    "payment_method": "cash",
    "status": "confirmed",
    "trip_from": "Berlin",
    "trip_to": "Munich",
    "trip_date": "2024-02-15T14:30:00Z",
    "passenger_name": "Jane Smith",
    "created_at": "2024-01-15T10:30:00Z",
    "cancelled_at": null,
    "cancelled_by": null
  }
}
```

### 4.6 Cancel Booking
**PUT** `/bookings/{bookingId}/cancel`

**Request Body:**
```json
{
  "cancelled_by": "driver" | "user"
}
```

**Note:** This endpoint should:
1. Update booking status to "cancelled"
2. Atomically increment trip seats (refund seats)
3. Set cancelled_at timestamp
4. Set cancelled_by field

**Response:**
```json
{
  "success": true,
  "data": {
    "id": "booking-uuid",
    "status": "cancelled",
    "cancelled_at": "2024-01-15T11:00:00Z",
    "cancelled_by": "driver"
  }
}
```

---

## 5. Reviews Endpoints (if implemented)

### 5.1 Create Review
**POST** `/reviews`

**Request Body:**
```json
{
  "driver_id": "driver-uuid",
  "trip_id": "trip-uuid",
  "rating": 5,
  "comment": "Great driver, very punctual!"
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "id": "review-uuid",
    "driver_id": "driver-uuid",
    "user_id": "user-uuid",
    "trip_id": "trip-uuid",
    "rating": 5,
    "comment": "Great driver, very punctual!",
    "created_at": "2024-01-15T10:30:00Z"
  }
}
```

### 5.2 Get Reviews for Driver
**GET** `/reviews/driver/{driverId}`

**Query Parameters:**
- `page` (optional): Page number
- `limit` (optional): Items per page

**Response:**
```json
{
  "success": true,
  "data": {
    "reviews": [
      {
        "id": "review-uuid",
        "driver_id": "driver-uuid",
        "user_id": "user-uuid",
        "user_name": "Jane Smith",
        "trip_id": "trip-uuid",
        "rating": 5,
        "comment": "Great driver, very punctual!",
        "created_at": "2024-01-15T10:30:00Z"
      }
    ],
    "pagination": {
      "page": 1,
      "limit": 20,
      "total": 10
    }
  }
}
```

---

## 6. Favorites Endpoints (if implemented)

### 6.1 Add Trip to Favorites
**POST** `/favorites`

**Request Body:**
```json
{
  "trip_id": "trip-uuid"
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "id": "favorite-uuid",
    "user_id": "user-uuid",
    "trip_id": "trip-uuid",
    "created_at": "2024-01-15T10:30:00Z"
  }
}
```

### 6.2 Get User's Favorites
**GET** `/favorites/me`

**Response:**
```json
{
  "success": true,
  "data": {
    "favorites": [
      {
        "id": "favorite-uuid",
        "trip_id": "trip-uuid",
        "trip": {
          "id": "trip-uuid",
          "from": "Berlin",
          "to": "Munich",
          "date": "2024-02-15T14:30:00Z",
          "seats": 4,
          "price": 35.50,
          "driver_name": "John Doe"
        },
        "created_at": "2024-01-15T10:30:00Z"
      }
    ]
  }
}
```

### 6.3 Remove from Favorites
**DELETE** `/favorites/{favoriteId}`

**Response:**
```json
{
  "success": true,
  "message": "Removed from favorites"
}
```

---

## 7. Real-Time Subscriptions

Since the app uses `StreamBuilder` with `.snapshots()`, you'll need to implement real-time updates. Options:

### Option 1: WebSocket Connection
**WebSocket URL:** `wss://your-api-domain.com/ws`

**Connection:**
```javascript
// Connect with auth token
ws://your-api-domain.com/ws?token=<access_token>
```

**Subscribe to trips:**
```json
{
  "action": "subscribe",
  "channel": "trips",
  "filters": {
    "from": "Berlin",
    "to": "Munich"
  }
}
```

**Subscribe to user bookings:**
```json
{
  "action": "subscribe",
  "channel": "bookings",
  "user_id": "user-uuid"
}
```

**Subscribe to driver bookings:**
```json
{
  "action": "subscribe",
  "channel": "bookings",
  "driver_id": "driver-uuid"
}
```

**Subscribe to trip bookings:**
```json
{
  "action": "subscribe",
  "channel": "bookings",
  "trip_id": "trip-uuid"
}
```

**Message Format:**
```json
{
  "channel": "trips" | "bookings" | "users",
  "event": "created" | "updated" | "deleted",
  "data": { /* object data */ }
}
```

### Option 2: Server-Sent Events (SSE)
**GET** `/events/trips`
**GET** `/events/bookings?user_id={userId}`
**GET** `/events/bookings?driver_id={driverId}`
**GET** `/events/bookings?trip_id={tripId}`

**Headers:**
```
Authorization: Bearer <access_token>
Accept: text/event-stream
```

**Event Format:**
```
event: created
data: {"id": "trip-uuid", "from": "Berlin", ...}

event: updated
data: {"id": "trip-uuid", "seats": 3, ...}

event: deleted
data: {"id": "trip-uuid"}
```

### Option 3: Polling (Fallback)
If real-time is not available, implement polling:
- Poll every 5-10 seconds for updates
- Use `If-Modified-Since` header or `updated_at` query parameter

---

## 8. Data Schemas

### User Schema
```json
{
  "id": "string (UUID)",
  "email": "string (unique)",
  "password": "string (hashed)",
  "name": "string",
  "surname": "string",
  "age": "string",
  "phone": "string",
  "role": "enum: user | driver",
  "car_model": "string (nullable, required if driver)",
  "car_color": "string (nullable, required if driver)",
  "car_year": "string (nullable, required if driver)",
  "license_number": "string (nullable, required if driver)",
  "license_image_url": "string (nullable)",
  "created_at": "datetime (ISO 8601)",
  "updated_at": "datetime (ISO 8601)"
}
```

### Trip Schema
```json
{
  "id": "string (UUID)",
  "from": "string",
  "to": "string",
  "date": "datetime (ISO 8601)",
  "seats": "integer",
  "price": "decimal",
  "driver_id": "string (UUID, foreign key)",
  "driver_name": "string",
  "created_at": "datetime (ISO 8601)",
  "updated_at": "datetime (ISO 8601)"
}
```

### Booking Schema
```json
{
  "id": "string (UUID)",
  "trip_id": "string (UUID, foreign key)",
  "user_id": "string (UUID, foreign key)",
  "driver_id": "string (UUID, foreign key)",
  "seats": "integer",
  "total_price": "decimal",
  "payment_method": "enum: cash | card",
  "status": "enum: confirmed | cancelled | pending",
  "trip_from": "string (denormalized)",
  "trip_to": "string (denormalized)",
  "trip_date": "datetime (denormalized)",
  "passenger_name": "string (denormalized)",
  "created_at": "datetime (ISO 8601)",
  "cancelled_at": "datetime (nullable)",
  "cancelled_by": "enum: driver | user (nullable)"
}
```

### Review Schema
```json
{
  "id": "string (UUID)",
  "driver_id": "string (UUID, foreign key)",
  "user_id": "string (UUID, foreign key)",
  "trip_id": "string (UUID, foreign key)",
  "rating": "integer (1-5)",
  "comment": "string (nullable)",
  "created_at": "datetime (ISO 8601)"
}
```

---

## 9. Error Responses

All endpoints should return errors in this format:

```json
{
  "success": false,
  "error": {
    "code": "ERROR_CODE",
    "message": "Human-readable error message",
    "details": {} // Optional additional details
  }
}
```

### Common Error Codes:
- `UNAUTHORIZED` (401): Invalid or missing token
- `FORBIDDEN` (403): User doesn't have permission
- `NOT_FOUND` (404): Resource not found
- `VALIDATION_ERROR` (400): Invalid request data
- `CONFLICT` (409): Resource conflict (e.g., not enough seats)
- `INTERNAL_ERROR` (500): Server error

---

## 10. Important Implementation Notes

### 10.1 Atomic Operations
- **Booking Creation**: Must be atomic (transaction) to prevent race conditions
- **Booking Cancellation**: Must atomically refund seats to trip
- **Trip Seat Updates**: Must be atomic when bookings are created/cancelled

### 10.2 Denormalization
The booking schema includes denormalized fields (`trip_from`, `trip_to`, `trip_date`, `passenger_name`) for easier querying. Keep these in sync when:
- Trip details are updated
- User name is updated

### 10.3 Indexing Requirements
Create database indexes on:
- `trips.driver_id`
- `trips.date`
- `trips.from`
- `trips.to`
- `bookings.user_id`
- `bookings.driver_id`
- `bookings.trip_id`
- `bookings.status`

### 10.4 Security Considerations
- Validate user ownership before allowing updates/deletes
- Drivers can only cancel bookings for their own trips
- Users can only cancel their own bookings
- Validate seat availability before creating bookings
- Implement rate limiting on auth endpoints

### 10.5 File Uploads
- License images should be uploaded to cloud storage (S3, Cloudinary, etc.)
- Return public URL after upload
- Validate file type and size on backend

---

## 11. Migration Checklist

When migrating from Firebase:

1. ✅ Replace `FirebaseAuth` with JWT-based authentication
2. ✅ Replace `FirebaseFirestore.collection().add()` with POST endpoints
3. ✅ Replace `FirebaseFirestore.collection().doc().get()` with GET endpoints
4. ✅ Replace `FirebaseFirestore.collection().doc().update()` with PUT endpoints
5. ✅ Replace `FirebaseFirestore.collection().doc().delete()` with DELETE endpoints
6. ✅ Replace `.where().orderBy().snapshots()` with filtered GET endpoints + WebSocket/SSE
7. ✅ Replace `runTransaction()` with atomic backend operations
8. ✅ Replace `FieldValue.serverTimestamp()` with server-generated timestamps
9. ✅ Implement real-time subscriptions (WebSocket/SSE)
10. ✅ Handle authentication token refresh
11. ✅ Update error handling for REST API errors
12. ✅ Implement retry logic for network failures

---

## 12. Example Implementation Stack

### Backend Options:
- **Node.js/Express** with PostgreSQL/MongoDB
- **Python/Django** or **FastAPI** with PostgreSQL
- **Go/Gin** with PostgreSQL
- **Ruby on Rails** with PostgreSQL
- **Java/Spring Boot** with PostgreSQL

### Database:
- **PostgreSQL** (recommended for relational data)
- **MongoDB** (if you prefer NoSQL)
- **MySQL** (alternative relational option)

### Real-time:
- **Socket.io** (Node.js)
- **WebSockets** (native)
- **Server-Sent Events** (simpler, one-way)
- **Pusher/Ably** (managed service)

### Authentication:
- **JWT** (JSON Web Tokens)
- **OAuth 2.0** (for social login if needed)

---

This specification covers all the endpoints needed to replace Firebase functionality in your car sharing app.
