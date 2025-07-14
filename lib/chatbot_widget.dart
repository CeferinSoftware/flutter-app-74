import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ChatbotWidget extends StatefulWidget {
  final String apiBaseUrl;
  final String appId;
  final int userId;
  final Color primaryColor;
  final String chatbotName;
  
  const ChatbotWidget({
    Key? key,
    required this.apiBaseUrl,
    required this.appId,
    required this.userId,
    this.primaryColor = Colors.blue,
    this.chatbotName = 'Asistente',
  }) : super(key: key);

  @override
  _ChatbotWidgetState createState() => _ChatbotWidgetState();
}

class _ChatbotWidgetState extends State<ChatbotWidget> {
  final List<ChatMessage> _messages = [];
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  bool _isMinimized = true;

  @override
  void initState() {
    super.initState();
    _addWelcomeMessage();
  }

  void _addWelcomeMessage() {
    setState(() {
      _messages.add(ChatMessage(
        text: '¡Hola! Soy ${widget.chatbotName}. ¿En qué puedo ayudarte hoy?',
        isUser: false,
        timestamp: DateTime.now(),
      ));
    });
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    // Agregar mensaje del usuario
    setState(() {
      _messages.add(ChatMessage(
        text: text,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _isLoading = true;
    });

    _textController.clear();
    _scrollToBottom();

    try {
      // Llamar a la API del chatbot
      final response = await http.post(
        Uri.parse('${widget.apiBaseUrl}/wp-json/webtoapp/v2/chatbot/query'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'user_id': widget.userId,
          'app_id': widget.appId,
          'query': text,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() {
            _messages.add(ChatMessage(
              text: data['response'],
              isUser: false,
              timestamp: DateTime.now(),
              confidence: data['confidence']?.toDouble(),
              sources: List<String>.from(data['sources']?.map((s) => s['url']) ?? []),
            ));
          });
        } else {
          _addErrorMessage('Lo siento, no pude procesar tu consulta en este momento.');
        }
      } else {
        _addErrorMessage('Error de conexión. Por favor, inténtalo de nuevo.');
      }
    } catch (e) {
      _addErrorMessage('Error de conexión. Verifica tu internet e inténtalo de nuevo.');
    } finally {
      setState(() {
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  void _addErrorMessage(String message) {
    setState(() {
      _messages.add(ChatMessage(
        text: message,
        isUser: false,
        timestamp: DateTime.now(),
        isError: true,
      ));
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Botón flotante del chatbot
        if (_isMinimized)
          Positioned(
            bottom: 20,
            right: 20,
            child: FloatingActionButton(
              onPressed: () => setState(() => _isMinimized = false),
              backgroundColor: widget.primaryColor,
              child: const Icon(Icons.chat, color: Colors.white),
            ),
          ),
        
        // Ventana del chatbot
        if (!_isMinimized)
          Positioned(
            bottom: 20,
            right: 20,
            child: Container(
              width: 320,
              height: 500,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Header del chatbot
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: widget.primaryColor,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                    ),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          radius: 16,
                          backgroundColor: Colors.white,
                          child: Icon(Icons.smart_toy, color: Colors.blue),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            widget.chatbotName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => setState(() => _isMinimized = true),
                          icon: const Icon(Icons.close, color: Colors.white),
                          iconSize: 20,
                        ),
                      ],
                    ),
                  ),
                  
                  // Lista de mensajes
                  Expanded(
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(8),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        return ChatMessageWidget(
                          message: _messages[index],
                          primaryColor: widget.primaryColor,
                        );
                      },
                    ),
                  ),
                  
                  // Indicador de carga
                  if (_isLoading)
                    Container(
                      padding: const EdgeInsets.all(8),
                      child: Row(
                        children: [
                          const SizedBox(width: 12),
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(widget.primaryColor),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text('Escribiendo...', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ),
                  
                  // Input de mensaje
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      border: Border(top: BorderSide(color: Colors.grey, width: 0.5)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _textController,
                            decoration: const InputDecoration(
                              hintText: 'Escribe tu mensaje...',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            maxLines: null,
                            textInputAction: TextInputAction.send,
                            onSubmitted: _sendMessage,
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: _isLoading ? null : () => _sendMessage(_textController.text),
                          icon: Icon(Icons.send, color: widget.primaryColor),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final bool isError;
  final double? confidence;
  final List<String>? sources;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.isError = false,
    this.confidence,
    this.sources,
  });
}

class ChatMessageWidget extends StatelessWidget {
  final ChatMessage message;
  final Color primaryColor;

  const ChatMessageWidget({
    Key? key,
    required this.message,
    required this.primaryColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            CircleAvatar(
              radius: 12,
              backgroundColor: message.isError ? Colors.red : primaryColor,
              child: Icon(
                message.isError ? Icons.error : Icons.smart_toy,
                size: 16,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: message.isUser 
                    ? primaryColor 
                    : (message.isError ? Colors.red.shade50 : Colors.grey.shade100),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.text,
                    style: TextStyle(
                      color: message.isUser ? Colors.white : Colors.black87,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(message.timestamp),
                    style: TextStyle(
                      color: message.isUser 
                          ? Colors.white.withOpacity(0.7) 
                          : Colors.grey.shade600,
                      fontSize: 11,
                    ),
                  ),
                  if (message.confidence != null && message.confidence! < 0.5) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Respuesta con baja confianza',
                      style: TextStyle(
                        color: Colors.orange.shade700,
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (message.isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 12,
              backgroundColor: Colors.grey.shade400,
              child: const Icon(Icons.person, size: 16, color: Colors.white),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
} 