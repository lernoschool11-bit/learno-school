import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class GeminiService {
  static const String _apiKey = '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';
  static const String _model = 'google/gemini-2.0-flash-lite-preview-02-05:free'; // Using a highly capable free model from OpenRouter
  static const String _baseUrl = 'https://openrouter.ai/api/v1/chat/completions';

  final List<Map<String, String>> _chatHistory = [];

  Future<String> generateResponse(String prompt) async {
    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
          'HTTP-Referer': 'https://learno.app', // Required by some OpenRouter models
          'X-Title': 'Learno School',
        },
        body: jsonEncode({
          'model': _model,
          'messages': [
            {
              'role': 'system',
              'content': 'You are the Learno Assistant, a helpful AI for students in Jordan. Keep answers concise and educational.'
            },
            {'role': 'user', 'content': prompt}
          ],
          'temperature': 0.7,
          'max_tokens': 1024,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        final choices = data['choices'] as List;
        if (choices.isEmpty) return 'No response generated.';
        return choices[0]['message']['content'] as String;
      } else {
        debugPrint('OpenRouter API Error: ${response.body}');
        return 'عذراً، حدث خطأ في معالجة طلبك.';
      }
    } catch (e) {
      debugPrint('OpenRouter Error: $e');
      return 'عذراً، تعذر الاتصال بالخادم.';
    }
  }

  /// Multi-turn chat مع سجل المحادثة
  Future<String> chat(String prompt) async {
    _chatHistory.add({'role': 'user', 'content': prompt});

    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
          'HTTP-Referer': 'https://learno.app',
          'X-Title': 'Learno School',
        },
        body: jsonEncode({
          'model': _model,
          'messages': [
            {
              'role': 'system',
              'content': 'You are the Learno Assistant, a helpful AI for students in Jordan. Keep answers concise and educational.'
            },
            ..._chatHistory,
          ],
          'temperature': 0.7,
          'max_tokens': 1024,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        final choices = data['choices'] as List;
        if (choices.isEmpty) return 'No response generated.';
        
        final assistantText = choices[0]['message']['content'] as String;

        // احفظ رد الـ AI بالـ history
        _chatHistory.add({'role': 'assistant', 'content': assistantText});

        return assistantText;
      } else {
        debugPrint('OpenRouter API Error: ${response.body}');
        return 'عذراً، حدث خطأ في معالجة طلبك.';
      }
    } catch (e) {
      debugPrint('OpenRouter Error: $e');
      return 'عذراً، تعذر الاتصال بالخادم.';
    }
  }

  /// امسح سجل المحادثة
  void clearHistory() => _chatHistory.clear();
}