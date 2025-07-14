import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PokeWoke',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Color(0xFF2196f3)),
        useMaterial3: true,
      ),
      home: const WebViewScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class WebViewScreen extends StatefulWidget {
  const WebViewScreen({super.key});

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  late final WebViewController controller;
  bool isLoading = true;
  bool showChatbot = false;

  @override
  void initState() {
    super.initState();
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (url) {
            setState(() {
              isLoading = false;
            });
          },
        ),
      )
      ..loadRequest(Uri.parse('https://pokewoke.store'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('PokeWoke'),
        backgroundColor: Color(0xFF2196f3),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => controller.reload(),
          ),
          IconButton(
            icon: const Icon(Icons.chat),
            onPressed: () {
              setState(() {
                showChatbot = !showChatbot;
              });
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: controller),
          if (isLoading)
            const Center(child: CircularProgressIndicator()),
          if (showChatbot)
            Positioned(
              bottom: 20,
              right: 20,
              child: ChatbotWidget(
                onClose: () {
                  setState(() {
                    showChatbot = false;
                  });
                },
              ),
            ),
        ],
      ),
    );
  }
}

class ChatbotWidget extends StatefulWidget {
  final VoidCallback onClose;

  const ChatbotWidget({super.key, required this.onClose});

  @override
  State<ChatbotWidget> createState() => _ChatbotWidgetState();
}

class _ChatbotWidgetState extends State<ChatbotWidget> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages = [];
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      height: 400,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Color(0xFF2196f3),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'PokeWokeAI',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: Colors.white),
                  onPressed: widget.onClose,
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(8),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                final isUser = message['sender'] == 'user';
                return Container(
                  margin: EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: isUser 
                        ? MainAxisAlignment.end 
                        : MainAxisAlignment.start,
                    children: [
                      Container(
                        constraints: BoxConstraints(maxWidth: 200),
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isUser ? Color(0xFF2196f3) : Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          message['text'] ?? '',
                          style: TextStyle(
                            color: isUser ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          if (_isLoading)
            Padding(
              padding: EdgeInsets.all(8),
              child: CircularProgressIndicator(),
            ),
          Container(
            padding: EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Escribe tu mensaje...',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: _sendMessage,
                  ),
                ),
                SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: () => _sendMessage(_controller.text),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    setState(() {
      _messages.add({'sender': 'user', 'text': text});
      _isLoading = true;
    });

    _controller.clear();

    try {
      final response = await _callAI(text);
      setState(() {
        _messages.add({'sender': 'bot', 'text': response});
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _messages.add({'sender': 'bot', 'text': 'Error: $e'});
        _isLoading = false;
      });
    }
  }

  Future<String> _callAI(String message) async {
    if ('gemini' == 'gemini') {
      return await _callGemini(message);
    } else if ('gemini' == 'openai') {
      return await _callOpenAI(message);
    }
    return 'Proveedor de IA no soportado';
  }

  Future<String> _callGemini(String message) async {
    final url = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=AIzaSyAy-IS0ZPVF4Z-IAD7zrwWMkybIfM4LVFQ';
    
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [{
            'parts': [{'text': 'Eres un asistente online\n\nUsuario: $message'}]
          }]
        }),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['candidates'][0]['content']['parts'][0]['text'];
      }
      return 'Error en la respuesta de Gemini';
    } catch (e) {
      return 'Error de conexión: $e';
    }
  }

  Future<String> _callOpenAI(String message) async {
    final url = 'https://api.openai.com/v1/chat/completions';
    
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer AIzaSyAy-IS0ZPVF4Z-IAD7zrwWMkybIfM4LVFQ',
        },
        body: jsonEncode({
          'model': 'gemini-1.5-flash',
          'messages': [
            {'role': 'system', 'content': 'Eres un asistente online'},
            {'role': 'user', 'content': message}
          ]
        }),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'];
      }
      return 'Error en la respuesta de OpenAI';
    } catch (e) {
      return 'Error de conexión: $e';
    }
  }
}