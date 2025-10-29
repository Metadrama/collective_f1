//
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_sticky_header/flutter_sticky_header.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../screens/settings_screen.dart';
import '../services/preferences_service.dart';
import 'package:collective/widgets/calendar_modal.dart';
import 'favorites_screen.dart';
import 'entry_insight_screen.dart';
import 'edit_entry_screen.dart';
import 'analytics_screen.dart';
import '../widgets/edge_fade.dart';
import '../widgets/shimmer_sliver.dart';
import '../widgets/indeterminate_progress_bar.dart';
import '../utils/custom_delete_dialog.dart';

import '../widgets/journal_input.dart';
import '../widgets/journal_entry.dart';
import '../widgets/journal_toolbar.dart';
import '../widgets/journal_selection_toolbar.dart';
import '../controller/journal_controller.dart';
import '../utils/system_ui_helper.dart';
import '../widgets/slidable_open_trigger.dart';

class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen>
    with TickerProviderStateMixin {
  late final JournalController jc;
  final scrollController = ScrollController();
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  bool _isSearching = false;
  bool _prefSwipeDeleteEnabled = true;
  bool _prefSwipeFavoriteEnabled = true;
  bool _prefDeleteConfirmEnabled = true;
  bool _prefCloseOnScroll = true;
  String _prefMotion = 'scroll';

  @override
  void initState() {
    super.initState();
    jc = JournalController(
      vsync: this,
      onUpdate: () {
        if (mounted) {
          setState(() {});
        }
      }, // Ensure mounted check
      scrollController: scrollController,
    );
    jc.loadEntriesFromFirestore();
    _loadSwipePrefs();
    _searchController.addListener(() {
      // Listener to update UI when search text changes
      if (mounted) {
        setState(() {});
      }
    });
  }

  Future<void> _loadSwipePrefs() async {
    final d = await PreferencesService.isSwipeDeleteEnabled();
    final f = await PreferencesService.isSwipeFavoriteEnabled();
    final c = await PreferencesService.isDeleteConfirmationEnabled();
    final cos = await PreferencesService.isCloseOnScrollEnabled();
    final m = await PreferencesService.getSlidableMotion();
    if (!mounted) return;
    setState(() {
      _prefSwipeDeleteEnabled = d;
      _prefSwipeFavoriteEnabled = f;
      _prefDeleteConfirmEnabled = c;
      _prefCloseOnScroll = cos;
      _prefMotion = m;
    });
  }

  @override
  void dispose() {
    jc.dispose();
    scrollController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (_isSearching) {
        _searchFocusNode.requestFocus();
      } else {
        _searchFocusNode.unfocus();
        _searchController.clear();
        jc.updateSearchTerm(''); // Clear search term in controller
      }
    });
  }

  void _onSearchChanged(String query) {
    jc.updateSearchTerm(query);
  }

  @override
  Widget build(BuildContext context) {
    // Keep a stable reference to the screen context for navigation/dialogs
    final rootContext = context;
    updateSystemUiOverlay(context);
    final background = Theme.of(context).scaffoldBackgroundColor;
    // Use filteredEntries for display
    final grouped = jc.groupEntriesByDate(jc.filteredEntries);

    return Scaffold(
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child:
                jc.isSelectionMode
                    ? JournalSelectionToolbar(
                      selectedCount: jc.selectedEntries.length,
                      onClearSelection:
                          () => setState(() => jc.clearSelection()),
                      onDeleteSelected: () async {
                        await jc.deleteSelectedEntries();
                        // setState is called by jc.onUpdate via deleteSelectedEntries
                      },
                    )                    : JournalToolbar(
                      isSearching: _isSearching,
                      onToggleSearch: _toggleSearch,
                      searchController: _searchController,
                      searchFocusNode: _searchFocusNode,
                      onSearchChanged: _onSearchChanged,
                      syncStatus: jc.syncStatus, // Pass syncStatus
                      onToggleFavorites: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => FavoritesScreen(
                                  journalController: jc, // Pass the controller
                                ),
                          ),
                        );
                      },
                      onOpenDatePicker: () {
                        showCalendarModal(
                          context,
                          jc.entries, // show all entries in calendar, not filtered
                          scrollController,
                        );
                      },
                      onOpenAnalytics: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AnalyticsScreen(
                              journalController: jc,
                            ),
                          ),
                        );
                      },
                      onOpenSettings: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SettingsScreen(),
                          ),
                        );
                        _loadSwipePrefs();
                      },
                    ),
          ),
          Expanded(
            child: Stack(
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  child: SlidableAutoCloseBehavior(
                    child: CustomScrollView(
                    key: ValueKey('${jc.isLoading}_${jc.entries.length}_${grouped.length}'),
                    controller: scrollController,
                    slivers:
                        jc.isLoading
                            ? List.generate(5, (_) => const ShimmerSliver())
                                .toList() // Use new widget
                            : grouped.entries.map((entryGroup) {
                              return SliverStickyHeader(
                                header: GestureDetector(
                                  onLongPress: () {
                                    jc.selectEntriesByDate(entryGroup.value);
                                  },
                                  onTap: () {
                                    // Added onTap for deselection
                                    if (jc.isSelectionMode) {
                                      jc.deselectEntriesByDate(
                                        entryGroup.value,
                                      );
                                    }
                                  },
                                  child: Container(
                                    color: Colors.transparent, // Make the full row background transparent
                                    padding: const EdgeInsets.fromLTRB(
                                      2, // Reduced left padding to minimize wasted space
                                      8, // Reduced top padding
                                      16,
                                      4, // Reduced bottom padding
                                    ),
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 1,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).brightness == Brightness.dark
                                              ? const Color.fromARGB(255, 48, 48, 48).withOpacity(0.9)
                                              : const Color.fromARGB(255, 168, 168, 168).withOpacity(0.95),
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(
                                            color: Theme.of(context).brightness == Brightness.dark
                                                ? Colors.white.withOpacity(0.1)
                                                : Colors.black.withOpacity(0.05),
                                            width: 0.5,
                                          ),
                                        ),
                                        child: Text(
                                          entryGroup.key,
                                          style: TextStyle(
                                            fontSize: 13, // Smaller font size
                                            color: Theme.of(context).brightness == Brightness.dark
                                                ? Colors.white.withOpacity(0.8)
                                                : Colors.white.withOpacity(0.9),
                                            fontWeight: FontWeight.w500,
                                            fontFamily: 'IBM Plex Sans', // Sans font
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                sliver: SliverList(
                                  delegate: SliverChildBuilderDelegate(
                                    (context, index) {
                                      final entry = entryGroup.value[index];
                                      return TweenAnimationBuilder<double>(
                                        duration: const Duration(milliseconds: 300),
                                        tween: Tween(begin: 0.0, end: 1.0),
                                        curve: Curves.easeOut,
                                        builder: (context, value, child) {
                                          return Transform.scale(
                                            scale: 0.95 + (0.05 * value),
                                            child: Opacity(
                                              opacity: value,
                                              child: child,
                                            ),
                                          );
                                        },
                                        child: Slidable(
                                          groupTag: 'journal_entries',
                                          key: ValueKey(entry.localId ?? entry.firestoreId),
                                          enabled: !jc.isSelectionMode,
                                          closeOnScroll: _prefCloseOnScroll,
                                          // Swipe left (start) to Delete (with confirmation)
                                          startActionPane: _prefSwipeDeleteEnabled
                                              ? ActionPane(
                                                  motion: _prefMotion == 'scroll' ? const ScrollMotion() : const StretchMotion(),
                                                  extentRatio: 0.24,
                                                  children: [
                                                    SlidableAction(
                                                      onPressed: (slidableContext) async {
                                                        final proceed = !_prefDeleteConfirmEnabled
                                                            ? true
                                                            : (await CustomDeleteDialog.show(
                                                                  rootContext,
                                                                  title: 'Delete Entry',
                                                                  message: 'Are you sure you want to delete this entry? This action cannot be undone.',
                                                                )) == true;
                                                        if (proceed) {
                                                          jc.removeEntryImmediate(entry);
                                                        } else {
                                                          Slidable.of(slidableContext)?.close();
                                                        }
                                                      },
                                                      backgroundColor: Colors.red,
                                                      foregroundColor: Colors.white,
                                                      icon: Icons.delete,
                                                      label: 'Delete',
                                                    ),
                                                  ],
                                                )
                                              : null,
                                          // Swipe right (end) to Edit (long-swipe trigger handled by listener)
                                          endActionPane: ActionPane(
                                            motion: _prefMotion == 'scroll' ? const ScrollMotion() : const StretchMotion(),
                                            extentRatio: 0.24,
                                            children: [
                                              SlidableAction(
                                                onPressed: (slidableContext) async {
                                                  final result = await Navigator.push<bool>(
                                                    rootContext,
                                                    MaterialPageRoute(
                                                      builder: (context) => EditEntryScreen(
                                                        entry: entry,
                                                        journalController: jc,
                                                      ),
                                                    ),
                                                  );
                                                  if (result == true) {
                                                    setState(() {});
                                                  }
                                                  Slidable.of(slidableContext)?.close();
                                                },
                                                backgroundColor: Colors.blueAccent,
                                                foregroundColor: Colors.white,
                                                icon: Icons.edit,
                                                label: 'Edit',
                                              ),
                                            ],
                                          ),
                                          child: SlidableOpenTrigger(
                                            onStartFullyOpen: _prefSwipeDeleteEnabled
                                                ? () async {
                                                    final proceed = !_prefDeleteConfirmEnabled
                                                        ? true
                                                        : (await CustomDeleteDialog.show(
                                                              rootContext,
                                                              title: 'Delete Entry',
                                                              message: 'Are you sure you want to delete this entry? This action cannot be undone.',
                                                            )) == true;
                                                    if (proceed) {
                                                      jc.removeEntryImmediate(entry);
                                                    }
                                                  }
                                                : null,
                                            onEndFullyOpen: () async {
                                              // Long-swipe right -> edit
                                              final result = await Navigator.push<bool>(
                                                rootContext,
                                                MaterialPageRoute(
                                                  builder: (context) => EditEntryScreen(
                                                    entry: entry,
                                                    journalController: jc,
                                                  ),
                                                ),
                                              );
                                              if (result == true) {
                                                setState(() {});
                                              }
                                            },
                                            child: JournalEntryWidget(
                                              key: ValueKey(entry.localId ?? entry.firestoreId),
                                              entry: entry,
                                              onTap: () async {
                                                Navigator.push(
                                                  rootContext,
                                                  MaterialPageRoute(
                                                    builder: (context) => EntryInsightScreen(
                                                      entry: entry,
                                                      journalController: jc,
                                                    ),
                                                  ),
                                                );
                                              },
                                              onToggleFavorite: jc.toggleFavorite,
                                              isSelectionMode: () => jc.isSelectionMode,
                                              onToggleSelection: () {
                                                setState(() => jc.toggleEntrySelection(entry));
                                              },
                                              searchTerm: _searchController.text,
                                              onInsight: () async {
                                                Navigator.push(
                                                  rootContext,
                                                  MaterialPageRoute(
                                                    builder: (context) => EntryInsightScreen(
                                                      entry: entry,
                                                      journalController: jc,
                                                    ),
                                                  ),
                                                );
                                              },
                                              onEdit: () async {
                                                final result = await Navigator.push<bool>(
                                                  rootContext,
                                                  MaterialPageRoute(
                                                    builder: (context) => EditEntryScreen(
                                                      entry: entry,
                                                      journalController: jc,
                                                    ),
                                                  ),
                                                );
                                                if (result == true) {
                                                  setState(() {});
                                                }
                                              },
                                              onDelete: () async {
                                                bool proceed = true;
                                                if (_prefDeleteConfirmEnabled) {
                                                  final confirm = await CustomDeleteDialog.show(
                                                  rootContext,
                                                  title: 'Delete Entry',
                                                  message: 'Are you sure you want to delete this entry? This action cannot be undone.',
                                                );
                                                proceed = confirm == true;
                                              }
                                              if (proceed) {
                                                jc.removeEntryImmediate(entry);
                                              }
                                              },
                                              onLongPress: () {
                                                setState(() => jc.toggleEntrySelection(entry));
                                              },
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                    childCount: entryGroup.value.length,
                                  ),
                                ),
                              );
                            }).toList(),
                    ),
                  ),
                ),
                //EdgeFade(top: false, background: background),
              ],
            ),
          ),
          GestureDetector(
            onVerticalDragUpdate: jc.handleDragUpdate,
            onVerticalDragEnd: (_) => jc.handleDragEnd(),
            child: JournalInputWidget(
              journalController: jc,
            ),
          ),
          Container(
            height: 1,
            width: double.infinity,
            color: background.withAlpha(24),
            alignment: Alignment.centerLeft,
            child: jc.isSavingEntry
                ? IndeterminateProgressBar(
                    color: Theme.of(context).hintColor,
                    height: 1.5,
                  )
                : FractionallySizedBox(
                    widthFactor: (-jc.dragOffsetY / JournalController.swipeThreshold).clamp(0.0, 1.0),
                    child: Container(
                      height: 1,
                      color: Theme.of(context).hintColor,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
