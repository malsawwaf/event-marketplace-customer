import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../services/address_service.dart';
import '../../config/supabase_config.dart';
import '../../config/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/map_location_picker.dart';

class AddEditAddressScreen extends StatefulWidget {
  final Map<String, dynamic>? address;

  const AddEditAddressScreen({Key? key, this.address}) : super(key: key);

  @override
  State<AddEditAddressScreen> createState() => _AddEditAddressScreenState();
}

class _AddEditAddressScreenState extends State<AddEditAddressScreen> {
  final _formKey = GlobalKey<FormState>();
  final AddressService _addressService = AddressService();

  final _labelController = TextEditingController();
  final _cityController = TextEditingController();
  final _districtController = TextEditingController();
  final _addressTextController = TextEditingController();
  final _addressDetailsController = TextEditingController();
  final _countryController = TextEditingController();

  bool _isDefault = false;
  bool _isSaving = false;
  bool _hasSelectedLocation = false;
  double? _latitude;
  double? _longitude;

  @override
  void initState() {
    super.initState();
    if (widget.address != null) {
      _loadAddress();
    } else {
      // For new address, open map picker immediately
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _openMapPicker();
      });
    }
  }

  void _loadAddress() {
    final address = widget.address!;
    _labelController.text = address['label'] ?? '';
    _cityController.text = address['city'] ?? '';
    _districtController.text = address['district'] ?? '';
    _addressTextController.text = address['address_text'] ?? '';
    _addressDetailsController.text = address['address_details'] ?? '';
    _countryController.text = address['country'] ?? 'Saudi Arabia';
    _isDefault = address['is_default'] == true;
    _hasSelectedLocation = true;

    // Parse location from database format
    final location = address['location'];
    if (location != null) {
      final parsed = _addressService.parseLocation(location);
      if (parsed != null) {
        _latitude = parsed['latitude'];
        _longitude = parsed['longitude'];
      }
    }
    // Fallback to direct lat/lng fields if available
    _latitude ??= address['latitude'];
    _longitude ??= address['longitude'];
  }

  @override
  void dispose() {
    _labelController.dispose();
    _cityController.dispose();
    _districtController.dispose();
    _addressTextController.dispose();
    _addressDetailsController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  Future<void> _openMapPicker() async {
    final result = await Navigator.push<dynamic>(
      context,
      MaterialPageRoute(
        builder: (context) => MapLocationPicker(
          initialLatitude: _latitude,
          initialLongitude: _longitude,
          returnAddressInfo: true,
        ),
      ),
    );

    if (result != null && result is LocationPickerResult) {
      setState(() {
        _latitude = result.location.latitude;
        _longitude = result.location.longitude;
        _hasSelectedLocation = true;

        // Auto-fill fields from geocoding result
        if (result.city != null && result.city!.isNotEmpty) {
          _cityController.text = result.city!;
        }
        if (result.address != null && result.address!.isNotEmpty) {
          _addressTextController.text = result.address!;
        }
        if (result.district != null && result.district!.isNotEmpty) {
          _districtController.text = result.district!;
        }
        if (result.country != null && result.country!.isNotEmpty) {
          _countryController.text = result.country!;
        } else {
          _countryController.text = 'Saudi Arabia';
        }
      });
    } else if (result != null && result is LatLng) {
      // Fallback for legacy LatLng result
      setState(() {
        _latitude = result.latitude;
        _longitude = result.longitude;
        _hasSelectedLocation = true;
      });
    } else if (!_hasSelectedLocation && widget.address == null) {
      // User cancelled without selecting - go back
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  Future<void> _saveAddress() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_hasSelectedLocation || _latitude == null || _longitude == null) {
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${l10n.pleaseSelectAddress}'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      // Combine address text and details
      final fullAddress = [
        _addressTextController.text.trim(),
        _addressDetailsController.text.trim(),
      ].where((s) => s.isNotEmpty).join(', ');

      if (widget.address == null) {
        // Add new address
        await _addressService.addAddress(
          customerId: userId,
          label: _labelController.text.trim().isEmpty
              ? 'Home'
              : _labelController.text.trim(),
          city: _cityController.text.trim(),
          district: _districtController.text.trim(),
          latitude: _latitude!,
          longitude: _longitude!,
          addressDetails: fullAddress,
          isDefault: _isDefault,
        );
      } else {
        // Update existing address
        await _addressService.updateAddress(
          addressId: widget.address!['id'],
          customerId: userId,
          label: _labelController.text.trim().isEmpty
              ? 'Home'
              : _labelController.text.trim(),
          city: _cityController.text.trim(),
          district: _districtController.text.trim(),
          latitude: _latitude!,
          longitude: _longitude!,
          addressDetails: fullAddress,
          isDefault: _isDefault,
        );
      }

      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.addressSavedSuccessfully),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.error}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isEditing = widget.address != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? l10n.editAddress : l10n.addAddress),
        backgroundColor: AppTheme.primaryNavy,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Location Picker (at the top, showing selected location)
              InkWell(
                onTap: _openMapPicker,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  height: 120,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _hasSelectedLocation
                          ? AppTheme.primaryNavy
                          : Colors.grey[300]!,
                      width: _hasSelectedLocation ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    color: _hasSelectedLocation
                        ? AppTheme.primaryNavy.withOpacity(0.05)
                        : Colors.grey[100],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 80,
                        decoration: BoxDecoration(
                          color: _hasSelectedLocation
                              ? AppTheme.primaryNavy.withOpacity(0.1)
                              : Colors.grey[200],
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(11),
                            bottomLeft: Radius.circular(11),
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            _hasSelectedLocation ? Icons.location_on : Icons.map,
                            size: 40,
                            color: _hasSelectedLocation
                                ? AppTheme.primaryNavy
                                : Colors.grey[400],
                          ),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _hasSelectedLocation
                                    ? 'Location Selected'
                                    : 'Tap to select location',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: _hasSelectedLocation
                                      ? AppTheme.primaryNavy
                                      : Colors.grey[600],
                                ),
                              ),
                              if (_hasSelectedLocation && _latitude != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  '${_latitude!.toStringAsFixed(4)}, ${_longitude!.toStringAsFixed(4)}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                              const SizedBox(height: 4),
                              Text(
                                'Tap to change location',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.secondaryCoral,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Icon(
                          Icons.chevron_right,
                          color: Colors.grey[400],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Label (Home, Work, Other)
              Text(
                l10n.addressLabel,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildLabelChip('Home', l10n.addressTypeHome),
                  const SizedBox(width: 8),
                  _buildLabelChip('Work', l10n.addressTypeWork),
                  const SizedBox(width: 8),
                  _buildLabelChip('Other', l10n.addressTypeOther),
                ],
              ),
              const SizedBox(height: 24),

              // City (auto-filled from map)
              TextFormField(
                controller: _cityController,
                decoration: InputDecoration(
                  labelText: l10n.city,
                  prefixIcon: const Icon(Icons.location_city),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return l10n.pleaseEnterCity;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // District (auto-filled from map)
              TextFormField(
                controller: _districtController,
                decoration: InputDecoration(
                  labelText: l10n.district,
                  prefixIcon: const Icon(Icons.map_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
              ),
              const SizedBox(height: 16),

              // Address Text (auto-filled from map)
              TextFormField(
                controller: _addressTextController,
                decoration: InputDecoration(
                  labelText: l10n.address,
                  prefixIcon: const Icon(Icons.home_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
              ),
              const SizedBox(height: 16),

              // Country (auto-filled from map)
              TextFormField(
                controller: _countryController,
                decoration: InputDecoration(
                  labelText: 'Country',
                  prefixIcon: const Icon(Icons.public),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
              ),
              const SizedBox(height: 16),

              // Address Details (user input - building, floor, etc.)
              TextFormField(
                controller: _addressDetailsController,
                decoration: InputDecoration(
                  labelText: 'Address Details (Building, Floor, etc.)',
                  prefixIcon: const Icon(Icons.apartment),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  hintText: 'e.g., Building 5, Floor 3, Apartment 12',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),

              // Set as Default
              CheckboxListTile(
                value: _isDefault,
                onChanged: (value) {
                  setState(() => _isDefault = value ?? false);
                },
                title: Text(l10n.setAsDefault),
                subtitle: const Text('This will be selected automatically'),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 32),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveAddress,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryNavy,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          isEditing ? l10n.editAddress : l10n.saveAddress,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabelChip(String key, String displayLabel) {
    final isSelected = _labelController.text == key;
    return ChoiceChip(
      label: Text(displayLabel),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _labelController.text = key;
          });
        }
      },
      selectedColor: AppTheme.primaryNavy,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black,
      ),
    );
  }
}