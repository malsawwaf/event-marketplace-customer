import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/reviews_service.dart';

class ReviewCard extends StatelessWidget {
  final Map<String, dynamic> review;

  const ReviewCard({
    Key? key,
    required this.review,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final reviewsService = ReviewsService(); // Create instance in build method
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;

    final rating = (review['rating'] as num?)?.toInt() ?? 0;
    final reviewText = review['review_text'] ?? '';
    final customer = review['customers'] as Map<String, dynamic>?;
    final customerId = review['customer_id'] as String?;
    final customerName = reviewsService.formatCustomerName(customer, customerId, currentUserId);
    final timeAgo = reviewsService.getTimeAgo(review['created_at']);

    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Rating Stars
          Row(
            children: List.generate(5, (index) {
              return Icon(
                index < rating ? Icons.star : Icons.star_border,
                color: Colors.amber[700],
                size: 20,
              );
            }),
          ),
          const SizedBox(height: 12),
          // Customer Name
          Text(
            customerName,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          // Review Text
          Text(
            reviewText.isNotEmpty ? reviewText : 'No comment provided',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              height: 1.4,
            ),
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          // Time Ago
          Text(
            timeAgo,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}