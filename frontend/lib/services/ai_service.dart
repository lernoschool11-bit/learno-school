import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

import '../services/api_service.dart';

class GeminiService {
  final String _apiKey = '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';
  final String _endpoint = 'https://openrouter.ai/api/v1/chat/completions';
  final List<Map<String, String>> _chatHistory = [];

  Future<String> generateResponse(String prompt) async {
    try {
      final messages = [
        {'role': 'system', 'content': 'You are the Learno Assistant, a helpful AI for students. Keep answers concise.'},
        ..._chatHistory,
        {'role': 'user', 'content': prompt}
      ];

      final response = await http.post(
        Uri.parse(_endpoint),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'HTTP-Referer': 'https://learno-ai.com',
          'X-Title': 'Learno AI Assistant',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': 'google/gemini-flash-1.5-exp:free',
          'messages': messages,
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final aiText = data['choices'][0]['message']['content'] as String;
        
        // Update history
        _chatHistory.add({'role': 'user', 'content': prompt});
        _chatHistory.add({'role': 'assistant', 'content': aiText});
        
        return aiText;
      } else {
        // كما طلبت: طباعة السبب الحقيقي للخطأ في الكونسول
        debugPrint('OpenRouter Error Code: ${response.statusCode}');
        debugPrint('OpenRouter Error Body: ${response.body}');
        return 'حدث خطأ في الاتصال بالذكاء الاصطناعي (${response.statusCode})';
      }
    } catch (e) {
      debugPrint('AI Error: $e');
      return 'عذراً، حدث خطأ في الاتصال.';
    }
  }

  Future<String> chat(String prompt) => generateResponse(prompt);

  void clearHistory() => _chatHistory.clear();
}