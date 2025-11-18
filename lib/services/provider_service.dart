import 'package:supabase_flutter/supabase_flutter.dart';

class ProviderService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Get all providers with optional filters
  Future<List<Map<String, dynamic>>> getProviders({
    String? category,
    String? searchQuery,
    String? city,
    String? country,
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
        query = query.or('company_name_en.ilike.%$searchQuery%,trading_name.ilike.%$searchQuery%,store_description.ilike.%$searchQuery%');
      }

      // Filter by city (new dedicated field)
      if (city != null && city.isNotEmpty) {
        query = query.eq('city', city);
      }

      // Filter by country (for future multi-country expansion)
      if (country != null && country.isNotEmpty) {
        query = query.eq('country', country);
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

  /// Get all unique cities where providers are available
  Future<List<String>> getAllCities({String? country}) async {
    try {
      var query = _supabase
          .from('providers')
          .select('city')
          .eq('is_active', true);

      // Filter by country if specified
      if (country != null && country.isNotEmpty) {
        query = query.eq('country', country);
      }

      final response = await query;

      final cities = <String>{};
      for (var provider in response) {
        final city = provider['city'] as String?;
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
          'company_name_en.ilike.%$query%,trading_name.ilike.%$query%,store_description.ilike.%$query%',
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