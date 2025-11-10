import 'package:flutter/material.dart';
import '../../services/address_service.dart';
import '../../config/supabase_config.dart';

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.address == null
                  ? 'Address added successfully'
                  : 'Address updated successfully',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving address: $e'),
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
    final isEditing = widget.address != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Address' : 'Add Address'),
        backgroundColor: Colors.blue[700],
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
                'Address Label',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildLabelChip('Home'),
                  const SizedBox(width: 8),
                  _buildLabelChip('Work'),
                  const SizedBox(width: 8),
                  _buildLabelChip('Other'),
                ],
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _labelController,
                decoration: InputDecoration(
                  labelText: 'Custom Label (optional)',
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
                  labelText: 'City',
                  prefixIcon: const Icon(Icons.location_city),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
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
                decoration: InputDecoration(
                  labelText: 'District',
                  prefixIcon: const Icon(Icons.map_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter district';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Full Address
              TextFormField(
                controller: _fullAddressController,
                decoration: InputDecoration(
                  labelText: 'Full Address',
                  prefixIcon: const Icon(Icons.home_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  hintText: 'Building, Street, etc.',
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter full address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Location Picker (Placeholder)
              Container(
                height: 150,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey[100],
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.map,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Map Location Picker',
                        style: TextStyle(
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '(Coming Soon)',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
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
                title: const Text('Set as default address'),
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
                    backgroundColor: Colors.blue[700],
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
                          isEditing ? 'Update Address' : 'Save Address',
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

  Widget _buildLabelChip(String label) {
    final isSelected = _labelController.text == label;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _labelController.text = label;
          });
        }
      },
      selectedColor: Colors.blue[700],
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black,
      ),
    );
  }
}