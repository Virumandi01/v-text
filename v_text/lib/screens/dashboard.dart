import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'chat_canvas.dart';
import 'companion.dart';
import 'discovery.dart';

class DashboardScreen extends StatefulWidget {
  final String serverUrl;
  final String userToken;
  const DashboardScreen({super.key, required this.serverUrl, required this.userToken});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late IO.Socket socket;
  List<Map<String, String>> contacts = [
    {"name": "Notes to Self (Private Space)", "id": "00000000", "type": "self"}
  ];

  @override
  void initState() {
    super.initState();
    _connectToActiveNode();
  }

  void _connectToActiveNode() {
    socket = IO.io(widget.serverUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
    });
    socket.onConnect((_) => socket.emit('authenticate', widget.userToken));
  }

  @override
  void dispose() {
    socket.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('v-text Terminal', style: TextStyle(fontFamily: 'monospace', fontSize: 16)),
        backgroundColor: const Color(0xFF111827),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_suggest_rounded, color: Color(0xFF818CF8)),
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => CompanionScreen(socket: socket, userToken: widget.userToken),
              ));
            },
          )
        ],
      ),
      body: ListView.separated(
        itemCount: contacts.length,
        padding: const EdgeInsets.all(16),
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final item = contacts[index];
          final isSelf = item["type"] == "self";
          return ListTile(
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => ChatCanvasScreen(socket: socket, channelName: item["name"]!, channelId: item["id"]!, isSelf: isSelf),
              ));
            },
            tileColor: const Color(0xFF111827),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            leading: CircleAvatar(
              backgroundColor: isSelf ? Colors.teal.withOpacity(0.2) : Colors.indigo.withOpacity(0.2),
              child: Icon(isSelf ? Icons.bookmark_rounded : Icons.person_rounded, color: isSelf ? Colors.tealAccent : Colors.indigoAccent),
            ),
            title: Text(item["name"]!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: Text('ID: ${item["id"]}', style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: Colors.grey)),
            trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
          );
        },
      ),
      bottomNavigationBar: BottomAppBar(
        color: const Color(0xFF111827),
        notchMargin: 8,
        child: SizedBox(
          height: 60,
          child: Center(
            child: FloatingActionButton.extended(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: const Color(0xFF0B0F19),
                  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
                  builder: (context) => DiscoveryPanel(
                    socket: socket,
                    onContactAdded: (name, id) {
                      setState(() {
                        contacts.add({"name": name, "id": id, "type": "friend"});
                      });
                    }
                  ),
                );
              },
              backgroundColor: const Color(0xFF4F46E5),
              icon: const Icon(Icons.qr_code_scanner_rounded, color: Colors.white),
              label: const Text("DISCOVERY HUB", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5, color: Colors.white)),
            ),
          ),
        ),
      ),
    );
  }
}