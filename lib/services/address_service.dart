import 'package:supabase_flutter/supabase_flutter.dart';

class AddressService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Get all addresses for a customer
  Future<List<Map<String, dynamic>>> getAddresses(String customerId) async {
    try {
      final response = await _supabase
          .from('customer_addresses')
          .select()
          .eq('customer_id', customerId)
          .order('is_default', ascending: false)
          .order('created_at', ascending: false);

      if (response is List) {
        return response.map((item) => Map<String, dynamic>.from(item)).toList();
      }

      return [];
    } catch (e) {
      print('Error fetching addresses: $e');
      rethrow;
    }
  }

  /// Get default address for a customer
  Future<Map<String, dynamic>?> getDefaultAddress(String customerId) async {
    try {
      final response = await _supabase
          .from('customer_addresses')
          .select()
          .eq('customer_id', customerId)
          .eq('is_default', true)
          .maybeSingle();

      return response;
    } catch (e) {
      print('Error fetching default address: $e');
      return null;
    }
  }

  /// Add new address
  Future<Map<String, dynamic>> addAddress({
    required String customerId,
    required String label,
    required String city,
    required String district,
    required double latitude,
    required double longitude,
    String? addressDetails,
    bool isDefault = false,
  }) async {
    try {
      // If setting as default, remove default from other addresses first
      if (isDefault) {
        await _supabase
            .from('customer_addresses')
            .update({'is_default': false})
            .eq('customer_id', customerId);
      }

      final response = await _supabase
          .from('customer_addresses')
          .insert({
            'customer_id': customerId,
            'label': label,
            'city': city,
            'district': district,
            'address_details': addressDetails,
            'location': 'POINT($longitude $latitude)',
            'is_default': isDefault,
          })
          .select()
          .single();

      return response;
    } catch (e) {
      print('Error adding address: $e');
      rethrow;
    }
  }

  /// Update existing address
  Future<Map<String, dynamic>> updateAddress({
    required String addressId,
    required String customerId,
    required String label,
    required String city,
    required String district,
    required double latitude,
    required double longitude,
    String? addressDetails,
    bool? isDefault,
  }) async {
    try {
      // If setting as default, remove default from other addresses first
      if (isDefault == true) {
        await _supabase
            .from('customer_addresses')
            .update({'is_default': false})
            .eq('customer_id', customerId)
            .neq('id', addressId);
      }

      final updateData = <String, dynamic>{
        'label': label,
        'city': city,
        'district': district,
        'address_details': addressDetails,
        'location': 'POINT($longitude $latitude)',
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (isDefault != null) {
        updateData['is_default'] = isDefault;
      }

      final response = await _supabase
          .from('customer_addresses')
          .update(updateData)
          .eq('id', addressId)
          .select()
          .single();

      return response;
    } catch (e) {
      print('Error updating address: $e');
      rethrow;
    }
  }

  /// Set an address as default
  Future<void> setDefaultAddress(String customerId, String addressId) async {
    try {
      // Remove default from all addresses
      await _supabase
          .from('customer_addresses')
          .update({'is_default': false})
          .eq('customer_id', customerId);

      // Set new default
      await _supabase
          .from('customer_addresses')
          .update({'is_default': true})
          .eq('id', addressId);
    } catch (e) {
      print('Error setting default address: $e');
      rethrow;
    }
  }

  /// Delete address
  Future<void> deleteAddress(String addressId) async {
    try {
      await _supabase
          .from('customer_addresses')
          .delete()
          .eq('id', addressId);
    } catch (e) {
      print('Error deleting address: $e');
      rethrow;
    }
  }

  /// Parse location from PostGIS format to lat/lng
  Map<String, double>? parseLocation(dynamic location) {
    if (location == null) return null;

    try {
      // PostGIS returns location as: {"type":"Point","coordinates":[lng,lat]}
      if (location is Map) {
        final coordinates = location['coordinates'] as List?;
        if (coordinates != null && coordinates.length >= 2) {
          return {
            'latitude': (coordinates[1] as num).toDouble(),
            'longitude': (coordinates[0] as num).toDouble(),
          };
        }
      }
      return null;
    } catch (e) {
      print('Error parsing location: $e');
      return null;
    }
  }

  /// Format address for display
  String formatAddress(Map<String, dynamic> address) {
    final parts = <String>[];

    if (address['address_details'] != null && 
        (address['address_details'] as String).isNotEmpty) {
      parts.add(address['address_details']);
    }

    if (address['district'] != null) {
      parts.add(address['district']);
    }

    if (address['city'] != null) {
      parts.add(address['city']);
    }

    return parts.join(', ');
  }

  /// Get address count for customer
  Future<int> getAddressCount(String customerId) async {
    try {
      final response = await _supabase
          .from('customer_addresses')
          .select('id')
          .eq('customer_id', customerId);

      if (response is List) {
        return response.length;
      }

      return 0;
    } catch (e) {
      print('Error getting address count: $e');
      return 0;
    }
  }

  /// Validate address data
  String? validateAddress({
    required String label,
    required String city,
    required String district,
  }) {
    if (label.trim().isEmpty) {
      return 'Address label is required';
    }

    if (label.trim().length < 3) {
      return 'Address label must be at least 3 characters';
    }

    if (city.trim().isEmpty) {
      return 'City is required';
    }

    if (district.trim().isEmpty) {
      return 'District is required';
    }

    return null;
  }
}