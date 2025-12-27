import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;

class PlacePrediction {
  final String placeId;
  final String description;
  final String mainText;
  final String secondaryText;

  PlacePrediction({
    required this.placeId,
    required this.description,
    required this.mainText,
    required this.secondaryText,
  });

  factory PlacePrediction.fromJson(Map<String, dynamic> json) {
    return PlacePrediction(
      placeId: (json['osm_id'] ?? json['place_id'] ?? '').toString(),
      description: json['display_name'] ?? '',
      mainText: _extractMainText(json['display_name'] ?? ''),
      secondaryText: _extractSecondaryText(json['display_name'] ?? ''),
    );
  }

  static String _extractMainText(String displayName) {
    final parts = displayName.split(',');
    return parts.isNotEmpty ? parts[0].trim() : displayName;
  }

  static String _extractSecondaryText(String displayName) {
    final parts = displayName.split(',');
    if (parts.length > 1) {
      return parts.sublist(1).join(',').trim();
    }
    return '';
  }
}

class PlaceLocation {
  final double latitude;
  final double longitude;
  final String address;

  PlaceLocation({
    required this.latitude,
    required this.longitude,
    required this.address,
  });
}

class PlacesService {
  // OpenStreetMap Nominatim API (free, no API key required!)
  static const String _nominatimBaseUrl = 'https://nominatim.openstreetmap.org';

  // Simple in-memory cache to avoid repeated Nominatim requests
  static final Map<String, _CacheEntry> _cache = {};

  // Track ongoing requests per query to coalesce concurrent calls
  static final Map<String, Future<List<PlacePrediction>>> _ongoingRequests = {};

  // Minimum interval between outbound requests for the same query (ms)
  static const int _minRequestIntervalMs = 250;

  // Cache TTL
  static const Duration _cacheTtl = Duration(seconds: 60);

  /// Get place predictions (autocomplete suggestions) using Nominatim API
  static Future<List<PlacePrediction>> getPlacePredictions(String input) async {
    if (input.isEmpty) {
      return [];
    }
    final key = input.trim().toLowerCase();

    // Return cached results if fresh
    final cached = _cache[key];
    if (cached != null && DateTime.now().isBefore(cached.expiry)) {
      print('[NOMINATIM CACHE] Cache hit for "$key" - ${cached.predictions.length} results');
      return cached.predictions;
    }

    // If we have a stale cache entry (expired), return it immediately to
    // improve UX when the network is flaky, and refresh in background.
    if (cached != null) {
      print('[NOMINATIM CACHE] Returning stale cache for "$key" (${cached.predictions.length} results) and refreshing in background');
      // Fire-and-forget refresh
      _fetchPredictions(key).then((results) {
        if (results.isNotEmpty) {
          _cache[key] = _CacheEntry(predictions: results, expiry: DateTime.now().add(_cacheTtl));
          print('[NOMINATIM CACHE] Background refresh updated cache for "$key" with ${results.length} results');
        } else {
          print('[NOMINATIM CACHE] Background refresh returned no results for "$key"');
        }
      }).catchError((e) {
        print('[NOMINATIM CACHE] Background refresh error for "$key": $e');
      });

      return cached.predictions;
    }

    // If a request for this key is already ongoing, return its Future (coalesce)
    if (_ongoingRequests.containsKey(key)) {
      print('[NOMINATIM REQUEST] Request already in progress for "$key", coalescing...');
      try {
        return await _ongoingRequests[key]!;
      } catch (_) {
        // fall through to new request
      }
    }

    print('[NOMINATIM REQUEST] Starting new request for "$key"');
    
    // Create the request future and store it while running
    final future = _fetchPredictions(key).then((results) {
      // Cache only when we actually got results to avoid poisoning cache with
      // transient empty responses (rate limits, network errors).
      if (results.isNotEmpty) {
        print('[NOMINATIM CACHE] Caching ${results.length} results for "$key" (expires in ${_cacheTtl.inSeconds}s)');
        _cache[key] = _CacheEntry(
          predictions: results,
          expiry: DateTime.now().add(_cacheTtl),
        );
      } else {
        print('[NOMINATIM CACHE] Not caching empty results for "$key"');
      }
      _ongoingRequests.remove(key);
      return results;
    }).catchError((e) {
      print('[NOMINATIM REQUEST] Request failed for "$key": $e');
      _ongoingRequests.remove(key);
      return <PlacePrediction>[];
    });

    _ongoingRequests[key] = future;
    return await future;
  }

  static Future<List<PlacePrediction>> _fetchPredictions(String input) async {
    try {
      // simple rate limiting per query
      await Future.delayed(const Duration(milliseconds: 1));

      final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
        'q': input,
        'format': 'json',
        'limit': '10',
        'addressdetails': '1',
      });

      print('[NOMINATIM] Fetching predictions for "$input"');
      print('[NOMINATIM] Request URI: $uri');
      // Implement a small retry/backoff for transient failures (rate limits,
      // server errors, connection resets). Keep retries small to avoid
      // hammering the public Nominatim service.
      const int maxAttempts = 3;
      int attempt = 0;
      while (true) {
        attempt++;
        try {
          final response = await http
              .get(uri, headers: {
            'User-Agent': 'CarSharing/1.0 (dev@local)',
            'Accept-Language': 'en',
          })
              .timeout(const Duration(seconds: 5));

          print('[NOMINATIM] Response status: ${response.statusCode} (attempt $attempt)');
          print('[NOMINATIM] Response body length: ${response.body.length}');
          if (response.body.length < 1000) {
            print('[NOMINATIM] Response body: ${response.body}');
          } else {
            print('[NOMINATIM] Response (first 500 chars): ${response.body.substring(0, 500)}');
          }

          if (response.statusCode == 200) {
            final List<dynamic> data = json.decode(response.body);
            print('[NOMINATIM] Successfully parsed JSON: ${data.length} results');
            if (data.isNotEmpty) {
              print('[NOMINATIM] First result keys: ${data[0].toString().substring(0, 200)}');
            }
            final predictions = data.map((p) => PlacePrediction.fromJson(p)).toList();
            print('[NOMINATIM] Converted to ${predictions.length} predictions');
            return predictions;
          }

          // Treat common rate-limit/teapot responses and 5xx as transient
          if (response.statusCode == 429 || response.statusCode == 418 || response.statusCode >= 500) {
            if (attempt < maxAttempts) {
              final backoff = Duration(milliseconds: 300 * attempt);
              print('[NOMINATIM] Transient status ${response.statusCode}, retrying after ${backoff.inMilliseconds}ms');
              await Future.delayed(backoff);
              continue;
            } else {
              print('[NOMINATIM] Giving up after $attempt attempts (status ${response.statusCode})');
            }
          } else {
            print('[NOMINATIM] Non-retriable status ${response.statusCode}');
          }
        } on SocketException catch (se) {
          print('[NOMINATIM] SocketException: $se (attempt $attempt)');
          if (attempt < maxAttempts) {
            await Future.delayed(Duration(milliseconds: 300 * attempt));
            continue;
          }
        } on TimeoutException catch (te) {
          print('[NOMINATIM] Timeout: $te (attempt $attempt)');
          if (attempt < maxAttempts) {
            await Future.delayed(Duration(milliseconds: 300 * attempt));
            continue;
          }
        } catch (e) {
          print('[NOMINATIM] EXCEPTION: $e (attempt $attempt)');
          if (attempt < maxAttempts) {
            await Future.delayed(Duration(milliseconds: 300 * attempt));
            continue;
          }
        }

        break;
      }
    } catch (e) {
      print('[NOMINATIM] EXCEPTION: $e');
    }

    return [];
  }

  // Local fallback for common city names to improve UX when Nominatim is
  // unreachable or rate-limiting the client. This provides lightweight
  // suggestions so users can still pick common cities like "Marburg".
  static List<PlacePrediction> _localFallback(String input) {
    final map = <String, String>{
      'marburg': 'Marburg, Hesse, Germany',
      'berlin': 'Berlin, Germany',
      'munich': 'München, Bavaria, Germany',
      'muenchen': 'München, Bavaria, Germany',
      'hamburg': 'Hamburg, Germany',
      'frankfurt': 'Frankfurt am Main, Hesse, Germany',
      'koeln': 'Köln, North Rhine-Westphalia, Germany',
      'cologne': 'Köln, North Rhine-Westphalia, Germany',
      'stuttgart': 'Stuttgart, Baden-Württemberg, Germany',
      'dusseldorf': 'Düsseldorf, North Rhine-Westphalia, Germany',
    };

    final key = input.trim().toLowerCase();
    final results = <PlacePrediction>[];
    if (key.isEmpty) return results;

    map.forEach((k, display) {
      if (k.startsWith(key) || key.startsWith(k)) {
        results.add(PlacePrediction(
          placeId: 'fallback-$k',
          description: display,
          mainText: PlacePrediction._extractMainText(display),
          secondaryText: PlacePrediction._extractSecondaryText(display),
        ));
      }
    });

    if (results.isNotEmpty) {
      print('[NOMINATIM FALLBACK] Returning ${results.length} local fallback results for "$input"');
    }
    return results;
  }

  /// Get place details including coordinates
  static Future<PlaceLocation?> getPlaceDetails(String placeId) async {
    if (placeId.isEmpty) {
      return null;
    }

    try {
      // For Nominatim, we'll do a reverse lookup using coordinates
      // Since placeId from our predictions contains OSM data, we need to re-query
      // This is handled in the address-based approach below
      return null;
    } catch (e) {
      print('Error fetching place details: $e');
    }

    return null;
  }

  /// Geocode an address to get coordinates using Nominatim
  static Future<PlaceLocation?> geocodeAddress(String address) async {
    if (address.isEmpty) {
      return null;
    }

    try {
      final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
        'q': address,
        'format': 'json',
        'limit': '1',
        'addressdetails': '1',
      });

      final response = await http.get(uri, headers: {
        'User-Agent': 'CarSharing/1.0 (dev@local)',
        'Accept-Language': 'en',
      });

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (data.isNotEmpty) {
          final result = data[0];
          return PlaceLocation(
            latitude: double.parse(result['lat'].toString()),
            longitude: double.parse(result['lon'].toString()),
            address: result['display_name'] ?? address,
          );
        }
      }
    } catch (e) {
      print('Error geocoding address: $e');
    }

    return null;
  }

  /// Reverse geocode coordinates to get address using Nominatim
  static Future<String?> reverseGeocode(double latitude, double longitude) async {
    try {
      final uri = Uri.https('nominatim.openstreetmap.org', '/reverse', {
        'format': 'json',
        'lat': latitude.toString(),
        'lon': longitude.toString(),
        'zoom': '18',
        'addressdetails': '1',
      });

      final response = await http.get(uri, headers: {
        'User-Agent': 'CarSharing/1.0 (dev@local)',
        'Accept-Language': 'en',
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['display_name'] ?? null;
      }
    } catch (e) {
      print('Error reverse geocoding: $e');
    }

    return null;
  }

  /// Check if API key is configured (not needed for OpenStreetMap/Nominatim)
  static bool get isApiKeyConfigured => true; // Always true for OSM
}

class _CacheEntry {
  final List<PlacePrediction> predictions;
  final DateTime expiry;

  _CacheEntry({required this.predictions, required this.expiry});
}
