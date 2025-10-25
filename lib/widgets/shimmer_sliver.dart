import 'package:flutter/material.dart';
import 'package:flutter_sticky_header/flutter_sticky_header.dart';
import 'journal_entry_shimmer.dart'; // Assuming JournalEntryShimmer is in the same directory

class ShimmerSliver extends StatelessWidget {
  const ShimmerSliver({super.key});

  @override
  Widget build(BuildContext context) {
    return SliverStickyHeader(
      header: Container(height: 32, color: Colors.transparent),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (_, __) => const JournalEntryShimmer(),
          childCount: 1,
        ),
      ),
    );
  }
}
