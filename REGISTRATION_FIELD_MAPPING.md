# Registration Field Mapping - UI to Backend

## User Registration Payload
When a user (non-driver) submits the registration form, the following JSON is sent to `POST /api/auth/register`:

```json
{
  "email": "user@example.com",
  "password": "@Asd123123",
  "name": "Ahmed",
  "surname": "User",
  "age": "25",
  "phone": "+1234567890",
  "role": "user"
}
```

### Field Details - User Role
| Field | Type | Required | Example | Notes |
|-------|------|----------|---------|-------|
| `email` | String | ✅ Yes | `elmesery72@gmail.com` | Must be valid email |
| `password` | String | ✅ Yes | `@Asd123123` | At least 8 chars, mixed case, numbers, special chars |
| `name` | String | ✅ Yes | `Ahmed` | First name |
| `surname` | String | ✅ Yes | `User` | Last name |
| `age` | String | ✅ Yes | `"25"` | Sent as string, minimum 18 |
| `phone` | String | ✅ Yes | `""` or phone number | Can be empty string |
| `role` | String | ✅ Yes | `"user"` | Fixed value: "user" or "driver" |

---

## Driver Registration Payload
When a driver submits the registration form, the following JSON is sent to `POST /api/auth/register`:

```json
{
  "email": "driver@example.com",
  "password": "@Asd123123",
  "name": "Ahmed",
  "surname": "Driver",
  "age": "30",
  "phone": "+1234567890",
  "role": "driver",
  "carModel": "Toyota Camry",
  "carColor": "Silver",
  "carYear": "2020",
  "licenseNumber": "DL123456789"
}
```

### Field Details - Driver Role
| Field | Type | Required | Example | Notes |
|-------|------|----------|---------|-------|
| `email` | String | ✅ Yes | `driver@example.com` | Must be valid email |
| `password` | String | ✅ Yes | `@Asd123123` | At least 8 chars, mixed case, numbers, special chars |
| `name` | String | ✅ Yes | `Ahmed` | First name |
| `surname` | String | ✅ Yes | `Driver` | Last name |
| `age` | String | ✅ Yes | `"30"` | Sent as string, minimum 18 |
| `phone` | String | ✅ Yes | `"+1234567890"` | Phone number |
| `role` | String | ✅ Yes | `"driver"` | Fixed value: "driver" |
| `carModel` | String | ✅ Yes | `Toyota Camry` | Car make and model |
| `carColor` | String | ✅ Yes | `Silver` | Vehicle color |
| `carYear` | String | ✅ Yes | `"2020"` | Year as string, must be valid year (1900-current) |
| `licenseNumber` | String | ✅ Yes | `DL123456789` | Driver license number |

---

## Expected Response (On Success)
```json
{
  "data": {
    "access_token": "eyJhbGciOiJIUzI1NiIsInR...",
    "refresh_token": "eyJhbGciOiJIUzI1NiIsInR...",
    "user": {
      "id": "user-123",
      "email": "user@example.com",
      "name": "Ahmed",
      "surname": "User",
      "role": "user",
      "createdAt": "2026-01-07T22:39:56Z"
    }
  },
  "message": "User registered successfully",
  "timestamp": "2026-01-07T22:39:56Z"
}
```

---

## Expected Response (On Error - 500)
```json
{
  "status": 500,
  "code": "INTERNAL_SERVER_ERROR",
  "message": "An unexpected error occurred at the gateway level.",
  "error": {
    "path": "/api/auth/register",
    "details": []
  },
  "timestamp": "2026-01-07T22:39:56Z"
}
```

---

## Common Field Validation Rules (In UI)

### Email
- Must be valid email format
- Example: `elmesery72@gmail.com`

### Password
- Minimum 8 characters
- Must contain uppercase and lowercase letters
- Must contain at least one number
- Must contain at least one special character

### Age
- Must be 18 or older
- Sent as string in JSON

### Phone
- Can be empty string for regular users
- For drivers, should contain valid phone number
- Format: Any valid phone format (will be validated by backend)

### Car Year (Driver Only)
- Must be between 1900 and current year
- Sent as string in JSON

### Role
- Only two valid values: `"user"` or `"driver"`
- Determines which additional fields are required

---

## Backend Implementation Checklist

The backend `/api/auth/register` endpoint should:

- [ ] Accept POST requests with JSON body
- [ ] Validate all required fields are present
- [ ] Validate email format
- [ ] Validate password strength
- [ ] Validate age is >= 18
- [ ] Validate role is either "user" or "driver"
- [ ] If role is "driver", require: carModel, carColor, carYear, licenseNumber
- [ ] Check if email already exists in database
- [ ] Hash password securely
- [ ] Create user record in database
- [ ] Generate JWT access_token and refresh_token
- [ ] Return 201 Created with tokens and user data
- [ ] Return appropriate error codes (400, 409, 500, etc.)

---

## Testing the Endpoint

### Test Case 1: Valid User Registration
```bash
curl -X POST http://34.160.91.182/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "testuser@example.com",
    "password": "@Asd123123",
    "name": "Test",
    "surname": "User",
    "age": "25",
    "phone": "",
    "role": "user"
  }'
```

### Test Case 2: Valid Driver Registration
```bash
curl -X POST http://34.160.91.182/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "testdriver@example.com",
    "password": "@Asd123123",
    "name": "Test",
    "surname": "Driver",
    "age": "30",
    "phone": "+1234567890",
    "role": "driver",
    "carModel": "Toyota Camry",
    "carColor": "Silver",
    "carYear": "2020",
    "licenseNumber": "DL123456789"
  }'
```

### Test Case 3: Duplicate Email
```bash
# Should return 409 Conflict
curl -X POST http://34.160.91.182/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "existing@example.com",
    "password": "@Asd123123",
    "name": "Test",
    "surname": "User",
    "age": "25",
    "phone": "",
    "role": "user"
  }'
```

### Test Case 4: Missing Required Field
```bash
# Missing password - should return 400 Bad Request
curl -X POST http://34.160.91.182/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "testuser@example.com",
    "name": "Test",
    "surname": "User",
    "age": "25",
    "phone": "",
    "role": "user"
  }'
```

---

## Current Issue (500 Error)

The backend is returning a 500 error when registration is attempted. This suggests:

1. **Gateway-level error**: The API Gateway is not properly forwarding requests to the auth service
2. **Service misconfiguration**: The auth service might not be deployed or configured correctly
3. **Database connection**: The auth service cannot connect to the database
4. **Missing environment variables**: Required backend configs are missing

**Action Items for Backend Developer:**
- [ ] Check server logs for `/api/auth/register` endpoint
- [ ] Verify the authentication service is running
- [ ] Check database connectivity
- [ ] Verify API Gateway routing configuration
- [ ] Test the endpoint directly on the server with curl

---

**Last Updated**: 2026-01-07
**Status**: ✅ UI field mapping verified and aligned
