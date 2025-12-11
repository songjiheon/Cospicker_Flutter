import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// 최근 본 항목 카드 위젯 (숙소/맛집 공통)
class RecentItemCard extends StatelessWidget {
  final String imageUrl;
  final VoidCallback onTap;

  const RecentItemCard({
    super.key,
    required this.imageUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 120,
        margin: const EdgeInsets.only(right: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              color: Colors.grey[300],
              child: const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            errorWidget: (context, url, error) => Container(
              color: Colors.grey[300],
              child: const Icon(Icons.error_outline),
            ),
          ),
        ),
      ),
    );
  }
}

