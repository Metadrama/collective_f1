import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:http/http.dart' as http;
import '../services/analytics_service.dart';
import '../controller/journal_controller.dart';
import '../models/entry.dart';
import '../utils/date_formatter.dart';

class AnalyticsInsightsPanel extends StatefulWidget {
  final TopicCluster topic;
  final JournalController journalController;

  const AnalyticsInsightsPanel({
    super.key,
    required this.topic,
    required this.journalController,
  });

  @override
  State<AnalyticsInsightsPanel> createState() => _AnalyticsInsightsPanelState();
}

class _AnalyticsInsightsPanelState extends State<AnalyticsInsightsPanel> {
  bool _isLoadingInsights = false;
  String _insights = '';
  String _streamingText = '';
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _generateInsights();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _generateInsights() async {
    if (_isLoadingInsights) return;
    
    setState(() {
      _isLoadingInsights = true;
      _streamingText = '';
      _insights = '';
    });

    try {
      await _streamInsightsFromAI();
    } catch (e) {
      debugPrint('Insights generation error: $e');
      setState(() {
        _insights = _generateFallbackInsights();
        _isLoadingInsights = false;
      });
    }
  }

  Future<void> _streamInsightsFromAI() async {
    const baseUrl = 'https://api.deepseek.com/chat/completions';
    const apiKey = 'sk-8f8b1b0a07ac425ea96a22e5c2f0b2bc';
    
    final prompt = _buildInsightsPrompt();
    
    try {
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': 'deepseek-chat',
          'messages': [
            {
              'role': 'system',
              'content': 'You are a thoughtful journaling assistant that provides insightful analysis of personal writing patterns. Focus on patterns, growth, and meaningful observations. Be supportive and encouraging. Include specific dates when relevant.'
            },
            {
              'role': 'user',
              'content': prompt
            }
          ],
          'max_tokens': 1500,
          'temperature': 0.7,
          'stream': false, // We'll simulate streaming for UX
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'] as String;
        
        // Simulate streaming for better UX
        await _simulateStreaming(content);
      } else {
        throw Exception('API request failed');
      }
    } catch (e) {
      debugPrint('AI streaming error: $e');
      final fallback = _generateFallbackInsights();
      await _simulateStreaming(fallback);
    }
  }

  Future<void> _simulateStreaming(String content) async {
    final words = content.split(' ');
    
    for (int i = 0; i < words.length; i++) {
      if (!mounted) break;
      
      setState(() {
        _streamingText = words.sublist(0, i + 1).join(' ');
      });
      
      // Scroll to bottom as text appears
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 100),
            curve: Curves.easeOut,
          );
        }
      });
      
      // Variable delay for natural feel
      final delay = i % 10 == 0 ? 50 : (i % 5 == 0 ? 30 : 15);
      await Future.delayed(Duration(milliseconds: delay));
    }
    
    setState(() {
      _insights = content;
      _isLoadingInsights = false;
    });
  }

  String _buildInsightsPrompt() {
    final entries = widget.topic.entries;
    final buffer = StringBuffer();
      buffer.writeln('Analyze these journal entries about "${widget.topic.name}" and provide meaningful insights in markdown format:');
    buffer.writeln('');
    buffer.writeln('Please format your response using markdown with:');
    buffer.writeln('- ## for main section headers');
    buffer.writeln('- ### for subsection headers');
    buffer.writeln('- **bold** for emphasis');
    buffer.writeln('- *italic* for subtle emphasis');
    buffer.writeln('- Bullet points for lists');
    buffer.writeln('');
    buffer.writeln('Focus on:');
    buffer.writeln('- Patterns and trends over time');
    buffer.writeln('- Growth and changes in perspective');
    buffer.writeln('- Emotional evolution');
    buffer.writeln('- Key moments or turning points');
    buffer.writeln('- Actionable insights for reflection');
    buffer.writeln('');
    buffer.writeln('Include specific dates when mentioning events (e.g., "In March 2024..." or "On April 15th...")');
    buffer.writeln('');
    buffer.writeln('Entries (${entries.length} total):');
    
    // Group entries by month for better context
    final monthlyEntries = <String, List<Entry>>{};
    for (final entry in entries) {
      final monthKey = DateFormatter.formatForGrouping(entry.rawDateTime);
      monthlyEntries.putIfAbsent(monthKey, () => []).add(entry);
    }
    
    // Include sample entries from different time periods
    int included = 0;
    for (final monthEntry in monthlyEntries.entries) {
      if (included >= 20) break; // Limit to avoid token overflow
      
      buffer.writeln('');
      buffer.writeln('${monthEntry.key}:');
      
      for (final entry in monthEntry.value.take(3)) {
        buffer.writeln('- ${entry.timestamp}: ${entry.text}');
        if (entry.mood != null && entry.mood!.isNotEmpty) {
          buffer.writeln('  Mood: ${entry.mood}');
        }
        included++;
        if (included >= 20) break;
      }
    }
    
    return buffer.toString();
  }

  String _generateFallbackInsights() {
    final entries = widget.topic.entries;
    final topicName = widget.topic.name;
    final timeSpan = widget.topic.lastEntryDate.difference(widget.topic.firstEntryDate).inDays;
    
    final buffer = StringBuffer();
      buffer.writeln('## Your Journey with $topicName');
    buffer.writeln('');
    
    buffer.writeln('Over the span of **${timeSpan > 365 ? '${(timeSpan / 365).round()} years' : '$timeSpan days'}**, you\'ve written **${entries.length} entries** about $topicName. This shows a meaningful connection to this topic in your life.');
    buffer.writeln('');
    
    // Find most active periods
    final monthlyCount = <String, int>{};
    for (final entry in entries) {
      final monthKey = '${entry.rawDateTime.month}/${entry.rawDateTime.year}';
      monthlyCount[monthKey] = (monthlyCount[monthKey] ?? 0) + 1;
    }
    
    final mostActiveMonth = monthlyCount.entries.reduce((a, b) => a.value > b.value ? a : b);
    final parts = mostActiveMonth.key.split('/');
    final monthNames = ['', 'January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    final monthName = monthNames[int.parse(parts[0])];
    
    buffer.writeln('### Key Insights');
    buffer.writeln('');
    buffer.writeln('- **Most active period**: $monthName ${parts[1]} with **${mostActiveMonth.value} entries**');
    buffer.writeln('- This suggests it was a particularly significant time for reflection on $topicName');
    buffer.writeln('');
    
    // Check for mood patterns if available
    final moodEntries = entries.where((e) => e.mood != null && e.mood!.isNotEmpty);
    if (moodEntries.isNotEmpty) {
      buffer.writeln('### Emotional Awareness');
      buffer.writeln('');
      buffer.writeln('You\'ve tracked various moods while writing about $topicName, showing *thoughtful self-awareness* and emotional intelligence.');
      buffer.writeln('');
    }
    
    buffer.writeln('### Reflection');
    buffer.writeln('');
    buffer.writeln('This collection represents an important aspect of your personal growth. Consider **revisiting these entries** to see how your perspective has evolved over time.');
    
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
      return Container(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [              Icon(
                Icons.lightbulb_outline,
                size: 18,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Insights & Patterns',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontFamily: 'IBM Plex Sans',
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              const Spacer(),
              if (_isLoadingInsights)                SizedBox(
                  width: 14,
                  height: 14,                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
                  ),
                ),
            ],
          ),
            const SizedBox(height: 12),
            // Insights content
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: theme.colorScheme.outline.withOpacity(0.2),
                  width: 0.5,
                ),
              ),
              child: _buildInsightsContent(theme),
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Entry list section
          _buildEntryList(theme),
        ],
      ),
    );
  }

  Widget _buildInsightsContent(ThemeData theme) {
    final displayText = _isLoadingInsights ? _streamingText : _insights;
    
    if (displayText.isEmpty && !_isLoadingInsights) {
      return Center(        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.auto_awesome_outlined,
              size: 32,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 8),
            Text(
              'Generating insights...',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontFamily: 'IBM Plex Sans',
                fontSize: 14,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }
      return SingleChildScrollView(
      controller: _scrollController,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [          // Use MarkdownBody for proper markdown rendering
          MarkdownBody(
            data: displayText,
            styleSheet: MarkdownStyleSheet(
              p: theme.textTheme.bodyMedium?.copyWith(
                fontFamily: 'IBM Plex Sans',
                fontSize: 14,
                height: 1.6,
                letterSpacing: 0.2,
              ),
              h1: theme.textTheme.titleLarge?.copyWith(
                fontFamily: 'IBM Plex Sans',
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
              h2: theme.textTheme.titleMedium?.copyWith(
                fontFamily: 'IBM Plex Sans',
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              h3: theme.textTheme.titleSmall?.copyWith(
                fontFamily: 'IBM Plex Sans',
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
              listBullet: theme.textTheme.bodyMedium?.copyWith(
                fontFamily: 'IBM Plex Sans',
                fontSize: 14,
              ),
              strong: theme.textTheme.bodyMedium?.copyWith(
                fontFamily: 'IBM Plex Sans',
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              em: theme.textTheme.bodyMedium?.copyWith(
                fontFamily: 'IBM Plex Sans',
                fontSize: 14,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
            // Typing indicator
          if (_isLoadingInsights && _streamingText.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Analyzing...',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEntryList(ThemeData theme) {
    return Container(
      height: 120,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [          Text(
            'Related Entries (${widget.topic.entries.length})',
            style: theme.textTheme.titleSmall?.copyWith(
              fontFamily: 'IBM Plex Sans',
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          
          const SizedBox(height: 8),
          
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: widget.topic.entries.length,
              itemBuilder: (context, index) {
                final entry = widget.topic.entries[index];
                return _buildEntryCard(theme, entry);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEntryCard(ThemeData theme, Entry entry) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _navigateToEntry(entry),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.cardColor.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: theme.dividerColor.withOpacity(0.2),
                width: 0.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [                Text(
                  DateFormatter.formatForGrouping(entry.rawDateTime),
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontFamily: 'IBM Plex Sans',
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                
                const SizedBox(height: 4),
                
                Expanded(
                  child:                  Text(
                    entry.text,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontFamily: 'IBM Plex Sans',
                      fontSize: 12,
                      height: 1.3,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                
                if (entry.mood != null && entry.mood!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      entry.mood!,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToEntry(Entry entry) {
    // Navigate back to the main journal screen and scroll to this entry
    Navigator.of(context).pop(); // Close analytics screen
    
    // TODO: We'll need to add a way to scroll to a specific entry in the main journal
    // This might require adding a method to JournalController
  }
}
