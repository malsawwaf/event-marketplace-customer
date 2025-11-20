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
  final _fullAddressController = TextEditingController();
  
  bool _isDefault = false;
  bool _isSaving = false;
  double? _latitude;
  double? _longitude;

  @override
  void initState() {
    super.initState();
    if (widget.address != null) {
      _loadAddress();
    }
  }

  void _loadAddress() {
    final address = widget.address!;
    _labelController.text = address['label'] ?? '';
    _cityController.text = address['city'] ?? '';
    _districtController.text = address['district'] ?? '';
    _fullAddressController.text = address['full_address'] ?? '';
    _isDefault = address['is_default'] == true;
    _latitude = address['latitude'];
    _longitude = address['longitude'];
  }

  @override
  void dispose() {
    _labelController.dispose();
    _cityController.dispose();
    _districtController.dispose();
    _fullAddressController.dispose();
    super.dispose();
  }

  Future<void> _openMapPicker() async {
    final result = await Navigator.push<LatLng>(
      context,
      MaterialPageRoute(
        builder: (context) => MapLocationPicker(
          initialLatitude: _latitude,
          initialLongitude: _longitude,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _latitude = result.latitude;
        _longitude = result.longitude;
      });
    }
  }

  Future<void> _saveAddress() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      if (widget.address == null) {
        // Add new address
        await _addressService.addAddress(
          customerId: userId,
          label: _labelController.text.trim(),
          city: _cityController.text.trim(),
          district: _districtController.text.trim(),
          latitude: _latitude ?? 24.7136, // Default to Riyadh
          longitude: _longitude ?? 46.6753,
          addressDetails: _fullAddressController.text.trim(),
          isDefault: _isDefault,
        );
      } else {
        // Update existing address
        await _addressService.updateAddress(
          addressId: widget.address!['id'],
          customerId: userId,
          label: _labelController.text.trim(),
          city: _cityController.text.trim(),
          district: _districtController.text.trim(),
          latitude: _latitude ?? widget.address!['latitude'],
          longitude: _longitude ?? widget.address!['longitude'],
          addressDetails: _fullAddressController.text.trim(),
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
        Navigator.pop(context);
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
              const SizedBox(height: 8),
              TextFormField(
                controller: _labelController,
                decoration: InputDecoration(
                  labelText: '${l10n.addressLabel} (${l10n.optional})',
                  prefixIcon: const Icon(Icons.label_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // City
              TextFormField(
                controller: _cityController,
                decoration: InputDecoration(
                  labelText: l10n.city,
                  prefixIcon: const Icon(Icons.location_city),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return l10n.pleaseEnterCity;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // District
              TextFormField(
                controller: _districtController,
                decoration: InputDecoration(
                  labelText: l10n.state,
                  prefixIcon: const Icon(Icons.map_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return l10n.pleaseEnterCity;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Full Address
              TextFormField(
                controller: _fullAddressController,
                decoration: InputDecoration(
                  labelText: l10n.address,
                  prefixIcon: const Icon(Icons.home_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  hintText: 'Building, Street, etc.',
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return l10n.pleaseEnterCity;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Location Picker
              InkWell(
                onTap: _openMapPicker,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  height: 150,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _latitude != null && _longitude != null
                          ? AppTheme.primaryNavy
                          : Colors.grey[300]!,
                      width: _latitude != null && _longitude != null ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    color: _latitude != null && _longitude != null
                        ? AppTheme.primaryNavy.withOpacity(0.05)
                        : Colors.grey[100],
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _latitude != null && _longitude != null
                              ? Icons.location_on
                              : Icons.map,
                          size: 48,
                          color: _latitude != null && _longitude != null
                              ? AppTheme.primaryNavy
                              : Colors.grey[400],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _latitude != null && _longitude != null
                              ? '${l10n.location} ${l10n.selected}'
                              : '${l10n.select} ${l10n.location}',
                          style: TextStyle(
                            color: _latitude != null && _longitude != null
                                ? AppTheme.primaryNavy
                                : Colors.grey[600],
                            fontWeight: _latitude != null && _longitude != null
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                        if (_latitude != null && _longitude != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            '${_latitude!.toStringAsFixed(4)}, ${_longitude!.toStringAsFixed(4)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
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