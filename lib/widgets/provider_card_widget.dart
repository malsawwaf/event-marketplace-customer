import 'package:flutter/material.dart';
import '../services/favourites_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProviderCardWidget extends StatefulWidget {
  final Map<String, dynamic> provider;
  final VoidCallback? onTap;

  const ProviderCardWidget({
    Key? key,
    required this.provider,
    this.onTap,
  }) : super(key: key);

  @override
  State<ProviderCardWidget> createState() => _ProviderCardWidgetState();
}

class _ProviderCardWidgetState extends State<ProviderCardWidget> {
  bool _isFavorited = false;
  bool _isLoadingFavorite = true;

  @override
  void initState() {
    super.initState();
    _checkFavoriteStatus();
  }

  Future<void> _checkFavoriteStatus() async {
    final supabase = Supabase.instance.client;
    final customerId = supabase.auth.currentUser?.id;

    if (customerId == null) {
      setState(() => _isLoadingFavorite = false);
      return;
    }

    final favoritesService = FavoritesService();
    final isFavorited = await favoritesService.isProviderFavorited(
      customerId,
      widget.provider['id'] as String,
    );

    if (mounted) {
      setState(() {
        _isFavorited = isFavorited;
        _isLoadingFavorite = false;
      });
    }
  }

  Future<void> _toggleFavorite() async {
    final supabase = Supabase.instance.client;
    final customerId = supabase.auth.currentUser?.id;

    if (customerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to add favorites')),
      );
      return;
    }

    setState(() => _isLoadingFavorite = true);

    try {
      final favoritesService = FavoritesService();
      final newStatus = await favoritesService.toggleProviderFavorite(
        customerId,
        widget.provider['id'] as String,
      );

      if (mounted) {
        setState(() {
          _isFavorited = newStatus;
          _isLoadingFavorite = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newStatus
                  ? 'Added to favorites'
                  : 'Removed from favorites',
            ),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingFavorite = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update favorite')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final companyName = widget.provider['company_name_en'] as String? ?? 'Unknown';
    final location = widget.provider['store_location'] as String? ?? '';
    final photoUrl = widget.provider['profile_photo_url'] as String?;
    final priceRange = widget.provider['price_range'] as String? ?? 'moderate';
    final averageRating = (widget.provider['average_rating'] as num?)?.toDouble() ?? 0.0;
    final totalReviews = widget.provider['total_reviews'] as int? ?? 0;
    final isFeatured = widget.provider['is_featured'] as bool? ?? false;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover Photo with Featured Badge and Favorite Button
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  child: photoUrl != null
                      ? Image.network(
                          photoUrl,
                          height: 150,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 150,
                              color: Colors.grey[300],
                              child: const Icon(Icons.business, size: 50),
                            );
                          },
                        )
                      : Container(
                          height: 150,
                          color: Colors.grey[300],
                          child: const Icon(Icons.business, size: 50),
                        ),
                ),
                // Featured Badge
                if (isFeatured)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.star, size: 14, color: Colors.white),
                          SizedBox(width: 4),
                          Text(
                            'Featured',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                // Favorite Button
                Positioned(
                  top: 8,
                  right: 8,
                  child: _isLoadingFavorite
                      ? Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : IconButton(
                          icon: Icon(
                            _isFavorited ? Icons.favorite : Icons.favorite_border,
                            color: _isFavorited ? Colors.red : Colors.white,
                          ),
                          onPressed: _toggleFavorite,
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white.withOpacity(0.9),
                            padding: const EdgeInsets.all(8),
                          ),
                        ),
                ),
              ],
            ),
            // Provider Info
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Company Name
                  Text(
                    companyName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // Location
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          location,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Rating and Price Range
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Rating
                      Row(
                        children: [
                          const Icon(Icons.star, size: 16, color: Colors.amber),
                          const SizedBox(width: 4),
                          Text(
                            averageRating.toStringAsFixed(1),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            ' ($totalReviews)',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      // Price Range (SAR icons)
                      Row(
                        children: List.generate(
                          4,
                          (index) => Padding(
                            padding: const EdgeInsets.only(left: 2),
                            child: Image.asset(
                              'assets/icons/sar_icon.png',
                              width: 12,
                              height: 12,
                              color: index < _getPriceRangeCount(priceRange)
                                  ? Colors.green
                                  : Colors.grey[300],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _getPriceRangeCount(String priceRange) {
    switch (priceRange) {
      case 'budget':
        return 1;
      case 'moderate':
        return 2;
      case 'premium':
        return 3;
      case 'luxury':
        return 4;
      default:
        return 2;
    }
  }
}
