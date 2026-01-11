## Search Endpoint Issues - Server-Side Errors

### Problem
All trip search endpoints are returning 400 errors with "INTERNAL_SERVER_ERROR":

- `/trip-service/api/trips/search/matching-route` ❌
- `/trip-service/api/trips/search/near-source` ❌  
- `/trip-service/api/trips/search/near-destination` ❌

### Test Results
```
Test 1 (matching-route with params): 400 INTERNAL_SERVER_ERROR
Test 2 (matching-route minimal): 400 INTERNAL_SERVER_ERROR
Test 3 (near-source): 400 INTERNAL_SERVER_ERROR
```

### Server Response
```json
{
  "status": 400,
  "code": "INTERNAL_SERVER_ERROR",
  "message": "An unexpected error occurred",
  "error": {
    "path": "/trip-service/api/trips/search/...",
    "details": []
  }
}
```

### Conclusion
The backend search endpoints are either:
1. Not fully implemented
2. Have server-side bugs
3. Are expecting a different authentication or request format

The client requests are correctly formatted. This is confirmed by testing with all optional params, no optional params, and different endpoints - all fail with the same server error.

### Recommendation
**Contact the backend team** to:
1. Check server logs for the error details (the `requestId` is provided in each response)
2. Verify the search endpoint implementation
3. Confirm expected request format and parameters
4. Test the endpoints directly (e.g., with Postman/curl)

### Temporary Workaround
Until the search endpoints are fixed, the app can:
1. Display a "Search temporarily unavailable" message
2. Show all trips from a different endpoint (if available)
3. Use Firebase search as fallback (if still available)
