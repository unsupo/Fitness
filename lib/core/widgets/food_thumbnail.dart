import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// A small rounded food photo, with a graceful fallback icon when
/// [imageUrl] is null or fails to load.
class FoodThumbnail extends StatelessWidget {
  const FoodThumbnail({super.key, this.imageUrl, this.size = 40});

  final String? imageUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl;
    final radius = size / 4;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppColors.ringTrack, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: url == null
          ? _placeholder()
          : Image.network(
              url,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, progress) =>
                  progress == null ? child : _placeholder(),
              errorBuilder: (context, error, stackTrace) => _placeholder(),
            ),
    );
  }

  Widget _placeholder() => Container(
    color: AppColors.background,
    alignment: Alignment.center,
    child: Icon(
      Icons.restaurant,
      size: size * 0.45,
      color: AppColors.textSecondary,
    ),
  );
}
