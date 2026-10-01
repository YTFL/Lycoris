import 'package:flutter/material.dart';
import '../../domain/models/storefront.dart';

class StorefrontBadge extends StatelessWidget {
  final Storefront storefront;
  final bool showLabel;

  const StorefrontBadge({
    super.key,
    required this.storefront,
    this.showLabel = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: showLabel ? 8 : 6,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: storefront.brandColor.withAlpha(50),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: storefront.brandColor.withAlpha(160),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            storefront.fallbackIcon,
            size: 13,
            color: Colors.white.withAlpha(230),
          ),
          if (showLabel) ...[
            const SizedBox(width: 4),
            Text(
              storefront.label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
