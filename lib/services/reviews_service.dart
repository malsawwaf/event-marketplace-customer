import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import '../l10n/app_localizations.dart';

class ReviewsService {
  final _supabase = Supabase.instance.client;

  // ==========================================
  // EXISTING METHODS (For viewing reviews)
  // ==========================================

  /// Get recent reviews for a provider (last 3)
  Future<List<Map<String, dynamic>>> getRecentReviews(String providerId) async {
    try {
      print('🔍 Fetching reviews for provider: $providerId');
      
      final response = await _supabase
          .from('reviews')
          .select('*, customers(first_name, last_name)')
          .eq('provider_id', providerId)
          .order('created_at', ascending: false)
          .limit(3);

      print('📦 Raw response type: ${response.runtimeType}');
      print('📦 Response data: $response');
      
      // Handle response properly - it's already a List
      if (response is List) {
        final reviews = response.map((item) => Map<String, dynamic>.from(item as Map)).toList();
        print('📦 Parsed reviews count: ${reviews.length}');
        return reviews;
      }
      
      print('⚠️ Unexpected response type');
      return [];
    } catch (e) {
      print('❌ Error fetching reviews: $e');
      print('❌ Error type: ${e.runtimeType}');
      return [];
    }
  }

  /// Get all reviews for a provider
  Future<List<Map<String, dynamic>>> getProviderReviews(String providerId) async {
    try {
      final response = await _supabase
          .from('reviews')
          .select('*, customers(first_name, last_name)')
          .eq('provider_id', providerId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching all reviews: $e');
      return [];
    }
  }

  /// Format customer name (first name + stars for last name)
  /// Shows "You Posted This Review" if the review belongs to the current user
  String formatCustomerName(
    BuildContext context,
    Map<String, dynamic>? customer,
    String? reviewCustomerId,
    String? currentUserId,
  ) {
    final l10n = AppLocalizations.of(context);

    // Check if the review was posted by the logged-in user
    if (reviewCustomerId != null &&
        currentUserId != null &&
        reviewCustomerId == currentUserId) {
      return l10n.youPostedThisReview;
    }

    if (customer == null) return l10n.anonymous;

    final firstName = customer['first_name'] ?? l10n.anonymous;
    final lastName = customer['last_name'] ?? '';

    if (lastName.isEmpty) return firstName;

    // Hide last name with stars (e.g., "Ahmed M***")
    final lastNameInitial = lastName.isNotEmpty ? lastName[0] : '';
    final stars = '*' * (lastName.length - 1).clamp(3, 5);

    return '$firstName $lastNameInitial$stars';
  }

  /// Get time ago string (e.g., "2 days ago")
  String getTimeAgo(BuildContext context, String? timestamp) {
    if (timestamp == null) return '';

    final l10n = AppLocalizations.of(context);

    try {
      final date = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays > 365) {
        final years = (difference.inDays / 365).floor();
        return years == 1 ? l10n.yearAgo(years) : l10n.yearsAgo(years);
      } else if (difference.inDays > 30) {
        final months = (difference.inDays / 30).floor();
        return months == 1 ? l10n.monthAgo(months) : l10n.monthsAgo(months);
      } else if (difference.inDays > 0) {
        return difference.inDays == 1 ? l10n.dayAgo(difference.inDays) : l10n.daysAgo2(difference.inDays);
      } else if (difference.inHours > 0) {
        return difference.inHours == 1 ? l10n.hourAgo(difference.inHours) : l10n.hoursAgo2(difference.inHours);
      } else if (difference.inMinutes > 0) {
        return difference.inMinutes == 1 ? l10n.minuteAgo(difference.inMinutes) : l10n.minutesAgo2(difference.inMinutes);
      } else {
        return l10n.justNow;
      }
    } catch (e) {
      return '';
    }
  }

  // ==========================================
  // NEW METHODS (For submitting reviews)
  // ==========================================

  /// Submit a review for an order
  Future<void> submitReview({
    required String orderId,
    required String customerId,
    required String providerId,
    required double providerRating,
    required Map<String, double> itemRatings, // itemId: rating
    String? reviewText,
    List<String>? photoUrls,
  }) async {
    try {
      // Create the main review
      final review = await _supabase.from('reviews').insert({
        'customer_id': customerId,
        'provider_id': providerId,
        'order_id': orderId,
        'rating': providerRating,
        'review_text': reviewText,
        'photo_url': photoUrls ?? [],
        'created_at': DateTime.now().toIso8601String(),
      }).select().single();

      final reviewId = review['id'] as String;

      // Create item ratings
      for (final entry in itemRatings.entries) {
        await _supabase.from('item_ratings').insert({
          'review_id': reviewId,
          'item_id': entry.key,
          'rating': entry.value,
        });
      }

      // Update provider's average rating
      await _updateProviderRating(providerId);
      
      // Update each item's average rating
      for (final itemId in itemRatings.keys) {
        await _updateItemRating(itemId);
      }
    } catch (e) {
      throw Exception('Failed to submit review: $e');
    }
  }

  /// Update provider's average rating
  Future<void> _updateProviderRating(String providerId) async {
    try {
      final response = await _supabase
          .from('reviews')
          .select('rating')
          .eq('provider_id', providerId);

      if (response.isEmpty) return;

      final ratings = response.map((r) => (r['rating'] as num).toDouble()).toList();
      final avgRating = ratings.reduce((a, b) => a + b) / ratings.length;
      final reviewCount = ratings.length;

      await _supabase.from('providers').update({
        'average_rating': avgRating,
        'review_count': reviewCount,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', providerId);
    } catch (e) {
      // Log error but don't fail the review submission
      print('Error updating provider rating: $e');
    }
  }

  /// Update item's average rating
  Future<void> _updateItemRating(String itemId) async {
    try {
      final response = await _supabase
          .from('item_ratings')
          .select('rating')
          .eq('item_id', itemId);

      if (response.isEmpty) return;

      final ratings = response.map((r) => (r['rating'] as num).toDouble()).toList();
      final avgRating = ratings.reduce((a, b) => a + b) / ratings.length;
      final ratingCount = ratings.length;

      await _supabase.from('items').update({
        'average_rating': avgRating,
        'rating_count': ratingCount,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', itemId);
    } catch (e) {
      // Log error but don't fail the review submission
      print('Error updating item rating: $e');
    }
  }

  /// Check if customer has already reviewed an order
  Future<bool> hasReviewedOrder(String orderId, String customerId) async {
    try {
      final response = await _supabase
          .from('reviews')
          .select('id')
          .eq('order_id', orderId)
          .eq('customer_id', customerId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      throw Exception('Failed to check review status: $e');
    }
  }

  /// Get customer's reviews
  Future<List<Map<String, dynamic>>> getCustomerReviews(String customerId) async {
    try {
      final response = await _supabase
          .from('reviews')
          .select('''
            *,
            providers (
              id,
              company_name_en,
              trading_name,
              profile_photo_url
            ),
            orders (
              order_number
            )
          ''')
          .eq('customer_id', customerId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to load reviews: $e');
    }
  }

  /// Upload review photo
  Future<String> uploadReviewPhoto(String reviewId, String filePath) async {
    try {
      final fileName = '${reviewId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final storagePath = 'reviews/$fileName';

      // Read file as bytes
      final file = File(filePath);
      final bytes = await file.readAsBytes();

      await _supabase.storage
          .from('review_photos')
          .uploadBinary(storagePath, bytes);

      final publicUrl = _supabase.storage
          .from('review_photos')
          .getPublicUrl(storagePath);

      return publicUrl;
    } catch (e) {
      throw Exception('Failed to upload photo: $e');
    }
  }

  /// Delete review (if within edit window)
  Future<void> deleteReview(String reviewId, String customerId) async {
    try {
      // Verify ownership
      final review = await _supabase
          .from('reviews')
          .select('customer_id, created_at')
          .eq('id', reviewId)
          .single();

      if (review['customer_id'] != customerId) {
        throw Exception('Unauthorized: Not your review');
      }

      // Check if within 24 hours
      final createdAt = DateTime.parse(review['created_at']);
      final now = DateTime.now();
      if (now.difference(createdAt).inHours > 24) {
        throw Exception('Reviews can only be deleted within 24 hours');
      }

      // Delete item ratings first
      await _supabase
          .from('item_ratings')
          .delete()
          .eq('review_id', reviewId);

      // Delete review
      await _supabase
          .from('reviews')
          .delete()
          .eq('id', reviewId);
    } catch (e) {
      throw Exception('Failed to delete review: $e');
    }
  }

  /// Format rating for display
  String formatRating(double rating) {
    return rating.toStringAsFixed(1);
  }

  /// Get star icon count from rating
  int getFullStars(double rating) {
    return rating.floor();
  }

  /// Check if rating has half star
  bool hasHalfStar(double rating) {
    return (rating - rating.floor()) >= 0.5;
  }

  /// Validate review data
  Map<String, String?> validateReview({
    required double providerRating,
    required Map<String, double> itemRatings,
    String? reviewText,
  }) {
    final errors = <String, String?>{};

    if (providerRating < 1 || providerRating > 5) {
      errors['provider_rating'] = 'Provider rating must be between 1 and 5';
    }

    for (final entry in itemRatings.entries) {
      if (entry.value < 1 || entry.value > 5) {
        errors['item_${entry.key}'] = 'Item rating must be between 1 and 5';
      }
    }

    if (reviewText != null && reviewText.length > 1000) {
      errors['review_text'] = 'Review text cannot exceed 1000 characters';
    }

    return errors.isEmpty ? {} : errors;
  }
}