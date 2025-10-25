import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/entry.dart';
import '../controller/journal_controller.dart';
import '../services/deepseek_service.dart';
import '../widgets/indeterminate_progress_bar.dart';
import '../widgets/custom_image_viewer.dart';

class EntryInsightScreen extends StatefulWidget {
  final Entry entry;
  final JournalController journalController;

  const EntryInsightScreen({
    super.key, 
    required this.entry,
    required this.journalController,
  });

  @override
  State<EntryInsightScreen> createState() => _EntryInsightScreenState();
}

class _EntryInsightScreenState extends State<EntryInsightScreen> with TickerProviderStateMixin {
  late List<Entry> relatedEntries = [];
  bool isLoading = true;
  String _briefInsight = '';
  bool _loadingInsight = true;
  final DeepseekService _deepseekService = DeepseekService();

  // Static cache for insights and related entry IDs
  static final Map<String, String> _insightCache = {};
  static final Map<String, List<String>> _relatedIdsCache = {};

  // Persistent cache keys
  static const String _insightCacheKey = 'insight_cache';
  static const String _relatedIdsCacheKey = 'related_ids_cache';

  static bool _persistentCacheLoaded = false;

  // Loads persistent cache from SharedPreferences (call in initState)
  static Future<void> loadPersistentCache() async {
    if (_persistentCacheLoaded) return;
    final prefs = await SharedPreferences.getInstance();
    final insightMap = prefs.getString(_insightCacheKey);
    final relatedMap = prefs.getString(_relatedIdsCacheKey);
    if (insightMap != null) {
      final decoded = Map<String, dynamic>.from(await _decodeJson(insightMap));
      _insightCache.clear();
      decoded.forEach((k, v) => _insightCache[k] = v.toString());
    }
    if (relatedMap != null) {
      final decoded = Map<String, dynamic>.from(await _decodeJson(relatedMap));
      _relatedIdsCache.clear();
      decoded.forEach((k, v) {
        if (v is List) {
          _relatedIdsCache[k] = List<String>.from(v);
        } else if (v is String) {
          _relatedIdsCache[k] = [v];
        }
      });
    }
    _persistentCacheLoaded = true;
  }

  // Saves persistent cache to SharedPreferences
  static Future<void> savePersistentCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_insightCacheKey, _encodeJson(_insightCache));
    await prefs.setString(_relatedIdsCacheKey, _encodeJson(_relatedIdsCache));
  }

  // Helper for encoding/decoding JSON
  static String _encodeJson(Map map) => jsonEncode(map);
  static Future<Map<String, dynamic>> _decodeJson(String s) async {
    return s.isEmpty ? {} : Map<String, dynamic>.from(jsonDecode(s));
  }

  // For animated headers
  final ValueNotifier<int> _relatedDots = ValueNotifier<int>(0);
  final ValueNotifier<int> _insightDots = ValueNotifier<int>(0);
  bool _fetchingRelated = false;
  bool _generatingInsight = false;
  Timer? _relatedTimer;
  Timer? _insightTimer;
  final ScrollController _scrollController = ScrollController();

  // For cascading animation controllers
  final List<AnimationController> _cascadeControllers = [];
  final List<Animation<double>> _cascadeAnimations = [];

  @override
  void initState() {
    super.initState();
    _EntryInsightScreenState.loadPersistentCache().then((_) {
      _startPhasedLoading();
    });
  }

  @override
  void dispose() {
    _relatedTimer?.cancel();
    _insightTimer?.cancel();
    for (final c in _cascadeControllers) {
      c.dispose();
    }
    super.dispose();
  }
  void _showImageViewer(BuildContext context) {
    ImageProvider? imageProvider;
    String? heroTag;
    
    if (widget.entry.imageUrl != null && widget.entry.imageUrl!.isNotEmpty) {
      // Use network image for Firebase stored images
      imageProvider = CachedNetworkImageProvider(widget.entry.imageUrl!);
      heroTag = 'insight_image_${widget.entry.localId}_${widget.entry.imageUrl!}';
    } else if (widget.entry.localImagePath != null && widget.entry.localImagePath!.isNotEmpty) {
      // Use file image for local images
      imageProvider = FileImage(File(widget.entry.localImagePath!));
      heroTag = 'insight_image_${widget.entry.localId}_${widget.entry.localImagePath!}';
    }
    
    if (imageProvider != null) {
      showCustomImageViewer(
        context, 
        imageProvider,
        heroTag: heroTag,
      );
    }
  }

  Future<void> _startPhasedLoading({bool forceRefresh = false}) async {
    setState(() {
      isLoading = false;
      relatedEntries = [];
      _briefInsight = '';
      _loadingInsight = true;
      _fetchingRelated = true;
      _generatingInsight = false;
    });
    // Dispose old controllers
    for (final c in _cascadeControllers) {
      c.dispose();
    }
    _cascadeControllers.clear();
    _cascadeAnimations.clear();
    final entryId = widget.entry.localId;
    final allEntries = widget.journalController.entries;
    // --- Caching logic ---
    if (!forceRefresh && entryId != null && _insightCache.containsKey(entryId) && _relatedIdsCache.containsKey(entryId)) {
      // Use cached related entries
      final related = allEntries.where((e) => _relatedIdsCache[entryId]!.contains(e.localId)).toList();
      setState(() {
        relatedEntries = related;
        _briefInsight = _insightCache[entryId]!;
        _loadingInsight = false;
        _fetchingRelated = false;
        _generatingInsight = false;
      });
      // Re-initialize cascade animations for cached related entries
      for (int i = 0; i < related.length; i++) {
        _startCascadeAnimation(i);
      }
      // Scroll to bottom after build
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
      return;
    }
    // --- Animated header for related entries ---
    _relatedDots.value = 0;
    _relatedTimer?.cancel();
    _relatedTimer = Timer.periodic(const Duration(milliseconds: 400), (_) {
      if (_fetchingRelated) _relatedDots.value = (_relatedDots.value + 1) % 4;
    });
    // 2. List related entries one by one, with animation
    List<Entry> related = [];
    if (!forceRefresh && entryId != null && _relatedIdsCache.containsKey(entryId)) {
      for (final id in _relatedIdsCache[entryId]!) {
        final matches = allEntries.where((e) => e.localId == id);
        if (matches.isEmpty) continue;
        final match = matches.first;
        related.add(match);
        setState(() { relatedEntries = List.from(related); });
        _startCascadeAnimation(related.length - 1);
        await Future.delayed(const Duration(milliseconds: 120));
        _scrollToBottom();
      }
    } else {
      final fetched = await _deepseekService.fetchRelatedEntriesFromDeepseek(widget.entry, allEntries);
      for (final e in fetched) {
        related.add(e);
        setState(() { relatedEntries = List.from(related); });
        _startCascadeAnimation(related.length - 1);
        await Future.delayed(const Duration(milliseconds: 120));
        _scrollToBottom();
      }
      if (entryId != null) {        _relatedIdsCache[entryId] = related.map((e) => e.localId ?? '').where((id) => id.isNotEmpty).toList();
        await _EntryInsightScreenState.savePersistentCache();
      }
    }
    setState(() { _fetchingRelated = false; });
    _relatedTimer?.cancel();
    // 3. Show animated header before streaming insight
    setState(() { _briefInsight = ''; _loadingInsight = true; _generatingInsight = true; });
    _insightDots.value = 0;
    _insightTimer?.cancel();
    _insightTimer = Timer.periodic(const Duration(milliseconds: 400), (_) {
      if (_generatingInsight) _insightDots.value = (_insightDots.value + 1) % 4;
    });
    await Future.delayed(const Duration(milliseconds: 600));
    // 4. Stream insight generation
    await for (final chunk in _streamInsight(widget.entry, related)) {
      setState(() { _briefInsight += chunk; });
      _scrollToBottom(); // Always scroll on new chunk
      await Future.delayed(const Duration(milliseconds: 30));
    }
    setState(() { _loadingInsight = false; _generatingInsight = false; });
    _insightTimer?.cancel();
    if (entryId != null) {      _insightCache[entryId] = _briefInsight;
      await _EntryInsightScreenState.savePersistentCache();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // Use true streaming from DeepSeek
  Stream<String> _streamInsight(Entry entry, List<Entry> related) async* {
    await for (final chunk in _deepseekService.streamBriefInsight(entry, related)) {
      yield chunk;
    }
  }

  Future<void> _refresh() async {
    await _startPhasedLoading(forceRefresh: true);
  }

  void _startCascadeAnimation(int index) async {
    final controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    final animation = CurvedAnimation(parent: controller, curve: Curves.easeOutCubic);
    _cascadeControllers.add(controller);
    _cascadeAnimations.add(animation);
    // Staggered start for dramatic cascade
    await Future.delayed(Duration(milliseconds: 80 * index));
    controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final showCursor = _loadingInsight && _briefInsight.isNotEmpty;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Entry Insight'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: isLoading ? null : _refresh,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: isLoading
          ? Padding(
              padding: const EdgeInsets.only(top: 64.0),
              child: Center(
                child: IndeterminateProgressBar(color: theme.colorScheme.primary),
              ),
            )
          : SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMainEntryCard(theme),
                  const SizedBox(height: 24),
                  // Related Entries Section (cascading animated stack)
                  ValueListenableBuilder<int>(
                    valueListenable: _relatedDots,
                    builder: (context, dots, _) {
                      String header;
                      if (_fetchingRelated) {
                        header = 'Fetching related entries' + '.' * dots;
                      } else {
                        header = 'Related Entries';
                      }
                      return Text(header, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold));
                    },
                  ),
                  const SizedBox(height: 12),
                  relatedEntries.isEmpty
                      ? Text(_fetchingRelated ? '' : 'No related entries found', style: TextStyle(color: theme.hintColor))
                      : Column(
                          children: [
                            for (int i = 0; i < relatedEntries.length; i++)
                              if (i < _cascadeAnimations.length)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 8.0), // Added thin gap
                                  child: AnimatedBuilder(
                                    animation: _cascadeAnimations[i],
                                    builder: (context, child) {
                                      final anim = _cascadeAnimations[i].value;
                                      final double opacity = anim.clamp(0.0, 1.0);
                                      final double scale = 0.97 + 0.03 * anim;
                                      final double rotation = (1 - anim) * 0.04 * (i.isEven ? 1 : -1);
                                      final double shadowOpacity = 0.10 + 0.10 * anim;
                                      return Opacity(
                                        opacity: opacity,
                                        child: Transform.translate(
                                          offset: Offset(0, 0),
                                          child: Transform.rotate(
                                            angle: rotation,
                                            child: Transform.scale(
                                              scale: scale,
                                              child: _buildRelatedEntryCard(
                                                relatedEntries[i],
                                                theme,
                                                elevation: 10 + i * 2, 
                                                scale: 1.0, 
                                                rotation: 0.0,
                                                yOffset: 0,
                                                shadowOpacity: shadowOpacity,
                                                onTap: () { // FIXED onTap
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (context) => EntryInsightScreen(
                                                        entry: relatedEntries[i],
                                                        journalController: widget.journalController,
                                                      ),
                                                    ),
                                                  );
                                                },
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                            if (relatedEntries.isNotEmpty) const SizedBox(height: 4), // Keep or adjust based on visual preference
                          ],
                        ),
                  if (!_fetchingRelated) ...[
                    const SizedBox(height: 24),
                    // Insight Section
                    ValueListenableBuilder<int>(
                      valueListenable: _insightDots,
                      builder: (context, dots, _) {
                        String header;
                        if (_generatingInsight && _briefInsight.isEmpty) {
                          header = 'Generating insight' + '.' * dots;
                        } else {
                          header = 'Insight';
                        }
                        return Text(header, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold));
                      },
                    ),
                    const SizedBox(height: 8),                    Card(
                      elevation: 1,
                      color: theme.brightness == Brightness.light
                          ? theme.cardColor.withOpacity(0.8) // Lighter background for light mode
                          : theme.colorScheme.primary.withOpacity(0.05), // Keep dark mode styling
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: _briefInsight.isEmpty && _loadingInsight
                            ? const SizedBox(height: 24) // Empty space while waiting for stream
                            : Stack(
                                children: [
                                  MarkdownBody(
                                    data: _briefInsight,
                                    styleSheet: MarkdownStyleSheet(
                                      p: theme.textTheme.bodySmall?.copyWith(
                                        fontFamily: 'IBMPlexSans',
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                  if (showCursor)
                                    Positioned(
                                      left: _calculateCursorOffset(_briefInsight, theme),
                                      bottom: 8,
                                      child: _BlinkingCursor(),
                                    ),
                                ],
                              ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  // Helper to estimate cursor offset (optional, can be improved for perfect placement)
  double _calculateCursorOffset(String text, ThemeData theme) {
    // This is a rough estimate; for perfect placement, use a TextPainter
    final avgCharWidth = 8.0;
    return (text.length * avgCharWidth) % 400;
  }

  Widget _buildMainEntryCard(ThemeData theme) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date and metadata
            Row(
              children: [
                Text(
                  widget.entry.timestamp,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (widget.entry.mood != null && widget.entry.mood!.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Text(widget.entry.mood!, style: theme.textTheme.bodySmall),
                ],
                const Spacer(),
                Icon(
                  widget.entry.isFavorite ? Icons.bookmark : Icons.bookmark_outline,
                  color: widget.entry.isFavorite ? Colors.amber : theme.iconTheme.color,
                  size: 20,
                ),
              ],
            ),
            
            const SizedBox(height: 8),            // Image if exists
            if ((widget.entry.imageUrl != null && widget.entry.imageUrl!.isNotEmpty) ||
                (widget.entry.localImagePath != null && widget.entry.localImagePath!.isNotEmpty))
              GestureDetector(
                onTap: () => _showImageViewer(context),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxHeight: 240,
                      minWidth: double.infinity,
                    ),
                    child: Hero(
                      tag: widget.entry.imageUrl != null && widget.entry.imageUrl!.isNotEmpty
                          ? 'insight_image_${widget.entry.localId}_${widget.entry.imageUrl!}'
                          : 'insight_image_${widget.entry.localId}_${widget.entry.localImagePath!}',
                      child: widget.entry.imageUrl != null && widget.entry.imageUrl!.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: widget.entry.imageUrl!,
                              fit: BoxFit.cover,
                              placeholder: (context, url) {
                                final isDark = theme.brightness == Brightness.dark;
                                final baseColor = isDark ? Colors.grey[900]! : Colors.grey[200]!;
                                final highlightColor = isDark ? Colors.grey[850]! : Colors.grey[100]!;

                                return Shimmer.fromColors(
                                  baseColor: baseColor,
                                  highlightColor: highlightColor,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: baseColor,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                );
                              },
                              errorWidget: (context, url, error) => Icon(Icons.error),
                            )
                          : Image.file(
                              File(widget.entry.localImagePath!),
                              fit: BoxFit.cover,                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  height: 100,
                                  color: theme.colorScheme.surfaceVariant,
                                  child: Center(
                                    child: Icon(
                                      Icons.broken_image,
                                      color: theme.colorScheme.onSurfaceVariant,
                                      size: 40,
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ),
                ),
              ),
            
            if ((widget.entry.imageUrl != null && widget.entry.imageUrl!.isNotEmpty) ||
                (widget.entry.localImagePath != null && widget.entry.localImagePath!.isNotEmpty))
              const SizedBox(height: 12),
            
            // Entry text
            Text(
              widget.entry.text,
              style: theme.textTheme.bodyLarge,
            ),
            
            const SizedBox(height: 8),
            
            // Tags
            if (widget.entry.tags.isNotEmpty)
              Wrap(
                spacing: 6,
                children: widget.entry.tags.map((tag) {
                  return Chip(
                    label: Text(tag),
                    labelStyle: theme.textTheme.bodySmall,
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,                    backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }
  Widget _buildRelatedEntryCard(Entry entry, ThemeData theme, {double elevation = 8, double scale = 1.0, double rotation = 0.0, double yOffset = 0.0, double shadowOpacity = 0.18, VoidCallback? onTap}) {
    return Transform.translate(
      offset: Offset(0, yOffset),
      child: Transform.rotate(
        angle: rotation,
        child: Transform.scale(
          scale: scale,
          child: GestureDetector(
            onTap: onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 400), // Animation for any size changes
              curve: Curves.easeInOut,
              constraints: const BoxConstraints(
                minHeight: 100, // Ensure a minimum height
                // No maxHeight, allowing the card to grow with content
              ),
              child: Card(
                elevation: elevation,
                shadowColor: theme.shadowColor.withOpacity(shadowOpacity),
                margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(color: theme.colorScheme.primary.withOpacity(0.08), width: 1.0),
                ),
                color: theme.cardColor,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: onTap,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
                      child: SingleChildScrollView( // Allows scrolling for very long content
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min, // Key for wrapping content
                          children: [
                            Row(
                              children: [
                                Text(
                                  entry.timestamp,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.primary,                                  ),
                                ),
                                const Spacer(),
                                if (widget.entry.tags.any((tag) => entry.tags.contains(tag)))
                                  Icon(
                                    Icons.tag,
                                    size: 18,
                                    color: theme.colorScheme.primary.withOpacity(0.5),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            // Directly show full text, AnimatedCrossFade removed
                            Text(
                              entry.text,
                              style: theme.textTheme.bodyMedium?.copyWith(fontSize: 15, height: 1.35),
                            ),
                            if (entry.tags.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Wrap(
                                  spacing: 6,
                                  runSpacing: 4,
                                  children: entry.tags.map((tag) => Chip(
                                    visualDensity: VisualDensity.compact,
                                    label: Text(tag, style: theme.textTheme.bodySmall),
                                    backgroundColor: theme.colorScheme.primary.withOpacity(0.08),
                                    padding: const EdgeInsets.symmetric(horizontal: 6),
                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  )).toList(),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),      ),
    );
  }
}

class _BlinkingCursor extends StatefulWidget {
  @override
  State<_BlinkingCursor> createState() => _BlinkingCursorState();
}

class _BlinkingCursorState extends State<_BlinkingCursor> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: Text('|', style: TextStyle(fontSize: 16, fontFamily: 'IBMPlexSans', color: Theme.of(context).colorScheme.primary)),
    );
  }
}
