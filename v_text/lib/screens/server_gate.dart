import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'dashboard.dart';

class ServerGateScreen extends StatefulWidget {
  const ServerGateScreen({super.key});

  @override
  State<ServerGateScreen> createState() => _ServerGateScreenState();
}

class _ServerGateScreenState extends State<ServerGateScreen> {
  final TextEditingController _ipController = TextEditingController(text: "http://");
  bool _isConnecting = false;

  void _testAndConnectNode() async {
    final String targetUrl = _ipController.text.trim();
    if (!targetUrl.startsWith("http")) {
      _showSnackbar("Invalid Protocol. Must begin with http:// or https://");
      return;
    }

    setState(() => _isConnecting = true);

    IO.Socket testSocket = IO.io(targetUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });

    testSocket.connect();

    testSocket.onConnect((_) async {
      testSocket.dispose();
      
      final prefs = await SharedPreferences.getInstance();
      String freshToken = _generate32CharToken();
      
      await prefs.setString('v_text_server_ip', targetUrl);
      await prefs.setString('v_text_token', freshToken);

      if (mounted) {
        Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (context) => DashboardScreen(serverUrl: targetUrl, userToken: freshToken),
        ));
      }
    });

    testSocket.onConnectError((err) {
      testSocket.dispose();
      setState(() => _isConnecting = false);
      _showSnackbar("Node Connection Refused. Check address or server state.");
    });
  }

  String _generate32CharToken() {
    final random = Random.secure();
    final values = List<int>.generate(16, (i) => random.nextInt(256));
    return values.map((b) => b.toRadixString(16).padLeft(2, '0')).join('');
  }

  void _showSnackbar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.redAccent));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Fixed: Added missing comma between fontweight and color properties
            const Text(
              'v-text', 
              style: TextStyle(
                fontSize: 36, 
                fontWeight: FontWeight.w100, 
                color: Color(0xFF818CF8)
              )
            ),
            const Text('ENTER NETWORK NODE DESTINATION ADDRESS', style: TextStyle(fontSize: 10, letterSpacing: 1.5, color: Colors.grey)),
            const SizedBox(height: 32),
            TextField(
              controller: _ipController,
              autofocus: true,
              // Fixed: Spellings changed from colour to color
              style: const TextStyle(fontFamily: 'monospace', color: Color(0xFFFFD740)),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFF111827),
                hintText: "http://192.168.1.50:3000",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                prefixIcon: const Icon(Icons.lan_rounded, color: Colors.indigoAccent),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isConnecting ? null : _testAndConnectNode,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _isConnecting 
                  ? const CircularProgressIndicator(color: Colors.white) 
                  : const Text('INITIALIZE LINK', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}