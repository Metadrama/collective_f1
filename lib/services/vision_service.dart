import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/entry.dart';
import 'api_key_service.dart';

/// Google Cloud Vision integration to generate concise media descriptions
class VisionService {
  static const String _endpoint = 'https://vision.googleapis.com/v1/images:annotate';
  final String _apiKey = ApiKeyService.getGoogleVisionApiKey();

  // Persistent cache keys
  static const String _cacheKey = 'vision_media_desc_cache_v1';
  static Map<String, String> _cache = {};
  static bool _loaded = false;

  Future<void> _ensureLoaded() async {
    if (_loaded) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_cacheKey);
      if (raw != null && raw.isNotEmpty) {
        final map = Map<String, dynamic>.from(jsonDecode(raw));
        _cache = map.map((k, v) => MapEntry(k, v.toString()));
      }
    } catch (_) {
      // ignore
    }
    _loaded = true;
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKey, jsonEncode(_cache));
    } catch (_) {
      // ignore
    }
  }

  /// Returns a short description of the entry's media (labels + optional OCR snippet)
  /// or null if no media or API unavailable.
  Future<String?> describeEntryMedia(Entry entry) async {
    await _ensureLoaded();

    // No key configured or no media
    if (_apiKey.isEmpty) return null;
    final imageUrl = entry.imageUrl;
    final localPath = entry.localImagePath;
    if ((imageUrl == null || imageUrl.isEmpty) && (localPath == null || localPath.isEmpty)) {
      return null;
    }

    final cacheId = entry.localId ?? imageUrl ?? localPath!;
    if (_cache.containsKey(cacheId)) {
      return _cache[cacheId];
    }

    try {
      Map<String, dynamic> image;
      if (imageUrl != null && imageUrl.isNotEmpty) {
        image = {
          'source': {'imageUri': imageUrl}
        };
      } else {
        // Local file: base64 encode
        final bytes = await File(localPath!).readAsBytes();
        image = {'content': base64Encode(bytes)};
      }

      final body = {
        'requests': [
          {
            'image': image,
            'features': [
              {'type': 'LABEL_DETECTION', 'maxResults': 5},
              {'type': 'TEXT_DETECTION', 'maxResults': 1},
              {'type': 'WEB_DETECTION', 'maxResults': 3},
              {'type': 'SAFE_SEARCH_DETECTION'}
            ]
          }
        ]
      };

      final uri = Uri.parse('$_endpoint?key=$_apiKey');
      final resp = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (resp.statusCode != 200) {
        debugPrint('Vision API error: ${resp.statusCode} ${resp.body}');
        return null;
      }

      final data = jsonDecode(resp.body);
      final responses = data['responses'] as List?;
      if (responses == null || responses.isEmpty) return null;
      final r = responses.first as Map<String, dynamic>;

      // Labels
      final labels = <String>[];
      if (r['labelAnnotations'] is List) {
        for (final item in r['labelAnnotations']) {
          final score = (item['score'] ?? 0.0) * 1.0;
          final desc = (item['description'] ?? '').toString();
          if (desc.isNotEmpty && score >= 0.7) labels.add(desc);
        }
      }

      // OCR text
      String? ocr;
      if (r['fullTextAnnotation'] != null && r['fullTextAnnotation']['text'] is String) {
        ocr = (r['fullTextAnnotation']['text'] as String).trim();
      } else if (r['textAnnotations'] is List && (r['textAnnotations'] as List).isNotEmpty) {
        ocr = ((r['textAnnotations'] as List).first['description'] ?? '').toString().trim();
      }

      // Web entities as backup signals
      if (labels.isEmpty && r['webDetection']?['webEntities'] is List) {
        final entities = r['webDetection']['webEntities'] as List;
        for (final e in entities) {
          final desc = (e['description'] ?? '').toString();
          final score = (e['score'] ?? 0.0) * 1.0;
          if (desc.isNotEmpty && score >= 0.7) labels.add(desc);
          if (labels.length >= 3) break;
        }
      }

      final shortLabels = labels.take(3).toList();
      String? shortOcr;
      if (ocr != null && ocr.isNotEmpty) {
        final normalized = ocr.replaceAll('\n', ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
        shortOcr = normalized.length > 120 ? normalized.substring(0, 120) + '…' : normalized;
      }

      if (shortLabels.isEmpty && (shortOcr == null || shortOcr.isEmpty)) {
        return null;
      }

      final parts = <String>[];
      if (shortLabels.isNotEmpty) parts.add('looks like: ${shortLabels.join(', ')}');
      if (shortOcr != null && shortOcr.isNotEmpty) parts.add('text reads: "$shortOcr"');
      final description = parts.join('; ');

      _cache[cacheId] = description;
      await _persist();
      return description;
    } catch (e) {
      debugPrint('Vision describe error: $e');
      return null;
    }
  }
}
