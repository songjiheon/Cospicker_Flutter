import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// 가로 스크롤 아이템 리스트 위젯
class HorizontalItemList extends StatelessWidget {
  final List<dynamic> items;
  final bool loading;
  final String emptyText;
  final Function(Map<String, dynamic>) onItemTap;

  const HorizontalItemList({
    super.key,
    required this.items,
    required this.loading,
    required this.emptyText,
    required this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const SizedBox(
        height: 120,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (items.isEmpty) {
      return SizedBox(
        height: 120,
        child: Center(child: Text(emptyText)),
      );
    }

    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        itemBuilder: (context, i) {
          final item = items[i];
          final imageUrl = item['firstimage'] ?? '';

          return GestureDetector(
            onTap: () => onItemTap(item as Map<String, dynamic>),
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
        },
      ),
    );
  }
}

