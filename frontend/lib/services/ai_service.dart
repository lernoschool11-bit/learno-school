import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

import '../services/api_service.dart';

class GeminiService {
  final ApiService _api = ApiService();
  final List<Map<String, String>> _chatHistory = [];

  Future<String> generateResponse(String prompt) async {
    try {
      final response = await _api.post('/ai/chat', {
        'prompt': prompt,
        'history': _chatHistory,
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return data['response'] as String;
      } else {
        final error = jsonDecode(utf8.decode(response.bodyBytes));
        return error['error'] ?? 'حدث خطأ في معالجة طلبك.';
      }
    } catch (e) {
      debugPrint('AI Error: $e');
      return 'عذراً، تعذر الاتصال بالخادم.';
    }
  }

  /// Multi-turn chat مع سجل المحادثة
  Future<String> chat(String prompt) async {
    final responseText = await generateResponse(prompt);
    
    // إذا نجح الرد (ليس خطأ)، أضفه للسجل
    if (!responseText.contains('حدث خطأ') && !responseText.contains('عذراً')) {
      _chatHistory.add({'role': 'user', 'content': prompt});
      _chatHistory.add({'role': 'assistant', 'content': responseText});
    }

    return responseText;
  }

  /// امسح سجل المحادثة
  void clearHistory() => _chatHistory.clear();
}