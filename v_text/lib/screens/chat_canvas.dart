import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class ChatCanvasScreen extends StatefulWidget {
  final IO.Socket socket;
  final String channelName;
  final String channelId;
  final bool isSelf;

  const ChatCanvasScreen({super.key, required this.socket, required this.channelName, required this.channelId, required this.isSelf});

  @override
  State<ChatCanvasScreen> createState() => _ChatCanvasScreenState();
}

class _ChatCanvasScreenState extends State<ChatCanvasScreen> {
  final TextEditingController _textController = TextEditingController();
  final List<String> _messages = [];

  @override
  void initState() {
    super.initState();
    if (!widget.isSelf) {
      widget.socket.on('receive_msg', (data) {
        if (mounted && data['text'] != null) {
          setState(() => _messages.add("Partner: ${data['text']}"));
        }
      });
    }
  }

  void _sendMessage() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    setState(() => _messages.add(widget.isSelf ? "Saved Note: $text" : "You: $text"));
    
    if (!widget.isSelf) {
      widget.socket.emit('send_msg', {'text': text});
    }
    _textController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.channelName, style: const TextStyle(fontSize: 14))),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length,
              padding: const EdgeInsets.all(16),
              itemBuilder: (context, index) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: const Color(0xFF111827), borderRadius: BorderRadius.circular(12)),
                child: Text(_messages[index], style: const TextStyle(fontFamily: 'monospace', fontSize: 13)),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFF111827),
                      hintText: widget.isSelf ? "Store transient private string data..." : "Type text payload...",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(icon: const Icon(Icons.send_rounded, color: Colors.indigoAccent), onPressed: _sendMessage),
              ],
            ),
          ),
        ],
      ),
    );
  }
}