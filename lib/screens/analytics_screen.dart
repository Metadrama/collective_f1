import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../controller/journal_controller.dart';
import '../models/entry.dart';
import '../services/analytics_service.dart';
import '../utils/system_ui_helper.dart';
import '../widgets/analytics_topic_card.dart';
import '../widgets/analytics_calendar_view.dart';
import '../widgets/analytics_insights_panel.dart';

class AnalyticsScreen extends StatefulWidget {
  final JournalController journalController;

  const AnalyticsScreen({super.key, required this.journalController});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen>
    with TickerProviderStateMixin {
  late final AnalyticsService _analyticsService;
  
  bool _isAnalyzing = false;
  bool _hasAnalyzed = false;
  String _analysisProgress = '';
  List<TopicCluster> _topics = [];
  TopicCluster? _selectedTopic;
  
  late AnimationController _fadeController;
  late AnimationController _slideController;

  // Static cache for analytics data
  static final Map<String, List<Map<String, dynamic>>> _topicsCache = {};
  static final Map<String, DateTime> _cacheTimestamps = {};
  
  // Persistent cache keys
  static const String _topicsCacheKey = 'analytics_topics_cache';
  static const String _cacheTimestampsKey = 'analytics_cache_timestamps';
  static const Duration _cacheExpiry = Duration(hours: 6); // Cache for 6 hours
  
  static bool _persistentCacheLoaded = false;

  @override
  void initState() {
    super.initState();
    _analyticsService = AnalyticsService();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    // Load persistent cache and start analysis
    _AnalyticsScreenState.loadPersistentCache().then((_) {
      _startAnalysis();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  // Loads persistent cache from SharedPreferences
  static Future<void> loadPersistentCache() async {
    if (_persistentCacheLoaded) return;
    final prefs = await SharedPreferences.getInstance();
    final topicsMap = prefs.getString(_topicsCacheKey);
    final timestampsMap = prefs.getString(_cacheTimestampsKey);
    
    if (topicsMap != null) {
      final decoded = Map<String, dynamic>.from(await _decodeJson(topicsMap));
      _topicsCache.clear();
      decoded.forEach((k, v) {
        if (v is List) {
          _topicsCache[k] = List<Map<String, dynamic>>.from(v);
        }
      });
    }
    
    if (timestampsMap != null) {
      final decoded = Map<String, dynamic>.from(await _decodeJson(timestampsMap));
      _cacheTimestamps.clear();
      decoded.forEach((k, v) {
        if (v is String) {
          try {
            _cacheTimestamps[k] = DateTime.parse(v);
          } catch (e) {
            // Invalid timestamp, ignore
          }
        }
      });
    }
    
    _persistentCacheLoaded = true;
  }

  // Saves persistent cache to SharedPreferences
  static Future<void> savePersistentCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_topicsCacheKey, _encodeJson(_topicsCache));
    
    // Convert timestamps to strings for storage
    final timestampsForStorage = <String, String>{};
    _cacheTimestamps.forEach((k, v) {
      timestampsForStorage[k] = v.toIso8601String();
    });
    await prefs.setString(_cacheTimestampsKey, _encodeJson(timestampsForStorage));
  }

  // Helper for encoding/decoding JSON
  static String _encodeJson(Map map) => jsonEncode(map);
  static Future<Map<String, dynamic>> _decodeJson(String s) async {
    return s.isEmpty ? {} : Map<String, dynamic>.from(jsonDecode(s));
  }

  // Clears all persistent cache data
  static Future<void> clearPersistentCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_topicsCacheKey);
    await prefs.remove(_cacheTimestampsKey);
    _topicsCache.clear();
    _cacheTimestamps.clear();
    _persistentCacheLoaded = false;
  }

  Future<void> _startAnalysis({bool forceRefresh = false}) async {
    if (_isAnalyzing) return;
    setState(() {
      _isAnalyzing = true;
      _hasAnalyzed = false;
      _analysisProgress = 'Preparing your journey insights...';
    });

    try {
      // Get all entries for analysis
      final entries = widget.journalController.entries;
      debugPrint('[AnalyticsScreen] Number of entries received: ${entries.length}');

      if (entries.isEmpty) {
        setState(() {
          _isAnalyzing = false;
          _hasAnalyzed = true;
          _analysisProgress = 'No entries found to analyze';
        });
        return;
      }

      // Create a cache key based on entry count and latest entry timestamp
      final cacheKey = _generateCacheKey(entries);
      
      // Check if we have valid cached data
      if (!forceRefresh && _topicsCache.containsKey(cacheKey) && _cacheTimestamps.containsKey(cacheKey)) {
        final cacheTime = _cacheTimestamps[cacheKey]!;
        final now = DateTime.now();
        
        if (now.difference(cacheTime) < _cacheExpiry) {
          // Use cached data
          setState(() {
            _analysisProgress = 'Loading cached insights...';
          });
          
          await Future.delayed(const Duration(milliseconds: 500)); // Brief loading animation
          
          final cachedTopicsData = _topicsCache[cacheKey]!;
          final topics = _reconstructTopicsFromCache(cachedTopicsData, entries);
          
          setState(() {
            _topics = topics;
            _isAnalyzing = false;
            _hasAnalyzed = true;
          });

          // Animate in the results
          _fadeController.forward();
          return;
        }
      }

      // Start the analysis with progress updates
      _analyticsService.analysisProgress.listen((progress) {
        if (mounted) {
          setState(() {
            _analysisProgress = progress.message;
          });
        }
      });

      final topics = await _analyticsService.analyzeTopics(entries);
      debugPrint('[AnalyticsScreen] Number of topics returned: ${topics.length}');

      // Cache the results
      final topicsData = _serializeTopicsForCache(topics);
      _topicsCache[cacheKey] = topicsData;
      _cacheTimestamps[cacheKey] = DateTime.now();
      await _AnalyticsScreenState.savePersistentCache();

      setState(() {
        _topics = topics;
        _isAnalyzing = false;
        _hasAnalyzed = true;
      });

      // Animate in the results
      _fadeController.forward();

    } catch (e) {
      debugPrint('Analytics error: $e');
      setState(() {
        _isAnalyzing = false;
        _hasAnalyzed = true;
        _analysisProgress = 'Analysis failed. Please try again.';
      });
    }
  }

  String _generateCacheKey(List<Entry> entries) {
    if (entries.isEmpty) return 'empty';
    
    // Sort entries by timestamp to ensure consistent key generation
    final sortedEntries = List<Entry>.from(entries);
    sortedEntries.sort((a, b) => a.rawDateTime.compareTo(b.rawDateTime));
    
    // Use entry count and latest timestamp as key components
    final entryCount = entries.length;
    final latestTimestamp = sortedEntries.last.rawDateTime.millisecondsSinceEpoch;
    
    return 'analytics_${entryCount}_$latestTimestamp';
  }

  List<Map<String, dynamic>> _serializeTopicsForCache(List<TopicCluster> topics) {
    return topics.map((topic) {
      return {
        'id': topic.id,
        'name': topic.name,
        'description': topic.description,
        'confidence': topic.confidence,
        'emoji': topic.emoji,
        'firstEntryDate': topic.firstEntryDate.toIso8601String(),
        'lastEntryDate': topic.lastEntryDate.toIso8601String(),
        'entryIds': topic.entries.map((e) => e.localId).where((id) => id != null).toList(),
      };
    }).toList();
  }

  List<TopicCluster> _reconstructTopicsFromCache(List<Map<String, dynamic>> cachedData, List<Entry> allEntries) {
    return cachedData.map((topicData) {
      // Find entries that belong to this topic
      final entryIds = List<String>.from(topicData['entryIds'] ?? []);
      final topicEntries = allEntries.where((entry) => 
        entry.localId != null && entryIds.contains(entry.localId)
      ).toList();
      
      return TopicCluster(
        id: topicData['id'] ?? '',
        name: topicData['name'] ?? '',
        description: topicData['description'] ?? '',
        entries: topicEntries,
        confidence: (topicData['confidence'] ?? 0.0).toDouble(),
        emoji: topicData['emoji'] ?? '📝',
        firstEntryDate: DateTime.parse(topicData['firstEntryDate']),
        lastEntryDate: DateTime.parse(topicData['lastEntryDate']),
      );
    }).toList();
  }

  void _selectTopic(TopicCluster topic) {
    setState(() {
      _selectedTopic = topic;
    });
    _slideController.forward();
  }

  void _goBackToTopics() {
    _slideController.reverse().then((_) {
      setState(() {
        _selectedTopic = null;
      });
    });
  }

  Future<void> _refresh() async {
    await _startAnalysis(forceRefresh: true);
  }

  @override
  Widget build(BuildContext context) {
    updateSystemUiOverlay(context);
    final theme = Theme.of(context);
    final background = theme.scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(theme),
            
            // Content
            Expanded(
              child: _buildContent(theme),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, 
              size: 22, 
              color: theme.iconTheme.color,
            ),
            onPressed: () => Navigator.of(context).pop(),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _selectedTopic != null ? _selectedTopic!.name : 'Journey Analytics',
              style: theme.textTheme.titleLarge?.copyWith(
                fontFamily: 'IBM Plex Sans',
                fontWeight: FontWeight.w600,
                fontSize: 20,
                color: theme.brightness == Brightness.dark ? Colors.white : Colors.black,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (_selectedTopic != null)
            IconButton(
              icon: Icon(Icons.close, 
                size: 20, 
                color: theme.iconTheme.color,
              ),
              onPressed: _goBackToTopics,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          if (_selectedTopic == null && _hasAnalyzed)
            IconButton(
              icon: Icon(Icons.refresh, 
                size: 20, 
                color: theme.iconTheme.color,
              ),
              onPressed: _refresh,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }

  Widget _buildContent(ThemeData theme) {
    if (_isAnalyzing) {
      return _buildAnalyzingState(theme);
    }
    
    if (!_hasAnalyzed || _topics.isEmpty) {
      return _buildEmptyState(theme);
    }

    if (_selectedTopic != null) {
      return _buildTopicDetailView(theme);
    }
    
    return _buildTopicsOverview(theme);
  }
  Widget _buildAnalyzingState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: theme.primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(theme.primaryColor),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Analyzing Your Journey',
            style: theme.textTheme.titleLarge?.copyWith(
              fontFamily: 'IBM Plex Sans',
              fontWeight: FontWeight.w600,
              fontSize: 18,
              color: theme.brightness == Brightness.dark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              _analysisProgress,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontFamily: 'IBM Plex Sans',
                fontSize: 14,
                color: theme.brightness == Brightness.dark 
                  ? Colors.white.withOpacity(0.7) 
                  : Colors.black.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.analytics_outlined,
            size: 56,
            color: theme.brightness == Brightness.dark 
              ? Colors.white.withOpacity(0.5)
              : Colors.black.withOpacity(0.4),
          ),
          const SizedBox(height: 20),
          Text(
            'No Insights Yet',
            style: theme.textTheme.titleLarge?.copyWith(
              fontFamily: 'IBM Plex Sans',
              fontWeight: FontWeight.w600,
              fontSize: 18,
              color: theme.brightness == Brightness.dark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Start journaling to discover patterns and insights in your thoughts.',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontFamily: 'IBM Plex Sans',
                fontSize: 14,
                color: theme.brightness == Brightness.dark 
                  ? Colors.white.withOpacity(0.7) 
                  : Colors.black.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildTopicsOverview(ThemeData theme) {
    return FadeTransition(
      opacity: _fadeController,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'You have ${_topics.length} ${_topics.length == 1 ? 'topic' : 'topics'} to reflect on',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontFamily: 'IBM Plex Sans',
                    fontSize: 16,
                    color: theme.brightness == Brightness.dark ? Colors.white : Colors.black,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tap a topic to explore your journey',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontFamily: 'IBM Plex Sans',
                    fontSize: 14,
                    color: theme.brightness == Brightness.dark 
                      ? Colors.white.withOpacity(0.7) 
                      : Colors.black.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _topics.length,
              itemBuilder: (context, index) {
                final topic = _topics[index];
                return TweenAnimationBuilder<double>(
                  duration: Duration(milliseconds: 350 + (index * 80)),
                  tween: Tween(begin: 0.0, end: 1.0),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return Transform.translate(
                      offset: Offset(0, 15 * (1 - value)),
                      child: Opacity(
                        opacity: value,
                        child: child,
                      ),
                    );
                  },
                  child: AnalyticsTopicCard(
                    topic: topic,
                    onTap: () => _selectTopic(topic),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopicDetailView(ThemeData theme) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(1.0, 0.0),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _slideController,
        curve: Curves.easeOutCubic,
      )),
      child: Column(
        children: [
          // Calendar View
          Expanded(
            flex: 2,
            child: AnalyticsCalendarView(
              topic: _selectedTopic!,
              journalController: widget.journalController,
            ),
          ),
          
          // Insights Panel
          Expanded(
            flex: 3,
            child: AnalyticsInsightsPanel(
              topic: _selectedTopic!,
              journalController: widget.journalController,
            ),
          ),
        ],
      ),
    );
  }
}
