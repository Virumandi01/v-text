import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class DiscoveryPanel extends StatefulWidget {
  final IO.Socket socket;
  final Function(String name, String id) onContactAdded;
  const DiscoveryPanel({super.key, required this.socket, required this.onContactAdded});

  @override
  State<DiscoveryPanel> createState() => _DiscoveryPanelState();
}

class _DiscoveryPanelState extends State<DiscoveryPanel> {
  final TextEditingController _idInputController = TextEditingController();
  bool _isScanning = false;
  final String myEightDigitId = "8421-9654"; 

  void _linkViaCode() {
    String inputId = _idInputController.text.trim();
    if (inputId.length >= 8) {
      widget.onContactAdded("Node Client ($inputId)", inputId);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    // FIXED: SingleChildScrollView prevents the keyboard from lagging out the bottom sheet
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 24, 
          left: 24, right: 24, top: 24
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[800], borderRadius: BorderRadius.circular(10))),
            const SizedBox(height: 24),
            if (!_isScanning) ...[
              const Text("YOUR PAIRING SIGNATURE", style: TextStyle(fontSize: 10, letterSpacing: 1.5, color: Colors.grey)),
              const SizedBox(height: 8),
              Text(myEightDigitId, style: const TextStyle(fontSize: 24, fontFamily: 'monospace', fontWeight: FontWeight.bold, color: Color(0xFFFFD740))),
              const SizedBox(height: 24),
              TextField(
                controller: _idInputController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: const TextStyle(fontFamily: 'monospace', letterSpacing: 2),
                decoration: InputDecoration(
                  filled: true, fillColor: const Color(0xFF111827),
                  hintText: "TYPE 8-DIGIT ID CODE",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => setState(() => _isScanning = true),
                      icon: const Icon(Icons.camera_alt_rounded, color: Colors.white),
                      // FIXED: Explicit text colors
                      label: const Text("SCAN", style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1F2937), minimumSize: const Size(double.infinity, 50)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _linkViaCode,
                      // FIXED: Explicit text colors
                      child: const Text("CONNECT", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4F46E5), minimumSize: const Size(double.infinity, 50)),
                    ),
                  ),
                ],
              ),
            ] else ...[
              SizedBox(
                height: 300,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: MobileScanner(
                    onDetect: (capture) {
                      if (capture.barcodes.isNotEmpty && capture.barcodes.first.rawValue != null) {
                        widget.onContactAdded("Scanned Node", capture.barcodes.first.rawValue!);
                        Navigator.pop(context);
                      }
                    },
                  ),
                ),
              ),
              TextButton(onPressed: () => setState(() => _isScanning = false), child: const Text("Cancel"))
            ],
          ],
        ),
      ),
    );
  }
}