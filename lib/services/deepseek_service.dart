import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/entry.dart';
import '../services/api_key_service.dart';

/// Service for interacting with DeepSeek API to generate intelligent insights
/// about journal entries
class DeepseekService {
  final String _apiKey;
  final String _baseUrl = 'https://api.deepseek.com/v1';

  /// Create a new DeepseekService instance
  DeepseekService() : _apiKey = ApiKeyService.getDeepseekApiKey();

  /// Analyze the contextual relationship between entries (legacy)
  @deprecated
  Future<String> analyzeEntryContext(Entry mainEntry, List<Entry> relatedEntries) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'deepseek-chat',
          'messages': [
            {
              'role': 'system',
              'content': 'You are an intelligent journaling assistant that helps analyze journal '
                  'entries. Your task is to provide a brief contextual analysis of how a main '
                  'journal entry relates to other entries. Be concise, insightful, and helpful. '
                  'Focus on themes, emotional patterns, and narrative continuity.'
            },
            {
              'role': 'user',
              'content': _formatEntriesForAnalysis(mainEntry, relatedEntries)
            }
          ],
          'max_tokens': 500,
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'];
      } else {
        debugPrint('DeepSeek API error: ${response.statusCode}, ${response.body}');
        return _generateFallbackEntryContext(mainEntry, relatedEntries);
      }
    } catch (e) {
      debugPrint('Failed to connect to DeepSeek API: $e');
      return _generateFallbackEntryContext(mainEntry, relatedEntries);
    }
  }

  /// Generate overall insights across multiple entries (legacy)
  @deprecated
  Future<String> generateOverallInsights(Entry mainEntry, List<Entry> relatedEntries) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'deepseek-chat',
          'messages': [
            {
              'role': 'system',
              'content': 'You are an intelligent journaling assistant that helps users gain '
                  'insights from their journal entries. Your task is to analyze patterns across '
                  'multiple related entries and provide helpful observations about themes, '
                  'emotional patterns, potential growth opportunities, and recurring topics. '
                  'Be concise, thoughtful, and avoid generic responses.'
            },
            {
              'role': 'user',
              'content': _formatEntriesForOverallInsight(mainEntry, relatedEntries)
            }
          ],
          'max_tokens': 800,
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'];
      } else {
        debugPrint('DeepSeek API error: ${response.statusCode}, ${response.body}');
        return _generateFallbackOverallInsights(mainEntry, relatedEntries);
      }
    } catch (e) {
      debugPrint('Failed to connect to DeepSeek API: $e');
      return _generateFallbackOverallInsights(mainEntry, relatedEntries);
    }
  }

  /// Fetch related entries for a main entry using Deepseek API (context-aware, improved)
  Future<List<Entry>> fetchRelatedEntriesFromDeepseek(Entry mainEntry, List<Entry> allEntries) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'deepseek-chat',
          'messages': [
            {
              'role': 'system',
              'content':
                  'You are an intelligent journaling assistant. Given a main journal entry and a list of other entries, select the 3-5 most contextually relevant related entries. Consider not just superficial similarity (tags, date, or word overlap), but also emotional tone, narrative continuity, and deeper themes. Use the provided metadata (mood, tags, date) for each entry. Avoid picking entries that are only superficially similar. Return only their localId as a JSON array.'
            },
            {
              'role': 'user',
              'content': _formatMainAndAllEntriesForRelatedContextAware(mainEntry, allEntries)
            }
          ],
          'max_tokens': 200,
          'temperature': 0.2,
        }),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        var content = data['choices'][0]['message']['content'] as String;
        // Remove code block markers if present
        content = content.trim();
        if (content.startsWith('```')) {
          final firstNewline = content.indexOf('\n');
          if (firstNewline != -1) {
            content = content.substring(firstNewline + 1);
          }
          if (content.endsWith('```')) {
            content = content.substring(0, content.length - 3);
          }
          content = content.trim();
        }
        // Now parse as JSON array
        final List<dynamic> idList = jsonDecode(content);
        // Post-process: filter for minimum content/metadata overlap and context relevance
        final List<Entry> candidates = allEntries.where((e) => idList.contains(e.localId)).toList();
        final List<Entry> filtered = _filterContextuallyRelevantEntries(mainEntry, candidates);
        // If not enough, fallback to original candidates
        return filtered.length >= 3 ? filtered : candidates;
      } else {
        debugPrint('DeepSeek API error (related): \\${response.statusCode}, \\${response.body}');
        // fallback: use local heuristics (old method)
        return _findRelatedLocally(mainEntry, allEntries);
      }
    } catch (e) {
      debugPrint('Failed to connect to DeepSeek API (related): $e');
      return _findRelatedLocally(mainEntry, allEntries);
    }
  }

  /// Generate a brief insight for the main entry and its related entries (concise prompt)
  Future<String> generateBriefInsight(Entry mainEntry, List<Entry> relatedEntries) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'deepseek-chat',
          'messages': [
            {
              'role': 'system',
              'content': 'You are a journaling assistant. Given a main entry and a few related entries, write a single concise paragraph summarizing the main entry in the context of the related entries. Be specific, avoid generic advice.'
            },
            {
              'role': 'user',
              'content': _formatMainAndRelatedForInsight(mainEntry, relatedEntries)
            }
          ],
          'max_tokens': 180,
          'temperature': 0.5,
        }),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'];
      } else {
        debugPrint('DeepSeek API error (insight): \\${response.statusCode}, \\${response.body}');
        return _generateFallbackEntryContext(mainEntry, relatedEntries);
      }
    } catch (e) {
      debugPrint('Failed to connect to DeepSeek API (insight): $e');
      return _generateFallbackEntryContext(mainEntry, relatedEntries);
    }
  }

  /// Stream a brief insight for the main entry and its related entries (true streaming)
  Stream<String> streamBriefInsight(Entry mainEntry, List<Entry> relatedEntries) async* {
    final client = http.Client();
    final request = http.Request(
      'POST',
      Uri.parse('$_baseUrl/chat/completions'),
    );
    request.headers.addAll({
      'Authorization': 'Bearer $_apiKey',
      'Content-Type': 'application/json',
    });
    request.body = jsonEncode({
      'model': 'deepseek-chat',
      'stream': true,
      'messages': [
        {
          'role': 'system',
          'content': 'You are a journaling assistant. Given a main entry and a few related entries, write a single concise paragraph summarizing the main entry in the context of the related entries. Be specific, avoid generic advice.'
        },
        {
          'role': 'user',
          'content': _formatMainAndRelatedForInsight(mainEntry, relatedEntries)
        }
      ],
      'max_tokens': 180,
      'temperature': 0.5,
    });
    try {
      final response = await client.send(request);
      await for (final line in response.stream.transform(utf8.decoder).transform(const LineSplitter())) {
        if (line.startsWith('data: ')) {
          final data = line.substring(6).trim();
          if (data == '[DONE]') break;
          final jsonChunk = jsonDecode(data);
          final delta = jsonChunk['choices'][0]['delta'];
          if (delta != null && delta['content'] != null) {
            yield delta['content'];
          }
        }
      }
    } catch (e) {
      debugPrint('DeepSeek streaming error: $e');
      // fallback: yield the whole thing at once
      final fallback = await generateBriefInsight(mainEntry, relatedEntries);
      yield fallback;
    } finally {
      client.close();
    }
  }

  /// Generate intelligent tag suggestions based on journal entry text
  Future<List<String>> suggestTags(String text, List<String> existingTags) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'deepseek-chat',
          'messages': [
            {
              'role': 'system',
              'content': 'You are an intelligent journaling assistant that suggests relevant tags for journal entries. '
                  'Analyze the provided text and suggest 3-5 concise, meaningful tags that capture the key themes, emotions, activities, or topics. '
                  'Tags should be single words or short phrases, lowercase, and prefixed with #. '
                  'Focus on: emotions, activities, people, places, themes, goals, or topics mentioned. '
                  'Avoid generic words like "the", "and", etc. Be specific and meaningful. '
                  'Return only the tags, one per line, no additional text.'
            },
            {
              'role': 'user',
              'content': 'Text: "$text"\n\nExisting tags to consider for context: ${existingTags.join(", ")}\n\nSuggest relevant tags:'
            }
          ],
          'max_tokens': 100,
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'] as String;
        
        // Parse the response to extract tags
        final suggestedTags = content
            .split('\n')
            .map((line) => line.trim())
            .where((line) => line.isNotEmpty && line.startsWith('#'))
            .map((tag) => tag.toLowerCase())
            .take(5)
            .toList();
        
        return suggestedTags;
      } else {
        debugPrint('DeepSeek API error for tag suggestions: ${response.statusCode}, ${response.body}');
        return [];
      }
    } catch (e) {
      debugPrint('Error getting tag suggestions: $e');
      return [];
    }
  }

  /// Format entries for analyzing contextual relationship (legacy)
  @deprecated
  String _formatEntriesForAnalysis(Entry mainEntry, List<Entry> relatedEntries) {
    final buffer = StringBuffer();

    buffer.writeln('Main Entry (Date: ${mainEntry.timestamp}):');
    buffer.writeln('${mainEntry.text}');
    
    if (mainEntry.mood != null && mainEntry.mood!.isNotEmpty) {
      buffer.writeln('Mood: ${mainEntry.mood}');
    }
    
    if (mainEntry.tags.isNotEmpty) {
      buffer.writeln('Tags: ${mainEntry.tags.join(', ')}');
    }
    
    buffer.writeln('\nRelated Entries:');
    
    for (var entry in relatedEntries) {
      buffer.writeln('Date: ${entry.timestamp}');
      buffer.writeln('${entry.text}');
      
      if (entry.mood != null && entry.mood!.isNotEmpty) {
        buffer.writeln('Mood: ${entry.mood}');
      }
      
      if (entry.tags.isNotEmpty) {
        buffer.writeln('Tags: ${entry.tags.join(', ')}');
      }
      
      buffer.writeln('---');
    }
    
    buffer.writeln('\nPlease provide a brief contextual analysis of how the main entry relates to the related entries. '
        'Focus on themes, emotional patterns, and narrative continuity. Keep it concise (2-3 paragraphs max).');
    
    return buffer.toString();
  }

  /// Format entries for overall insights analysis (legacy)
  @deprecated
  String _formatEntriesForOverallInsight(Entry mainEntry, List<Entry> relatedEntries) {
    final buffer = StringBuffer();
    final allEntries = [mainEntry, ...relatedEntries];
    
    buffer.writeln('Journal Entry Analysis:');
    buffer.writeln('Please analyze the following journal entries and provide insights on themes, patterns, and development.');
    
    for (var entry in allEntries) {
      buffer.writeln('\nDate: ${entry.timestamp}');
      buffer.writeln('${entry.text}');
      
      if (entry.mood != null && entry.mood!.isNotEmpty) {
        buffer.writeln('Mood: ${entry.mood}');
      }
      
      if (entry.tags.isNotEmpty) {
        buffer.writeln('Tags: ${entry.tags.join(', ')}');
      }
      
      buffer.writeln('---');
    }
    
    buffer.writeln('\nPlease provide 3-4 insightful observations about:');
    buffer.writeln('1. Recurring themes or topics');
    buffer.writeln('2. Emotional patterns or development');
    buffer.writeln('3. Potential growth opportunities or areas of focus');
    buffer.writeln('4. Any other notable patterns or connections between these entries');
    
    return buffer.toString();
  }

  /// Helper: format for related entries selection (context-aware, with metadata)
  String _formatMainAndAllEntriesForRelatedContextAware(Entry main, List<Entry> all) {
    final buffer = StringBuffer();
    buffer.writeln('Main Entry:');
    buffer.writeln('ID: \\${main.localId}');
    buffer.writeln('Date: \\${main.timestamp}');
    if (main.mood != null && main.mood!.isNotEmpty) buffer.writeln('Mood: \\${main.mood}');
    if (main.tags.isNotEmpty) buffer.writeln('Tags: \\${main.tags.join(", ")}');
    buffer.writeln(main.text);
    buffer.writeln('---');
    buffer.writeln('Other Entries:');
    for (final e in all) {
      if (e.localId == main.localId) continue;
      buffer.writeln('ID: \\${e.localId}');
      buffer.writeln('Date: \\${e.timestamp}');
      if (e.mood != null && e.mood!.isNotEmpty) buffer.writeln('Mood: \\${e.mood}');
      if (e.tags.isNotEmpty) buffer.writeln('Tags: \\${e.tags.join(", ")}');
      buffer.writeln(e.text);
      buffer.writeln('---');
    }
    return buffer.toString();
  }

  /// Helper: format for brief insight
  String _formatMainAndRelatedForInsight(Entry main, List<Entry> related) {
    final buffer = StringBuffer();
    buffer.writeln('Main Entry:');
    buffer.writeln(main.text);
    buffer.writeln('---');
    buffer.writeln('Related Entries:');
    for (final e in related) {
      buffer.writeln(e.text);
      buffer.writeln('---');
    }
    return buffer.toString();
  }

  /// Generate a fallback context if API call fails
  String _generateFallbackEntryContext(Entry mainEntry, List<Entry> relatedEntries) {
    // Simple fallback algorithm to generate insight without API
    final List<String> insights = [];
    
    // Check for common tags between main entry and related entries
    if (mainEntry.tags.isNotEmpty && relatedEntries.isNotEmpty) {
      final commonTagsEntries = relatedEntries
          .where((e) => e.tags.any((tag) => mainEntry.tags.contains(tag)))
          .toList();
          
      if (commonTagsEntries.isNotEmpty) {
        final commonTags = mainEntry.tags
            .where((tag) => commonTagsEntries
                .any((e) => e.tags.contains(tag)))
            .toList();
            
        if (commonTags.isNotEmpty) {
          insights.add('This entry shares themes with other entries involving: ${commonTags.join(", ")}.');
        }
      }
    }
    
    // Check for date proximity
    final sameDayEntries = relatedEntries
        .where((e) => _isSameDay(e.rawDateTime, mainEntry.rawDateTime))
        .toList();
        
    if (sameDayEntries.isNotEmpty) {
      insights.add('This entry was written on the same day as ${sameDayEntries.length} other entries, suggesting related events or thoughts.');
    }
    
    // Default insight if nothing specific found
    if (insights.isEmpty) {
      insights.add('This entry appears to be part of your ongoing journal narrative.');
      
      if (relatedEntries.isNotEmpty) {
        insights.add('There are ${relatedEntries.length} related entries that provide additional context to this moment in your life.');
      }
    }
    
    return insights.join(' ');
  }

  /// Generate fallback overall insights if API call fails
  String _generateFallbackOverallInsights(Entry mainEntry, List<Entry> relatedEntries) {
    final List<String> insights = [];
    final allEntries = [mainEntry, ...relatedEntries];
    
    // Check for mood patterns
    final moods = allEntries
        .where((e) => e.mood != null && e.mood!.isNotEmpty)
        .map((e) => e.mood!)
        .toList();
        
    if (moods.isNotEmpty) {
      // Simple frequency count
      final moodFrequency = <String, int>{};
      for (final mood in moods) {
        moodFrequency[mood] = (moodFrequency[mood] ?? 0) + 1;
      }
      
      final mostFrequentMood = moodFrequency.entries
          .reduce((a, b) => a.value > b.value ? a : b)
          .key;
          
      insights.add('Your most frequent mood across these entries was "$mostFrequentMood".');
    }
    
    // Check for common tags
    final allTags = allEntries
        .expand((e) => e.tags)
        .toList();
        
    if (allTags.isNotEmpty) {
      final tagFrequency = <String, int>{};
      for (final tag in allTags) {
        tagFrequency[tag] = (tagFrequency[tag] ?? 0) + 1;
      }
      
      final mostFrequentTags = tagFrequency.entries
          .where((e) => e.value > 1)
          .map((e) => e.key)
          .take(3)
          .toList();
          
      if (mostFrequentTags.isNotEmpty) {
        insights.add('Recurring themes include: ${mostFrequentTags.join(", ")}.');
      }
    }
    
    // Check for time span
    if (relatedEntries.isNotEmpty) {
      final dates = allEntries.map((e) => e.rawDateTime).toList();
      dates.sort();
      
      final firstDate = dates.first;
      final lastDate = dates.last;
      final diffDays = lastDate.difference(firstDate).inDays;
      
      if (diffDays > 0) {
        insights.add('These entries span $diffDays days, showing a period of your journaling experience.');
      } else {
        insights.add('These entries were all written on the same day, representing a snapshot of your thoughts during that time.');
      }
    }
    
    // Default insight
    if (insights.isEmpty) {
      insights.add('These journal entries form part of your ongoing reflection process.');
    }
    
    return insights.join(' ');
  }
  
  /// Local fallback for related entries (old logic)
  List<Entry> _findRelatedLocally(Entry main, List<Entry> all) {
    // Use your previous heuristics, e.g. tags, date, content
    final Set<Entry> byTags = all.where((e) => e.localId != main.localId && e.tags.any((tag) => main.tags.contains(tag))).toSet();
    final Set<Entry> byDate = all.where((e) {
      final entryDate = DateTime(e.rawDateTime.year, e.rawDateTime.month, e.rawDateTime.day);
      final mainDate = DateTime(main.rawDateTime.year, main.rawDateTime.month, main.rawDateTime.day);
      return e.localId != main.localId && (entryDate.isAtSameMomentAs(mainDate) || entryDate.isAtSameMomentAs(mainDate.subtract(const Duration(days: 1))) || entryDate.isAtSameMomentAs(mainDate.add(const Duration(days: 1))));
    }).toSet();
    final Set<Entry> byContent = all.where((e) {
      if (e.localId == main.localId) return false;
      final mainWords = main.text.toLowerCase().split(RegExp(r'\W+')).where((w) => w.length > 4).toSet();
      final otherWords = e.text.toLowerCase().split(RegExp(r'\W+')).where((w) => w.length > 4).toSet();
      return mainWords.intersection(otherWords).length >= 3;
    }).toSet();
    final allRelated = {...byTags, ...byDate, ...byContent}.toList();
    allRelated.sort((a, b) => b.rawDateTime.compareTo(a.rawDateTime));
    return allRelated.take(5).toList();
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  // Context-aware post-processing filter for related entries
  List<Entry> _filterContextuallyRelevantEntries(Entry main, List<Entry> candidates) {
    // Score by: mood match, tag overlap, content overlap, date proximity, narrative continuity
    List<_EntryScore> scored = candidates.map((e) {
      int score = 0;
      // Mood match
      if (main.mood != null && e.mood != null && main.mood == e.mood) score += 2;
      // Tag overlap
      final tagOverlap = main.tags.toSet().intersection(e.tags.toSet()).length;
      score += tagOverlap;
      // Content overlap (words > 4 chars)
      final mainWords = main.text.toLowerCase().split(RegExp(r'\W+')).where((w) => w.length > 4).toSet();
      final otherWords = e.text.toLowerCase().split(RegExp(r'\W+')).where((w) => w.length > 4).toSet();
      score += mainWords.intersection(otherWords).length;
      // Date proximity (within 2 days)
      final diff = (main.rawDateTime.difference(e.rawDateTime).inDays).abs();
      if (diff <= 2) score += 1;
      // Narrative continuity: if entry is before or after main entry
      if (e.rawDateTime.isBefore(main.rawDateTime)) score += 1;
      return _EntryScore(e, score);
    }).toList();
    scored.sort((a, b) => b.score.compareTo(a.score));
    // Only keep those with score >= median or at least 3
    int median = scored.isNotEmpty ? scored[scored.length ~/ 2].score : 0;
    int threshold = median > 2 ? median : 3;
    return scored.where((s) => s.score >= threshold).map((s) => s.entry).toList();
  }
}

// Helper class for scoring related entries
class _EntryScore {
  final Entry entry;
  final int score;
  _EntryScore(this.entry, this.score);
}
