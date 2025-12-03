import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:async';
import '../services/location_service.dart';
import '../config/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../utils/cities.dart';

/// Result from MapLocationPicker containing location and address info
class LocationPickerResult {
  final LatLng location;
  final String? city;
  final String? address;
  final String? country;
  final String? district;

  LocationPickerResult({
    required this.location,
    this.city,
    this.address,
    this.country,
    this.district,
  });
}

class MapLocationPicker extends StatefulWidget {
  final double? initialLatitude;
  final double? initialLongitude;
  final bool returnAddressInfo; // If true, returns LocationPickerResult instead of LatLng

  const MapLocationPicker({
    Key? key,
    this.initialLatitude,
    this.initialLongitude,
    this.returnAddressInfo = false,
  }) : super(key: key);

  @override
  State<MapLocationPicker> createState() => _MapLocationPickerState();
}

class _MapLocationPickerState extends State<MapLocationPicker> {
  GoogleMapController? _mapController;
  LatLng? _selectedLocation;
  bool _isLoading = false;
  bool _isGeocodingLoading = false;
  final LocationService _locationService = LocationService();

  // Current address info from reverse geocoding
  String? _currentCity;
  String? _currentAddress;
  String? _currentCountry;
  String? _currentDistrict;

  // For city selection when location fails
  bool _locationFailed = false;
  bool _showCitySelector = false;

  // Search functionality
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;
  bool _showSearchResults = false;
  Timer? _debounce;

  // Default to Riyadh center if no initial location
  static const LatLng _defaultLocation = LatLng(24.7136, 46.6753);

  @override
  void initState() {
    super.initState();
    // Set initial location from widget parameters or try current location
    if (widget.initialLatitude != null && widget.initialLongitude != null) {
      _selectedLocation = LatLng(widget.initialLatitude!, widget.initialLongitude!);
      if (widget.returnAddressInfo) {
        _reverseGeocode(_selectedLocation!);
      }
    } else {
      _selectedLocation = _defaultLocation;
      // Try to get current location
      _getCurrentLocation();
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  /// Search for addresses using geocoding
  Future<void> _searchAddress(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _showSearchResults = false;
      });
      return;
    }

    setState(() => _isSearching = true);

    try {
      // Append "Saudi Arabia" to improve search results for local addresses
      final searchQuery = query.contains('Saudi') ? query : '$query, Saudi Arabia';
      final locations = await locationFromAddress(searchQuery);

      if (locations.isNotEmpty && mounted) {
        // Get address details for each result
        final List<Map<String, dynamic>> results = [];
        for (final location in locations.take(5)) {
          try {
            final placemarks = await placemarkFromCoordinates(
              location.latitude,
              location.longitude,
            );
            if (placemarks.isNotEmpty) {
              final placemark = placemarks.first;
              results.add({
                'location': LatLng(location.latitude, location.longitude),
                'address': _buildAddressString(placemark),
                'city': placemark.locality ?? placemark.subAdministrativeArea,
                'country': placemark.country,
              });
            }
          } catch (e) {
            // If reverse geocoding fails, still add the location
            results.add({
              'location': LatLng(location.latitude, location.longitude),
              'address': query,
              'city': null,
              'country': 'Saudi Arabia',
            });
          }
        }

        if (mounted) {
          setState(() {
            _searchResults = results;
            _showSearchResults = true;
          });
        }
      }
    } catch (e) {
      print('Error searching address: $e');
      if (mounted) {
        setState(() {
          _searchResults = [];
          _showSearchResults = false;
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isSearching = false);
      }
    }
  }

  /// Handle search text change with debounce
  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _searchAddress(query);
    });
  }

  /// Select a search result and move the map
  void _selectSearchResult(Map<String, dynamic> result) {
    final location = result['location'] as LatLng;
    setState(() {
      _selectedLocation = location;
      _currentAddress = result['address'];
      _currentCity = result['city'];
      _currentCountry = result['country'];
      _showSearchResults = false;
      _searchController.clear();
    });

    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(location, 17),
    );

    // Reverse geocode to get full details
    _reverseGeocode(location);
  }

  Future<void> _reverseGeocode(LatLng location) async {
    if (!widget.returnAddressInfo) return;

    setState(() => _isGeocodingLoading = true);

    try {
      final placemarks = await placemarkFromCoordinates(
        location.latitude,
        location.longitude,
      );

      if (placemarks.isNotEmpty && mounted) {
        final placemark = placemarks.first;
        setState(() {
          _currentCity = placemark.locality ?? placemark.subAdministrativeArea;
          _currentDistrict = placemark.subLocality ?? placemark.administrativeArea;
          _currentCountry = placemark.country;
          _currentAddress = _buildAddressString(placemark);
        });
      }
    } catch (e) {
      print('Error reverse geocoding: $e');
    } finally {
      if (mounted) {
        setState(() => _isGeocodingLoading = false);
      }
    }
  }

  String _buildAddressString(Placemark placemark) {
    final parts = <String>[];
    if (placemark.street != null && placemark.street!.isNotEmpty) {
      parts.add(placemark.street!);
    }
    if (placemark.subLocality != null && placemark.subLocality!.isNotEmpty) {
      parts.add(placemark.subLocality!);
    }
    if (placemark.locality != null && placemark.locality!.isNotEmpty) {
      parts.add(placemark.locality!);
    }
    return parts.join(', ');
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoading = true);

    try {
      final position = await _locationService.getCurrentPosition().timeout(
        const Duration(seconds: 15),
        onTimeout: () => null,
      );
      if (position != null && mounted) {
        final newLocation = LatLng(position.latitude, position.longitude);
        setState(() {
          _selectedLocation = newLocation;
          _locationFailed = false;
          _showCitySelector = false;
        });

        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(newLocation, 17),
        );

        // Reverse geocode the new location
        _reverseGeocode(newLocation);
      } else if (mounted) {
        // Location failed - show city selector
        setState(() {
          _locationFailed = true;
          _showCitySelector = true;
        });
      }
    } catch (e) {
      print('Error getting location: $e');
      if (mounted) {
        // Location failed - show city selector
        setState(() {
          _locationFailed = true;
          _showCitySelector = true;
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _onCitySelected(String cityName) {
    final cityCoords = SaudiCities.getCityCoordinates(cityName);
    if (cityCoords != null) {
      final newLocation = LatLng(cityCoords['lat']!, cityCoords['lng']!);
      setState(() {
        _selectedLocation = newLocation;
        _currentCity = cityName;
        _currentCountry = 'Saudi Arabia';
        _showCitySelector = false;
        _locationFailed = false;
      });

      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(newLocation, 14),
      );

      // Reverse geocode for more details
      _reverseGeocode(newLocation);
    }
  }

  void _onCameraMove(CameraPosition position) {
    setState(() {
      _selectedLocation = position.target;
    });
  }

  void _onCameraIdle() {
    // Reverse geocode when camera stops moving
    if (_selectedLocation != null && widget.returnAddressInfo) {
      _reverseGeocode(_selectedLocation!);
    }
  }

  void _confirmLocation() {
    if (_selectedLocation != null) {
      if (widget.returnAddressInfo) {
        Navigator.pop(
          context,
          LocationPickerResult(
            location: _selectedLocation!,
            city: _currentCity,
            address: _currentAddress,
            country: _currentCountry,
            district: _currentDistrict,
          ),
        );
      } else {
        Navigator.pop(context, _selectedLocation);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.location),
        backgroundColor: AppTheme.primaryNavy,
        foregroundColor: Colors.white,
        actions: [
          if (_isLoading || _isGeocodingLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              ),
            ),
        ],
      ),
      body: Stack(
        children: [
          // Google Map
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _selectedLocation ?? _defaultLocation,
              zoom: 17,
            ),
            onMapCreated: (controller) {
              _mapController = controller;
            },
            onCameraMove: _onCameraMove,
            onCameraIdle: _onCameraIdle,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
          ),

          // Center pin with shadow effect
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.location_pin,
                  size: 50,
                  color: AppTheme.primaryNavy,
                ),
                // Pin shadow
                Container(
                  width: 10,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ],
            ),
          ),

          // Search bar and address info panel
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Search bar
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    onTap: () {
                      if (_searchResults.isNotEmpty) {
                        setState(() => _showSearchResults = true);
                      }
                    },
                    decoration: InputDecoration(
                      hintText: l10n.searchAddress,
                      hintStyle: TextStyle(color: Colors.grey[500]),
                      prefixIcon: Icon(Icons.search, color: AppTheme.primaryNavy),
                      suffixIcon: _isSearching
                          ? const Padding(
                              padding: EdgeInsets.all(12.0),
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            )
                          : _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {
                                      _searchResults = [];
                                      _showSearchResults = false;
                                    });
                                  },
                                )
                              : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                ),

                // Search results dropdown
                if (_showSearchResults && _searchResults.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    constraints: const BoxConstraints(maxHeight: 200),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        final result = _searchResults[index];
                        return ListTile(
                          leading: Icon(Icons.location_on, color: AppTheme.secondaryCoral),
                          title: Text(
                            result['address'] ?? 'Unknown address',
                            style: const TextStyle(fontSize: 14),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: result['city'] != null
                              ? Text(
                                  [result['city'], result['country']]
                                      .where((e) => e != null)
                                      .join(', '),
                                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                )
                              : null,
                          onTap: () => _selectSearchResult(result),
                        );
                      },
                    ),
                  ),

                // Address info (when not showing search results)
                if (widget.returnAddressInfo && !_showSearchResults)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 5,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.touch_app, color: AppTheme.primaryNavy, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              'Move the map to adjust location',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        if (_isGeocodingLoading)
                          const Padding(
                            padding: EdgeInsets.only(top: 8),
                            child: Center(
                              child: SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                          )
                        else if (_currentAddress != null && _currentAddress!.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            _currentAddress!,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (_currentCity != null || _currentCountry != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                [_currentCity, _currentCountry]
                                    .where((e) => e != null && e.isNotEmpty)
                                    .join(', '),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ),
                        ],
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // Current location button
          Positioned(
            bottom: 100,
            right: 16,
            child: FloatingActionButton(
              onPressed: _isLoading ? null : _getCurrentLocation,
              backgroundColor: Colors.white,
              foregroundColor: AppTheme.primaryNavy,
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.my_location),
            ),
          ),

          // City selector button (shown when location failed or user wants to select manually)
          Positioned(
            bottom: 100,
            left: 16,
            child: FloatingActionButton.extended(
              onPressed: () {
                setState(() {
                  _showCitySelector = !_showCitySelector;
                });
              },
              backgroundColor: _showCitySelector ? AppTheme.secondaryCoral : Colors.white,
              foregroundColor: _showCitySelector ? Colors.white : AppTheme.primaryNavy,
              icon: Icon(_showCitySelector ? Icons.close : Icons.location_city),
              label: Text(_showCitySelector ? l10n.close : l10n.selectCity),
            ),
          ),

          // City selector dropdown overlay
          if (_showCitySelector)
            Positioned(
              top: 160, // Below search bar and address info
              left: 16,
              right: 16,
              bottom: 170,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 15,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(Icons.location_on, color: AppTheme.secondaryCoral),
                          const SizedBox(width: 8),
                          Text(
                            l10n.selectCity,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryNavy,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: ListView.builder(
                        padding: EdgeInsets.zero,
                        itemCount: SaudiCities.getCityNamesEnglish().length,
                        itemBuilder: (context, index) {
                          final city = SaudiCities.getCityNamesEnglish()[index];
                          final isSelected = _currentCity == city;
                          return ListTile(
                            leading: Icon(
                              isSelected ? Icons.check_circle : Icons.location_city,
                              color: isSelected ? AppTheme.secondaryCoral : Colors.grey,
                            ),
                            title: Text(
                              city,
                              style: TextStyle(
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                color: isSelected ? AppTheme.primaryNavy : Colors.black87,
                              ),
                            ),
                            onTap: () => _onCitySelected(city),
                            selected: isSelected,
                            selectedTileColor: AppTheme.primaryNavy.withOpacity(0.05),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Confirm button
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: ElevatedButton(
              onPressed: _confirmLocation,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryNavy,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                l10n.confirm,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
