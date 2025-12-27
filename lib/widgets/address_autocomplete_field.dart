import 'dart:async';
import 'package:carsharing/services/places_service.dart';
import 'package:flutter/material.dart';
import 'package:carsharing/widgets/map_location_picker.dart';
import 'package:carsharing/services/location_service.dart';

class AddressAutocompleteField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData? prefixIcon;
  final Color? prefixIconColor;
  final Function(String address, double? latitude, double? longitude)? onAddressSelected;
  final String? Function(String?)? validator;

  const AddressAutocompleteField({
    super.key,
    required this.controller,
    required this.label,
    this.hint = 'Enter address...',
    this.prefixIcon,
    this.prefixIconColor,
    this.onAddressSelected,
    this.validator,
  });

  @override
  State<AddressAutocompleteField> createState() => _AddressAutocompleteFieldState();
}

class _AddressAutocompleteFieldState extends State<AddressAutocompleteField> {
  List<PlacePrediction> _predictions = [];
  bool _isLoading = false;
  bool _showSuggestions = false;
  final FocusNode _focusNode = FocusNode();
  bool _addressSelectedFromPredictions = false; // Track if address was selected from predictions
  Timer? _debounce;
  bool _noResults = false;

  @override
  void initState() {
    super.initState();
    print('[INIT] AddressAutocompleteField initState');
    _focusNode.addListener(() {
      print('[FOCUS] Focus changed: hasFocus=${_focusNode.hasFocus}');
      if (!_focusNode.hasFocus) {
        _hideSuggestions();
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _focusNode.dispose();
    _hideSuggestions();
    super.dispose();
  }
  Future<void> _onTextChanged(String value) async {
    // Clear the "selected from predictions" flag when user types
    setState(() {
      _addressSelectedFromPredictions = false;
    });

    print('[AUTOCOMPLETE] Text changed: "$value" (length: ${value.length})');

    // trigger suggestions earlier for shorter names (2+ chars)
    if (value.length < 2) {
      _debounce?.cancel();
      setState(() {
        _predictions = [];
        _showSuggestions = false;
        _isLoading = false;
        _noResults = false;
      });
      _hideSuggestions();
      print('[AUTOCOMPLETE] Text too short, cleared suggestions');
      return;
    }

    // Debounce rapid input
    _debounce?.cancel();
    print('[AUTOCOMPLETE] Starting debounce timer for "$value"');
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      print('[AUTOCOMPLETE] Debounce timer fired, fetching predictions for "$value"');
      if (!mounted) {
        print('[AUTOCOMPLETE] Widget unmounted, skipping');
        return;
      }
      setState(() {
        _isLoading = true;
        _noResults = false;
      });

      try {
        print('[AUTOCOMPLETE] Calling PlacesService.getPlacePredictions("$value")');
        final predictions = await PlacesService.getPlacePredictions(value);
        print('[AUTOCOMPLETE] Got ${predictions.length} predictions');
        if (!mounted) {
          print('[AUTOCOMPLETE] Widget unmounted after API call, skipping setState');
          return;
        }
        setState(() {
          _predictions = predictions;
          _isLoading = false;
          _showSuggestions = predictions.isNotEmpty;
          _noResults = predictions.isEmpty;
        });
        print('[AUTOCOMPLETE] State updated, showSuggestions=$_showSuggestions, noResults=$_noResults');
        if (_showSuggestions) {
          _showSuggestionsOverlay();
        }
      } catch (e) {
        print('[AUTOCOMPLETE] ERROR fetching predictions: $e');
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _predictions = [];
          _noResults = true;
        });
      }
    });
  }

  Future<void> _onPredictionSelected(PlacePrediction prediction) async {
    widget.controller.text = prediction.description;
    _hideSuggestions();

    // Mark that address was selected from predictions
    setState(() {
      _addressSelectedFromPredictions = true;
    });

    // Get coordinates for the selected address
    final location = await PlacesService.geocodeAddress(prediction.description);

    if (location != null && widget.onAddressSelected != null) {
      widget.onAddressSelected!(
        location.address,
        location.latitude,
        location.longitude,
      );
    } else if (widget.onAddressSelected != null) {
      widget.onAddressSelected!(prediction.description, null, null);
    }
  }

  void _showSuggestionsOverlay() {
    print('[OVERLAY] _showSuggestionsOverlay called, showSuggestions=$_showSuggestions, predictions=${_predictions.length}');
    
    if (!_showSuggestions || _predictions.isEmpty) {
      print('[OVERLAY] Skipping overlay (showSuggestions=$_showSuggestions, count=${_predictions.length})');
      return;
    }

    print('[OVERLAY] Triggering rebuild to show suggestions');
    setState(() {
      _showSuggestions = true;
    });
  }

  void _hideSuggestions() {
    print('[OVERLAY] _hideSuggestions called');
    setState(() {
      _showSuggestions = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    print('[BUILD] AddressAutocompleteField.build() called');
    print('[BUILD] Current state: predictions=${_predictions.length}, showSuggestions=$_showSuggestions, isLoading=$_isLoading');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: widget.controller,
          focusNode: _focusNode,
          decoration: InputDecoration(
            labelText: widget.label,
            hintText: widget.hint,
            border: const OutlineInputBorder(),
            prefixIcon: widget.prefixIcon != null
                ? Icon(widget.prefixIcon, color: widget.prefixIconColor)
                : null,
            suffixIcon: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: Padding(
                      padding: EdgeInsets.all(12.0),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : LayoutBuilder(
                    builder: (context, constraints) {
                      final screenWidth = MediaQuery.of(context).size.width;
                      final maxWidth = (screenWidth * 0.35).clamp(56.0, 120.0);
                      return SizedBox(
                        width: maxWidth,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (widget.controller.text.isNotEmpty)
                              IconButton(
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                visualDensity: VisualDensity.compact,
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  widget.controller.clear();
                                  _hideSuggestions();
                                  setState(() {
                                    _predictions = [];
                                    _addressSelectedFromPredictions = false;
                                  });
                                },
                              ),
                            IconButton(
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                              visualDensity: VisualDensity.compact,
                              icon: const Icon(Icons.map, size: 18),
                              tooltip: 'Pick on map',
                              onPressed: _openMapPicker,
                            ),
                            IconButton(
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                              visualDensity: VisualDensity.compact,
                              icon: const Icon(Icons.my_location, size: 18),
                              tooltip: 'Use current location',
                              onPressed: () async {
                                final pos = await LocationService.getCurrentLocation();
                                if (pos != null) {
                                  final lat = pos.latitude;
                                  final lon = pos.longitude;
                                  final addr = await PlacesService.reverseGeocode(lat, lon);
                                  widget.controller.text = addr ?? '${lat.toStringAsFixed(6)}, ${lon.toStringAsFixed(6)}';
                                  setState(() {
                                    _addressSelectedFromPredictions = true;
                                  });
                                  if (widget.onAddressSelected != null) {
                                    widget.onAddressSelected!(addr ?? widget.controller.text, lat, lon);
                                  }
                                  _hideSuggestions();
                                } else {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Could not get current location')),
                                    );
                                  }
                                }
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter an address';
            }
            if (!_addressSelectedFromPredictions) {
              return 'Please select an address from the list or use the map/location buttons';
            }
            return widget.validator?.call(value);
          },
          onChanged: _onTextChanged,
          onTap: () {
            print('[ONTAP] TextField tapped, predictions=${_predictions.length}, showSuggestions=$_showSuggestions');
            if (_predictions.isNotEmpty) {
              print('[ONTAP] Showing overlay from onTap');
              _showSuggestionsOverlay();
            }
          },
        ),
        // Suggestions dropdown - displayed directly below the input field
        if (_showSuggestions && _predictions.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.5),
                  spreadRadius: 2,
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            constraints: const BoxConstraints(maxHeight: 300),
            child: ListView.builder(
              shrinkWrap: true,
              physics: const BouncingScrollPhysics(),
              itemCount: _predictions.length,
              itemBuilder: (context, index) {
                final prediction = _predictions[index];
                print('[SUGGESTION-TILE] Building tile $index for: ${prediction.mainText}');
                return ListTile(
                  leading: const Icon(Icons.location_on, color: Colors.blue),
                  title: Text(
                    prediction.mainText,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: prediction.secondaryText.isNotEmpty ? Text(prediction.secondaryText) : null,
                  dense: true,
                  tileColor: index.isEven ? Colors.grey.shade100 : Colors.white,
                  onTap: () {
                    print('[SUGGESTION-TAP] Selected: ${prediction.mainText}');
                    _onPredictionSelected(prediction);
                  },
                );
              },
            ),
          )
        else if (!_isLoading && _noResults)
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                const Icon(Icons.search_off, color: Colors.grey),
                const SizedBox(width: 12),
                Expanded(child: const Text('No matching address', style: TextStyle(color: Colors.grey))),
              ],
            ),
          ),
      ],
    );
  }

  Future<void> _openMapPicker() async {
    await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => MapLocationPicker(
          initialLat: null,
          initialLon: null,
          onLocationSelected: (latitude, longitude, address) {
            widget.controller.text = address;
            setState(() {
              _addressSelectedFromPredictions = true;
            });
            if (widget.onAddressSelected != null) {
              widget.onAddressSelected!(address, latitude, longitude);
            }
          },
        ),
      ),
    );
  }
}
