import 'package:supabase_flutter/supabase_flutter.dart';

class ProviderService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Get all providers with optional filters
  Future<List<Map<String, dynamic>>> getProviders({
    String? category,
    String? searchQuery,
    String? city,
    bool? isFeatured,
    int? limit,
  }) async {
    try {
      var query = _supabase
          .from('providers')
          .select()
          .eq('is_active', true);

      if (category != null) {
        query = query.eq('category', category);
      }

      if (isFeatured != null && isFeatured) {
        query = query.eq('is_featured', true);
      }

      if (searchQuery != null && searchQuery.isNotEmpty) {
        query = query.or('company_name_en.ilike.%$searchQuery%,company_name_ar.ilike.%$searchQuery%,store_description.ilike.%$searchQuery%');
      }

      if (city != null && city.isNotEmpty) {
        query = query.eq('store_location', city);
      }

      // Apply ordering and limit at the end
      var finalQuery = query.order('average_rating', ascending: false)
                            .order('created_at', ascending: false);

      if (limit != null) {
        finalQuery = finalQuery.limit(limit);
      }

      final response = await finalQuery;
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching providers: $e');
      return [];
    }
  }

  /// Get featured providers
  Future<List<Map<String, dynamic>>> getFeaturedProviders({int limit = 5}) async {
    return getProviders(isFeatured: true, limit: limit);
  }

  /// Get provider by ID
  Future<Map<String, dynamic>?> getProviderById(String providerId) async {
    try {
      final response = await _supabase
          .from('providers')
          .select()
          .eq('id', providerId)
          .single();

      return response;
    } catch (e) {
      print('Error fetching provider: $e');
      return null;
    }
  }

  /// Get all unique cities (for location filter)
  Future<List<String>> getAllCities() async {
    try {
      final response = await _supabase
          .from('providers')
          .select('store_location')
          .eq('is_active', true);

      final cities = <String>{};
      for (var provider in response) {
        final city = provider['store_location'] as String?;
        if (city != null && city.isNotEmpty) {
          cities.add(city);
        }
      }

      final cityList = cities.toList();
      cityList.sort();
      return cityList;
    } catch (e) {
      print('Error fetching cities: $e');
      return [];
    }
  }

  /// Search providers by multiple criteria
  Future<List<Map<String, dynamic>>> searchProviders({
    String? query,
    String? category,
    String? city,
    double? minRating,
    String? priceRange,
  }) async {
    try {
      var supabaseQuery = _supabase
          .from('providers')
          .select()
          .eq('is_active', true);

      if (query != null && query.isNotEmpty) {
        supabaseQuery = supabaseQuery.or(
          'company_name_en.ilike.%$query%,company_name_ar.ilike.%$query%,store_description.ilike.%$query%',
        );
      }

      if (category != null) {
        supabaseQuery = supabaseQuery.eq('category', category);
      }

      if (city != null && city.isNotEmpty) {
        supabaseQuery = supabaseQuery.eq('store_location', city);
      }

      if (minRating != null) {
        supabaseQuery = supabaseQuery.gte('average_rating', minRating);
      }

      if (priceRange != null && priceRange.isNotEmpty) {
        supabaseQuery = supabaseQuery.eq('price_range', priceRange);
      }

      // Apply ordering at the end
      final response = await supabaseQuery.order('average_rating', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error searching providers: $e');
      return [];
    }
  }
}