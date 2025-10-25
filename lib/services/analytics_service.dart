import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/entry.dart';
import '../services/api_key_service.dart'; // Import ApiKeyService

class AnalyticsProgress {
  final double progress;
  final String message;

  AnalyticsProgress({required this.progress, required this.message});
}

class TopicCluster {
  final String id;
  final String name;
  final String description;
  final List<Entry> entries;
  final double confidence;
  final String emoji;
  final DateTime firstEntryDate;
  final DateTime lastEntryDate;

  TopicCluster({
    required this.id,
    required this.name,
    required this.description,
    required this.entries,
    required this.confidence,
    required this.emoji,
    required this.firstEntryDate,
    required this.lastEntryDate,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'confidence': confidence,
      'emoji': emoji,
      'entryCount': entries.length,
      'firstEntryDate': firstEntryDate.toIso8601String(),
      'lastEntryDate': lastEntryDate.toIso8601String(),
    };
  }

  factory TopicCluster.fromJson(Map<String, dynamic> json, List<Entry> entries) {
    return TopicCluster(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      entries: entries,
      confidence: (json['confidence'] ?? 0.0).toDouble(),
      emoji: json['emoji'] ?? '📝',
      firstEntryDate: DateTime.parse(json['firstEntryDate']),
      lastEntryDate: DateTime.parse(json['lastEntryDate']),
    );
  }
}

class AnalyticsService {
  static const String _baseUrl = 'https://api.deepseek.com/chat/completions';
  final String _apiKey; // Make apiKey non-static and final

  List<TopicCluster> _topics = [];
  bool _isAnalyzing = false;

  final StreamController<AnalyticsProgress> _progressController = StreamController<AnalyticsProgress>.broadcast();
  Stream<AnalyticsProgress> get analysisProgress => _progressController.stream;

  List<TopicCluster> get topics => List.unmodifiable(_topics);
  bool get isAnalyzing => _isAnalyzing;

  // Constructor to initialize the API key
  AnalyticsService() : _apiKey = ApiKeyService.getDeepseekApiKey();

  Future<List<TopicCluster>> analyzeTopics(List<Entry> entries) async {
    if (_isAnalyzing) return _topics;

    _isAnalyzing = true;
    _topics.clear();

    try {
      _progressController.add(AnalyticsProgress(
        progress: 0.1,
        message: 'Analyzing ${entries.length} entries...'
      ));

      // Filter out very short or meaningless entries
      final meaningfulEntries = _filterMeaningfulEntries(entries);
      debugPrint('[AnalyticsService] Number of meaningful entries after filtering: \\${meaningfulEntries.length}');

      _progressController.add(AnalyticsProgress(
        progress: 0.3,
        message: 'Found ${meaningfulEntries.length} meaningful entries...'
      ));

      if (meaningfulEntries.length < 3) {
        debugPrint('[AnalyticsService] Not enough meaningful entries for analysis.');
        _isAnalyzing = false;
        return [];
      }

      // Extract topics using AI
      _progressController.add(AnalyticsProgress(
        progress: 0.6,
        message: 'Discovering topics and themes...'
      ));
      final topicData = await _extractTopicsWithAI(meaningfulEntries);
      debugPrint('[AnalyticsService] Topic data extracted: \\${topicData.length} topics');

      _progressController.add(AnalyticsProgress(
        progress: 0.8,
        message: 'Organizing entries by topics...'
      ));
      final topics = await _buildTopicClusters(topicData, meaningfulEntries);
      debugPrint('[AnalyticsService] Final topic clusters built: \\${topics.length}');

      _progressController.add(AnalyticsProgress(
        progress: 1.0,
        message: 'Analysis complete!'
      ));
      _topics = topics;

      return topics;
    } catch (e) {
      debugPrint('Analytics error: $e');
      rethrow;
    } finally {
      _isAnalyzing = false;
    }
  }

  List<Entry> _filterMeaningfulEntries(List<Entry> entries) {
    return entries.where((entry) {
      // Filter criteria
      final text = entry.text.trim();
      
      // Too short
      if (text.length < 10) return false;
      
      // Just random characters or numbers
      if (RegExp(r'^[0-9\s\.\-\+\*\/\=\(\)]+$').hasMatch(text)) return false;
      
      // Just URLs
      if (RegExp(r'^https?://\S+$').hasMatch(text)) return false;
      
      // Word count check
      final words = text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
      if (words.length < 3) return false;
      
      return true;
    }).toList();
  }

  Future<List<Map<String, dynamic>>> _extractTopicsWithAI(List<Entry> entries) async {
    try {
      final prompt = _buildTopicExtractionPrompt(entries);
      debugPrint('[AnalyticsService] AI Prompt: $prompt');

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey', // Use the instance variable _apiKey
        },
        body: jsonEncode({
          'model': 'deepseek-chat',
          'messages': [
            {
              'role': 'system',
              'content': 'You are an expert at analyzing journal entries and identifying meaningful topics and themes. You extract topics that would be useful for personal reflection and growth. Return only valid JSON.'
            },
            {
              'role': 'user',
              'content': prompt
            }
          ],
          'max_tokens': 2000,
          'temperature': 0.3,
        }),
      );

      debugPrint('[AnalyticsService] AI Response Status Code: ${response.statusCode}');
      debugPrint('[AnalyticsService] AI Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Add null checks and type checks for robustness
        if (data['choices'] != null && 
            data['choices'] is List && 
            (data['choices'] as List).isNotEmpty &&
            data['choices'][0]['message'] != null &&
            data['choices'][0]['message']['content'] != null) {
              
          final content = data['choices'][0]['message']['content'] as String;
          debugPrint('[AnalyticsService] AI Response Content: $content');
          
          // Clean and parse JSON
          final cleanContent = content.trim();
          final jsonStart = cleanContent.indexOf('[');
          final jsonEnd = cleanContent.lastIndexOf(']') + 1;
          
          if (jsonStart != -1 && jsonEnd > jsonStart) {
            final jsonString = cleanContent.substring(jsonStart, jsonEnd);
            debugPrint('[AnalyticsService] Extracted JSON String: $jsonString');
            try {
              final List<dynamic> topicsJson = jsonDecode(jsonString);
              return topicsJson.cast<Map<String, dynamic>>();
            } catch (e) {
              debugPrint('[AnalyticsService] JSON Parsing Error: $e');
            }
          } else {
            debugPrint('[AnalyticsService] Could not find valid JSON array in AI response content.');
          }
        } else {
          debugPrint('[AnalyticsService] AI response structure is not as expected.');
        }
      }
    } catch (e) {
      debugPrint('[AnalyticsService] AI topic extraction error: $e');
    }
    
    // Fallback: create topics based on keywords if AI fails
    debugPrint('[AnalyticsService] Falling back to keyword-based topic extraction.');
    return _createFallbackTopics(entries);
  }

  String _buildTopicExtractionPrompt(List<Entry> entries) {
    final buffer = StringBuffer();
    buffer.writeln('Analyze these journal entries and identify 3-7 meaningful topics that would be useful for personal reflection. Consider themes like relationships, work, personal growth, health, emotions, hobbies, etc.');
    buffer.writeln('');
    buffer.writeln('For each topic, provide:');
    buffer.writeln('- id: unique identifier (lowercase, underscore-separated)');
    buffer.writeln('- name: clear, concise topic name (2-4 words)');
    buffer.writeln('- description: brief explanation of what this topic covers');
    buffer.writeln('- emoji: single emoji that represents this topic');
    buffer.writeln('- keywords: array of keywords that help identify entries for this topic');
    buffer.writeln('');
    buffer.writeln('Return as JSON array. Example:');
    buffer.writeln('[{"id": "personal_growth", "name": "Personal Growth", "description": "Self-improvement and learning experiences", "emoji": "🌱", "keywords": ["learn", "growth", "improve", "goal"]}]');
    buffer.writeln('');
    buffer.writeln('Entries to analyze:');
    
    // Include a sample of entries for analysis
    final sampleSize = entries.length > 50 ? 50 : entries.length;
    for (int i = 0; i < sampleSize; i++) {
      final entry = entries[i];
      buffer.writeln('---');
      buffer.writeln('Date: ${entry.timestamp}');
      if (entry.mood != null && entry.mood!.isNotEmpty) {
        buffer.writeln('Mood: ${entry.mood}');
      }
      if (entry.tags.isNotEmpty) {
        buffer.writeln('Tags: ${entry.tags.join(", ")}');
      }
      buffer.writeln(entry.text);
    }
    
    return buffer.toString();
  }

  List<Map<String, dynamic>> _createFallbackTopics(List<Entry> entries) {
    // Simple keyword-based topic detection as fallback
    final Map<String, List<String>> topicKeywords = {
      'work_career': ['work', 'job', 'career', 'office', 'boss', 'meeting', 'project', 'deadline'],
      'relationships': ['friend', 'family', 'love', 'relationship', 'date', 'partner', 'marriage'],
      'emotions': ['happy', 'sad', 'angry', 'frustrated', 'excited', 'anxious', 'worried', 'stressed'],
      'health_fitness': ['health', 'exercise', 'gym', 'run', 'fitness', 'diet', 'sleep', 'medical'],
      'personal_growth': ['learn', 'growth', 'improve', 'goal', 'habit', 'change', 'development'],
    };
    
    final topics = <Map<String, dynamic>>[];
    
    for (final entry in topicKeywords.entries) {
      final topicId = entry.key;
      final keywords = entry.value;
      
      // Count how many entries mention these keywords
      final matchingEntries = entries.where((entry) {
        final text = entry.text.toLowerCase();
        return keywords.any((keyword) => text.contains(keyword));
      }).toList();
      
      if (matchingEntries.length >= 2) {
        final topicInfo = _getTopicInfo(topicId);
        topics.add({
          'id': topicId,
          'name': topicInfo['name'],
          'description': topicInfo['description'],
          'emoji': topicInfo['emoji'],
          'keywords': keywords,
        });
      }
    }
    
    return topics;
  }

  Map<String, String> _getTopicInfo(String topicId) {
    final topicMap = {
      'work_career': {
        'name': 'Work & Career',
        'description': 'Professional life and career development',
        'emoji': '💼',
      },
      'relationships': {
        'name': 'Relationships',
        'description': 'Connections with family, friends, and partners',
        'emoji': '❤️',
      },
      'emotions': {
        'name': 'Emotions',
        'description': 'Feelings and emotional experiences',
        'emoji': '🎭',
      },
      'health_fitness': {
        'name': 'Health & Fitness',
        'description': 'Physical and mental wellness',
        'emoji': '🏃‍♂️',
      },
      'personal_growth': {
        'name': 'Personal Growth',
        'description': 'Self-improvement and learning',
        'emoji': '🌱',
      },
    };
    
    return topicMap[topicId] ?? {
      'name': 'General',
      'description': 'General thoughts and experiences',
      'emoji': '📝',
    };
  }

  Future<List<TopicCluster>> _buildTopicClusters(
    List<Map<String, dynamic>> topicData,
    List<Entry> entries,
  ) async {
    final clusters = <TopicCluster>[];
    
    for (final topicJson in topicData) {
      final keywords = List<String>.from(topicJson['keywords'] ?? []);
      
      // Find entries that match this topic
      final matchingEntries = entries.where((entry) {
        final text = entry.text.toLowerCase();
        final entryTags = entry.tags.map((t) => t.toLowerCase()).toList();
        
        // Check if entry text or tags contain topic keywords
        return keywords.any((keyword) => 
          text.contains(keyword.toLowerCase()) || 
          entryTags.any((tag) => tag.contains(keyword.toLowerCase()))
        );
      }).toList();
      
      if (matchingEntries.isNotEmpty) {
        // Sort entries by date
        matchingEntries.sort((a, b) => a.rawDateTime.compareTo(b.rawDateTime));
        
        final cluster = TopicCluster(
          id: topicJson['id'] ?? '',
          name: topicJson['name'] ?? 'Untitled Topic',
          description: topicJson['description'] ?? '',
          entries: matchingEntries,
          confidence: _calculateConfidence(matchingEntries, keywords),
          emoji: topicJson['emoji'] ?? '📝',
          firstEntryDate: matchingEntries.first.rawDateTime,
          lastEntryDate: matchingEntries.last.rawDateTime,
        );
        
        clusters.add(cluster);
      }
    }
    
    // Sort clusters by entry count (most entries first)
    clusters.sort((a, b) => b.entries.length.compareTo(a.entries.length));
    
    return clusters;
  }

  double _calculateConfidence(List<Entry> entries, List<String> keywords) {
    if (entries.isEmpty) return 0.0;
    
    final totalWords = entries.fold<int>(0, (sum, entry) {
      return sum + entry.text.split(RegExp(r'\s+')).length;
    });
    
    final keywordMatches = entries.fold<int>(0, (sum, entry) {
      final text = entry.text.toLowerCase();
      return sum + keywords.where((keyword) => text.contains(keyword)).length;
    });
    
    final confidence = (keywordMatches / (totalWords / 100)).clamp(0.0, 1.0);
    return confidence;
  }

  Future<List<TopicCluster>> getTopics() async {
    return List.unmodifiable(_topics);
  }

  TopicCluster? getTopicById(String id) {
    try {
      return _topics.firstWhere((topic) => topic.id == id);
    } catch (e) {
      return null;
    }
  }

  void clearAnalysis() {
    _topics.clear();
    _isAnalyzing = false;
  }
}
