import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class JournalEntryShimmer extends StatelessWidget {
  const JournalEntryShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final baseColor = isDark ? Colors.grey[900]! : Colors.grey[200]!;
    final highlightColor = isDark ? Colors.grey[850]! : Colors.grey[100]!;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timestamp shimmer
          Padding(
            padding: const EdgeInsets.only(bottom: 6, left: 4),
            child: _ShimmerBox(
              width: 120,
              height: 11,
              baseColor: baseColor,
              highlightColor: highlightColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Image Placeholder Shimmer
          Padding(
            padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
            child: _ShimmerBox(
              width: double.infinity,
              height: 100,
              baseColor: baseColor,
              highlightColor: highlightColor,
              borderRadius: BorderRadius.circular(4.0),
            ),
          ),
          // Metadata shimmer (mood/tags/word count)
          _ShimmerBox(
            width: 180,
            height: 12,
            baseColor: baseColor,
            highlightColor: highlightColor,
            borderRadius: BorderRadius.circular(2),
          ),
          const SizedBox(height: 4),
          // Entry text shimmer
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ShimmerBox(
                      width: double.infinity,
                      height: 16,
                      baseColor: baseColor,
                      highlightColor: highlightColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                    const SizedBox(height: 8),
                    _ShimmerBox(
                      width: double.infinity,
                      height: 16,
                      baseColor: baseColor,
                      highlightColor: highlightColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                    const SizedBox(height: 8),
                    _ShimmerBox(
                      width: 200,
                      height: 16,
                      baseColor: baseColor,
                      highlightColor: highlightColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Favorite star shimmer
              _ShimmerBox(
                width: 18,
                height: 18,
                baseColor: baseColor,
                highlightColor: highlightColor,
                borderRadius: BorderRadius.circular(9), // For a circle, radius is half of width/height
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ShimmerBox extends StatelessWidget {
  final double width;
  final double height;
  final Color baseColor;
  final Color highlightColor;
  final BorderRadiusGeometry? borderRadius;

  const _ShimmerBox({
    required this.width,
    required this.height,
    required this.baseColor,
    required this.highlightColor,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: baseColor, // This color defines the shape for the shimmer
          borderRadius: borderRadius,
        ),
      ),
    );
  }
}
