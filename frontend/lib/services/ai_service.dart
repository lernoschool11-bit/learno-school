import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class GeminiService {
  static const String _apiKey = 'AIzaSyD_c6RPpDgs9-aJP1aFYRme4Ki3F0UV28U';
  static const String _model = 'gemini-1.5-flash';
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1/models/$_model:generateContent';

  final List<Map<String, dynamic>> _chatHistory = [];

  Future<String> generateResponse(String prompt) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl?key=$_apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'system_instruction': {
            'parts': [
              {
                'text':
                    'You are the Learno Assistant, a helpful AI for students in Jordan. '
                    'Keep answers concise and educational.',
              }
            ]
          },
          'contents': [
            {'role': 'user', 'parts': [{'text': prompt}]}
          ],
          'generationConfig': {
            'temperature': 0.7,
            'maxOutputTokens': 1024,
          },
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final candidates = data['candidates'] as List;
        if (candidates.isEmpty) return 'No response generated.';
        return candidates[0]['content']['parts'][0]['text'] as String;
      } else {
        final error = jsonDecode(response.body);
        debugPrint('Gemini API Error: ${response.body}');
        return 'Error: ${error['error']['message']}';
      }
    } catch (e) {
      debugPrint('Gemini Error: $e');
      return 'Error: $e';
    }
  }

  /// Multi-turn chat مع سجل المحادثة
  Future<String> chat(String prompt) async {
    _chatHistory.add({
      'role': 'user',
      'parts': [{'text': prompt}]
    });

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl?key=$_apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'system_instruction': {
            'parts': [
              {
                'text':
                    'You are the Learno Assistant, a helpful AI for students in Jordan. '
                    'Keep answers concise and educational.',
              }
            ]
          },
          'contents': _chatHistory,
          'generationConfig': {
            'temperature': 0.7,
            'maxOutputTokens': 1024,
          },
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final candidates = data['candidates'] as List;
        if (candidates.isEmpty) return 'No response generated.';
        final assistantText =
            candidates[0]['content']['parts'][0]['text'] as String;

        // احفظ رد الـ AI بالـ history
        _chatHistory.add({
          'role': 'model',
          'parts': [{'text': assistantText}]
        });

        return assistantText;
      } else {
        final error = jsonDecode(response.body);
        debugPrint('Gemini API Error: ${response.body}');
        return 'Error: ${error['error']['message']}';
      }
    } catch (e) {
      debugPrint('Gemini Error: $e');
      return 'Error: $e';
    }
  }

  /// امسح سجل المحادثة
  void clearHistory() => _chatHistory.clear();
}