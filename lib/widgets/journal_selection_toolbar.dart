import 'package:flutter/material.dart';

class JournalSelectionToolbar extends StatelessWidget {
  final int selectedCount;
  final VoidCallback onClearSelection;
  final VoidCallback onDeleteSelected;

  const JournalSelectionToolbar({
    super.key,
    required this.selectedCount,
    required this.onClearSelection,
    required this.onDeleteSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: onClearSelection,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                tooltip: 'Clear selection',
              ),
              const SizedBox(width: 12), // Add some spacing
              Text(
                '$selectedCount selected',
                style: theme.textTheme.titleMedium,
              ),
            ],
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 20),
                onPressed: onDeleteSelected,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                tooltip: 'Delete selected',
              ),
              // Potentially add other actions like "Favorite selected", "Export selected" etc.
            ],
          ),
        ],
      ),
    );
  }
}
