import 'package:flutter/material.dart';
import 'package:flutter_sticky_header/flutter_sticky_header.dart';

import '../controller/journal_controller.dart';
import '../models/entry.dart'; // Needed for Entry type
import '../widgets/journal_entry.dart';
import '../widgets/edge_fade.dart';
import '../utils/system_ui_helper.dart';

class FavoritesScreen extends StatefulWidget {
  final JournalController journalController;

  const FavoritesScreen({super.key, required this.journalController});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    // No need to set onUpdate here, the controller is shared
    // and updates will be handled by calling setState after actions.
  }

  @override
  void dispose() {
    _scrollController.dispose();
    // It's important *not* to reset the controller's onUpdate here,
    // as the original JournalScreen still needs it.
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    updateSystemUiOverlay(context);
    final background = Theme.of(context).scaffoldBackgroundColor;
    final favoriteEntries = widget.journalController.favoriteEntries;
    final grouped = widget.journalController.groupEntriesByDate(
      favoriteEntries,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Favourites'),
        backgroundColor: background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        children: [
          if (favoriteEntries.isEmpty)
            Center(
              child: Text(
                'No favourite entries yet.',
                style: TextStyle(color: Theme.of(context).hintColor),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(
                bottom: 16.0,
              ), // Added bottom padding
              child: CustomScrollView(
                controller: _scrollController,
                slivers:
                    grouped.entries.map((entryGroup) {
                      return SliverStickyHeader(
                        header: Container(
                          color: background, // Ensure background for tap area
                          padding: const EdgeInsets.fromLTRB(
                            16,
                            8, // Reduced top padding
                            0,
                            4, // Reduced bottom padding
                          ),
                          child: Text(
                            entryGroup.key,
                            style: TextStyle(
                              fontSize: 16,
                              color: Theme.of(context).hintColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        sliver: SliverList(
                          // Using SliverList as animations aren't strictly needed here
                          delegate: SliverChildBuilderDelegate((
                            context,
                            index,
                          ) {
                            final entry = entryGroup.value[index];                            return JournalEntryWidget(
                              entry: entry,
                              // Allow unfavoriting from this screen
                              onToggleFavorite: (Entry e) async {
                                await widget.journalController.toggleFavorite(
                                  e,
                                );
                                // Call setState here to rebuild FavoritesScreen immediately
                                if (mounted) {
                                  setState(() {});
                                }
                              },
                              // Disable tap interactions on this screen for now
                              onInsight: null,
                              onEdit: null,
                              onDelete: null,
                              isSelectionMode: () => false,
                              onToggleSelection: null,
                            );
                          }, childCount: entryGroup.value.length),
                        ),
                      );
                    }).toList(),
              ),
            ),
          EdgeFade(top: true, background: background),
          EdgeFade(top: false, background: background),
        ],
      ),
    );
  }
}
