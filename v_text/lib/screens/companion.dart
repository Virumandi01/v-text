import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class CompanionScreen extends StatelessWidget {
  final IO.Socket socket;
  final String userToken;
  const CompanionScreen({super.key, required this.socket, required this.userToken});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Node Identity Hub', style: TextStyle(fontSize: 14, fontFamily: 'monospace'))),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("DESKTOP SYNC", style: TextStyle(color: Colors.grey, fontSize: 12, letterSpacing: 1.5)),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => Scaffold(
                      appBar: AppBar(title: const Text('Scan Matrix Link')),
                      body: MobileScanner(
                        onDetect: (capture) {
                          final List<Barcode> barcodes = capture.barcodes;
                          if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
                            String rawUrl = barcodes.first.rawValue!;
                            Uri uri = Uri.parse(rawUrl);
                            String? sid = uri.queryParameters['session'];
                            if (sid != null) {
                              socket.emit('submit_pairing_from_mobile', {'sessionId': sid, 'mobileToken': userToken});
                              Navigator.pop(context); // Close Scanner
                              Navigator.pop(context); // Return to Dashboard
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Desktop Authorized!", style: TextStyle(color: Colors.white)), backgroundColor: Colors.green));
                            }
                          }
                        },
                      ),
                    ),
                  ));
                },
                icon: const Icon(Icons.monitor_rounded, color: Colors.white),
                // FIXED: Explicit text coloring to prevent blank bars
                label: const Text("PAIR BROWSER WEB SESSION", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5), 
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}