import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter/foundation.dart';

class GeminiService {
  // PLACEHOLDER for API Key - User must replace this
  static const String _apiKey = 'AIzaSyBfF9iJRm9v5y6watsa7oo9z6Fe3f_gZLo';
  
  final GenerativeModel _model;
  final List<Content> _chatHistory = [];

  GeminiService() : _model = GenerativeModel(
    model: 'gemini-1.5-flash-latest',
    apiKey: _apiKey,
    systemInstruction: Content.system('You are the Learno Assistant, a helpful AI for students in Jordan. Keep answers concise and educational.'),
  );

  Future<String> generateResponse(String prompt) async {
    try {
      if (_apiKey == 'YOUR_GEMINI_API_KEY_HERE') {
        return 'Please configure your Gemini API Key in lib/services/ai_service.dart';
      }

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      
      final text = response.text;
      if (text == null) {
        return 'I am sorry, I could not generate a response.';
      }
      
      return text;
    } catch (e) {
      debugPrint('Gemini Error: $e');
      return 'Error: $e';
    }
  }

  // Optional: Start a chat session for contextual conversations
  ChatSession startChat() {
    return _model.startChat();
  }
}
