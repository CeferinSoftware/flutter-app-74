import 'dart:convert';
import 'package:http/http.dart' as http;
import 'config/ai_config.dart';

class AIService {
  static Future<String> sendMessage(String message) async {
    try {
      if (AIConfig.provider == 'gemini') {
        return await _sendToGemini(message);
      } else if (AIConfig.provider == 'openai') {
        return await _sendToOpenAI(message);
      }
      return 'Proveedor de IA no soportado';
    } catch (e) {
      return 'Error: $e';
    }
  }
  
  static Future<String> _sendToGemini(String message) async {
    final url = 'https://generativelanguage.googleapis.com/v1beta/models/${AIConfig.model}:generateContent?key=${AIConfig.apiKey}';
    
    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': [{
          'parts': [{'text': '${AIConfig.systemPrompt}

Usuario: $message'}]
        }]
      }),
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['candidates'][0]['content']['parts'][0]['text'];
    }
    return 'Error en la respuesta de Gemini';
  }
  
  static Future<String> _sendToOpenAI(String message) async {
    final url = 'https://api.openai.com/v1/chat/completions';
    
    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${AIConfig.apiKey}',
      },
      body: jsonEncode({
        'model': AIConfig.model,
        'messages': [
          {'role': 'system', 'content': AIConfig.systemPrompt},
          {'role': 'user', 'content': message}
        ]
      }),
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['choices'][0]['message']['content'];
    }
    return 'Error en la respuesta de OpenAI';
  }
}