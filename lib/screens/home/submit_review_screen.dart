import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../services/reviews_service.dart';
import '../../config/app_theme.dart';
import '../../l10n/app_localizations.dart';

class SubmitReviewScreen extends StatefulWidget {
  final String orderId;
  final Map<String, dynamic> order;

  const SubmitReviewScreen({
    Key? key,
    required this.orderId,
    required this.order,
  }) : super(key: key);

  @override
  State<SubmitReviewScreen> createState() => _SubmitReviewScreenState();
}

class _SubmitReviewScreenState extends State<SubmitReviewScreen> {
  final _supabase = Supabase.instance.client;
  final _reviewsService = ReviewsService();
  final _reviewTextController = TextEditingController();
  final _imagePicker = ImagePicker();

  double _providerRating = 5.0;
  Map<String, double> _itemRatings = {};
  List<File> _selectedPhotos = [];
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _initializeItemRatings();
  }

  @override
  void dispose() {
    _reviewTextController.dispose();
    super.dispose();
  }

  void _initializeItemRatings() {
    final orderItems = widget.order['order_items'] as List;
    for (final orderItem in orderItems) {
      final item = orderItem['items'] as Map<String, dynamic>;
      final itemId = item['id'] as String;
      _itemRatings[itemId] = 5.0;
    }
  }

  Future<void> _pickImage() async {
  final l10n = AppLocalizations.of(context);
  if (_selectedPhotos.length >= 5) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Maximum 5 photos allowed')),
    );
    return;
  }

  // Show dialog to choose camera or gallery
  final source = await showDialog<ImageSource>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n.selectPhotoSource),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: Text(l10n.takePhoto),
            onTap: () => Navigator.pop(context, ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: Text(l10n.chooseFromGallery),
            onTap: () => Navigator.pop(context, ImageSource.gallery),
          ),
        ],
      ),
    ),
  );

  if (source == null) return;

  try {
    final XFile? image = await _imagePicker.pickImage(
      source: source,  // <-- USE SELECTED SOURCE
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 85,
    );

      if (image != null && mounted) {
        setState(() {
          _selectedPhotos.add(File(image.path));
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  void _removePhoto(int index) {
    setState(() {
      _selectedPhotos.removeAt(index);
    });
  }

  Future<void> _submitReview() async {
    final customerId = _supabase.auth.currentUser?.id;
    if (customerId == null) return;

    // Validate
    final errors = _reviewsService.validateReview(
      providerRating: _providerRating,
      itemRatings: _itemRatings,
      reviewText: _reviewTextController.text.trim(),
    );

    if (errors.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errors.values.first ?? 'Validation error')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final provider = widget.order['providers'] as Map<String, dynamic>;
      final providerId = provider['id'] as String;

      // Upload photos if any
      List<String> photoUrls = [];
      for (final photo in _selectedPhotos) {
        final url = await _reviewsService.uploadReviewPhoto(
          widget.orderId,
          photo.path,
        );
        photoUrls.add(url);
      }

      // Submit review
      await _reviewsService.submitReview(
        orderId: widget.orderId,
        customerId: customerId,
        providerId: providerId,
        providerRating: _providerRating,
        itemRatings: _itemRatings,
        reviewText: _reviewTextController.text.trim().isEmpty
            ? null
            : _reviewTextController.text.trim(),
        photoUrls: photoUrls.isEmpty ? null : photoUrls,
      );

      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.thankYouForReview),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.error}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final provider = widget.order['providers'] as Map<String, dynamic>;
    final orderItems = widget.order['order_items'] as List;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.writeReview),
        backgroundColor: AppTheme.primaryNavy,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProviderSection(provider),
            const SizedBox(height: 24),
            _buildProviderRating(),
            const SizedBox(height: 24),
            _buildItemRatings(orderItems),
            const SizedBox(height: 24),
            _buildReviewText(),
            const SizedBox(height: 24),
            _buildPhotoSection(),
            const SizedBox(height: 24),
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildProviderSection(Map<String, dynamic> provider) {
    final l10n = AppLocalizations.of(context);
    final companyName = provider['company_name_en'] as String;
    final photoUrl = provider['profile_photo_url'] as String?;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
              child: photoUrl == null ? const Icon(Icons.business, size: 30) : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.howWasYourOrder,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    companyName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProviderRating() {
    final l10n = AppLocalizations.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.rateProvider,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return IconButton(
                  iconSize: 40,
                  onPressed: () {
                    setState(() {
                      _providerRating = (index + 1).toDouble();
                    });
                  },
                  icon: Icon(
                    index < _providerRating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                  ),
                );
              }),
            ),
            Center(
              child: Text(
                _getRatingLabel(_providerRating),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryNavy,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemRatings(List<dynamic> orderItems) {
    final l10n = AppLocalizations.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.rateItems,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            ...orderItems.map((orderItem) {
              final item = orderItem['items'] as Map<String, dynamic>;
              final itemId = item['id'] as String;
              final itemName = item['name'] as String;
              final photoUrls = item['photo_urls'] as List?;
              final photoUrl = photoUrls?.isNotEmpty == true ? photoUrls![0] : null;

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (photoUrl != null)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              photoUrl,
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: 50,
                                  height: 50,
                                  color: Colors.grey[300],
                                  child: const Icon(Icons.image),
                                );
                              },
                            ),
                          ),
                        if (photoUrl != null) const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            itemName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        return IconButton(
                          iconSize: 32,
                          onPressed: () {
                            setState(() {
                              _itemRatings[itemId] = (index + 1).toDouble();
                            });
                          },
                          icon: Icon(
                            index < (_itemRatings[itemId] ?? 5)
                                ? Icons.star
                                : Icons.star_border,
                            color: Colors.amber,
                          ),
                        );
                      }),
                    ),
                    const Divider(),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewText() {
    final l10n = AppLocalizations.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${l10n.yourReview} (${l10n.optional})',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _reviewTextController,
              maxLines: 5,
              maxLength: 1000,
              decoration: InputDecoration(
                hintText: l10n.writeYourReview,
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoSection() {
    final l10n = AppLocalizations.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Add Photos (${l10n.optional})',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  '${_selectedPhotos.length}/5',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_selectedPhotos.isEmpty)
              Center(
                child: OutlinedButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.add_photo_alternate),
                  label: const Text('Add Photos'),
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ..._selectedPhotos.asMap().entries.map((entry) {
                    final index = entry.key;
                    final photo = entry.value;
                    return Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            photo,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () => _removePhoto(index),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  }),
                  if (_selectedPhotos.length < 5)
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[400]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.add, color: Colors.grey),
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    final l10n = AppLocalizations.of(context);
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitReview,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryNavy,
          foregroundColor: Colors.white,
        ),
        child: _isSubmitting
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(
                l10n.submitReview,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  String _getRatingLabel(double rating) {
    if (rating == 5) return 'Excellent!';
    if (rating == 4) return 'Very Good';
    if (rating == 3) return 'Good';
    if (rating == 2) return 'Fair';
    return 'Poor';
  }
}