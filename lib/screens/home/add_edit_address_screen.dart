import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/address_service.dart';

class AddEditAddressScreen extends StatefulWidget {
  final Map<String, dynamic>? existingAddress;

  const AddEditAddressScreen({
    Key? key,
    this.existingAddress,
  }) : super(key: key);

  @override
  State<AddEditAddressScreen> createState() => _AddEditAddressScreenState();
}

class _AddEditAddressScreenState extends State<AddEditAddressScreen> {
  final _supabase = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _labelController;
  late TextEditingController _cityController;
  late TextEditingController _districtController;
  late TextEditingController _detailsController;

  bool _isDefault = false;
  bool _isSaving = false;

  // For simplicity, using Jeddah coordinates by default
  // In production, integrate Google Maps or similar for location picking
  double _latitude = 21.5433; // Jeddah default
  double _longitude = 39.1728;

  @override
  void initState() {
    super.initState();

    final address = widget.existingAddress;
    _labelController = TextEditingController(text: address?['label'] ?? '');
    _cityController = TextEditingController(text: address?['city'] ?? 'Jeddah');
    _districtController = TextEditingController(text: address?['district'] ?? '');
    _detailsController = TextEditingController(text: address?['address_details'] ?? '');
    _isDefault = address?['is_default'] ?? false;

    // Parse existing location if available
    if (address != null && address['location'] != null) {
      final addressService = AddressService();
      final location = addressService.parseLocation(address['location']);
      if (location != null) {
        _latitude = location['latitude']!;
        _longitude = location['longitude']!;
      }
    }
  }

  @override
  void dispose() {
    _labelController.dispose();
    _cityController.dispose();
    _districtController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  Future<void> _saveAddress() async {
    if (!_formKey.currentState!.validate()) return;

    final customerId = _supabase.auth.currentUser?.id;
    if (customerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to save address')),
      );
      return;
    }

    setState(() => _isSaving = true);

    final addressService = AddressService();

    try {
      if (widget.existingAddress != null) {
        // Update existing address
        await addressService.updateAddress(
          addressId: widget.existingAddress!['id'] as String,
          customerId: customerId,
          label: _labelController.text.trim(),
          city: _cityController.text.trim(),
          district: _districtController.text.trim(),
          latitude: _latitude,
          longitude: _longitude,
          addressDetails: _detailsController.text.trim().isEmpty
              ? null
              : _detailsController.text.trim(),
          isDefault: _isDefault,
        );
      } else {
        // Add new address
        await addressService.addAddress(
          customerId: customerId,
          label: _labelController.text.trim(),
          city: _cityController.text.trim(),
          district: _districtController.text.trim(),
          latitude: _latitude,
          longitude: _longitude,
          addressDetails: _detailsController.text.trim().isEmpty
              ? null
              : _detailsController.text.trim(),
          isDefault: _isDefault,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.existingAddress != null
                  ? 'Address updated successfully'
                  : 'Address added successfully',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingAddress != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Address' : 'Add New Address'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Label
            TextFormField(
              controller: _labelController,
              decoration: const InputDecoration(
                labelText: 'Address Label',
                hintText: 'e.g., Home, Office, Villa',
                prefixIcon: Icon(Icons.label),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter address label';
                }
                if (value.trim().length < 3) {
                  return 'Label must be at least 3 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // City
            TextFormField(
              controller: _cityController,
              decoration: const InputDecoration(
                labelText: 'City',
                prefixIcon: Icon(Icons.location_city),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter city';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // District
            TextFormField(
              controller: _districtController,
              decoration: const InputDecoration(
                labelText: 'District',
                prefixIcon: Icon(Icons.map),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter district';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Address Details
            TextFormField(
              controller: _detailsController,
              decoration: const InputDecoration(
                labelText: 'Address Details (Optional)',
                hintText: 'Building, Street, Floor, etc.',
                prefixIcon: Icon(Icons.home),
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),

            // Location Picker Placeholder
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.location_on, color: Colors.blue),
                        const SizedBox(width: 8),
                        const Text(
                          'Location',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Lat: ${_latitude.toStringAsFixed(6)}, Lng: ${_longitude.toStringAsFixed(6)}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () {
                        // TODO: Integrate Google Maps location picker
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Map picker coming soon! Using Jeddah default location.'),
                          ),
                        );
                      },
                      icon: const Icon(Icons.map),
                      label: const Text('Pick Location on Map'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Set as Default
            SwitchListTile(
              title: const Text('Set as default address'),
              subtitle: const Text('Use this address for all orders'),
              value: _isDefault,
              onChanged: (value) => setState(() => _isDefault = value),
              secondary: const Icon(Icons.bookmark),
            ),
            const SizedBox(height: 24),

            // Save Button
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveAddress,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        isEditing ? 'Update Address' : 'Save Address',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
