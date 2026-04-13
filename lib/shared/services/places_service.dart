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
  // Simple in-memory cache to avoid repeated Nominatim requests
  static final Map<String, _CacheEntry> _cache = {};

  // Track ongoing requests per query to coalesce concurrent calls
  static final Map<String, Future<List<PlacePrediction>>> _ongoingRequests = {};

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
      return cached.predictions;
    }

    // If we have a stale cache entry (expired), return it immediately to
    // improve UX when the network is flaky, and refresh in background.
    if (cached != null) {
      // Fire-and-forget refresh
      _fetchPredictions(key).then((results) {
        if (results.isNotEmpty) {
          _cache[key] = _CacheEntry(predictions: results, expiry: DateTime.now().add(_cacheTtl));
        } else {
        }
      }).catchError((e) {
      });

      return cached.predictions;
    }

    // If a request for this key is already ongoing, return its Future (coalesce)
    if (_ongoingRequests.containsKey(key)) {
      try {
        return await _ongoingRequests[key]!;
      } catch (_) {
        // fall through to new request
      }
    }

    
    // Create the request future and store it while running
    final future = _fetchPredictions(key).then((results) {
      // Cache and return results, or fallback to local suggestions
      if (results.isNotEmpty) {
        _cache[key] = _CacheEntry(
          predictions: results,
          expiry: DateTime.now().add(_cacheTtl),
        );
        _ongoingRequests.remove(key);
        return results;
      } else {
        // Try local fallback when Nominatim returns no results
        final fallbackResults = _localFallback(input);
        if (fallbackResults.isNotEmpty) {
          _cache[key] = _CacheEntry(
            predictions: fallbackResults,
            expiry: DateTime.now().add(_cacheTtl),
          );
        }
        _ongoingRequests.remove(key);
        return fallbackResults;
      }
    }).catchError((e) {
      // On any error, try local fallback
      final fallbackResults = _localFallback(input);
      if (fallbackResults.isNotEmpty) {
        _cache[key] = _CacheEntry(
          predictions: fallbackResults,
          expiry: DateTime.now().add(_cacheTtl),
        );
      }
      _ongoingRequests.remove(key);
      return fallbackResults;
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
      'countrycodes': 'de', // Restrict to Germany
      });

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

          if (response.body.length < 1000) {
          } else {
          }

          if (response.statusCode == 200) {
            final List<dynamic> data = json.decode(response.body);
            if (data.isNotEmpty) {
            }
            final predictions = data.map((p) => PlacePrediction.fromJson(p)).toList();
            return predictions;
          }

          // Treat common rate-limit/teapot responses and 5xx as transient
          if (response.statusCode == 429 || response.statusCode == 418 || response.statusCode >= 500) {
            if (attempt < maxAttempts) {
              final backoff = Duration(milliseconds: 300 * attempt);
              await Future.delayed(backoff);
              continue;
            } else {
            }
          } else {
          }
        } on SocketException {
          if (attempt < maxAttempts) {
            await Future.delayed(Duration(milliseconds: 300 * attempt));
            continue;
          }
        } on TimeoutException {
          if (attempt < maxAttempts) {
            await Future.delayed(Duration(milliseconds: 300 * attempt));
            continue;
          }
        } catch (e) {
          if (attempt < maxAttempts) {
            await Future.delayed(Duration(milliseconds: 300 * attempt));
            continue;
          }
        }

        break;
      }
    } catch (e) {
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
      'countrycodes': 'de', // Restrict to Germany
      });

      final response = await http.get(uri, headers: {
        'User-Agent': 'CarSharing/1.0 (dev@local)',
        'Accept-Language': 'en',
      }).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (data.isNotEmpty) {
          final result = data[0];
          final location = PlaceLocation(
            latitude: double.parse(result['lat'].toString()),
            longitude: double.parse(result['lon'].toString()),
            address: result['display_name'] ?? address,
          );
          return location;
        } else {
        }
      } else {
      }
    } catch (e) {
    }

    // Fallback: try to geocode local city names
    final fallbackLocation = _geocodeLocalCities(address);
    if (fallbackLocation != null) {
      return fallbackLocation;
    }

    return null;
  }

  /// Fallback geocoding for common German cities
  static PlaceLocation? _geocodeLocalCities(String address) {
    final lower = address.toLowerCase();
    
    final cityCoordinates = {
      'marburg': PlaceLocation(latitude: 50.8065, longitude: 8.7705, address: 'Marburg, Hesse, Germany'),
      'berlin': PlaceLocation(latitude: 52.5200, longitude: 13.4050, address: 'Berlin, Germany'),
      'munich': PlaceLocation(latitude: 48.1351, longitude: 11.5820, address: 'Munich, Bavaria, Germany'),
      'muenchen': PlaceLocation(latitude: 48.1351, longitude: 11.5820, address: 'Munich, Bavaria, Germany'),
      'münchen': PlaceLocation(latitude: 48.1351, longitude: 11.5820, address: 'Munich, Bavaria, Germany'),
      'hamburg': PlaceLocation(latitude: 53.5511, longitude: 9.9937, address: 'Hamburg, Germany'),
      'frankfurt': PlaceLocation(latitude: 50.1109, longitude: 8.6821, address: 'Frankfurt am Main, Hesse, Germany'),
      'cologne': PlaceLocation(latitude: 50.9375, longitude: 6.9603, address: 'Cologne, North Rhine-Westphalia, Germany'),
      'koeln': PlaceLocation(latitude: 50.9375, longitude: 6.9603, address: 'Cologne, North Rhine-Westphalia, Germany'),
      'köln': PlaceLocation(latitude: 50.9375, longitude: 6.9603, address: 'Cologne, North Rhine-Westphalia, Germany'),
      'stuttgart': PlaceLocation(latitude: 48.7758, longitude: 9.1829, address: 'Stuttgart, Baden-Württemberg, Germany'),
      'dusseldorf': PlaceLocation(latitude: 51.2277, longitude: 6.7735, address: 'Düsseldorf, North Rhine-Westphalia, Germany'),
      'düsseldorf': PlaceLocation(latitude: 51.2277, longitude: 6.7735, address: 'Düsseldorf, North Rhine-Westphalia, Germany'),
    };
    
    // Check for exact city name match
    for (final entry in cityCoordinates.entries) {
      if (lower.contains(entry.key)) {
        return entry.value;
      }
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
