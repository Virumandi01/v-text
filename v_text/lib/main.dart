import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/server_gate.dart';
import 'screens/dashboard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final String? savedIp = prefs.getString('v_text_server_ip');
  final String? savedToken = prefs.getString('v_text_token');

  runApp(VTextApp(initialScreen: (savedIp != null && savedToken != null) 
    ? DashboardScreen(serverUrl: savedIp, userToken: savedToken)
    : const ServerGateScreen()
  ));
}

class VTextApp extends StatelessWidget {
  final Widget initialScreen;
  const VTextApp({super.key, required this.initialScreen});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'v-text Node',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0B0F19),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF4F46E5),
          surface: Color(0xFF111827),
        ),
      ),
      home: initialScreen,
    );
  }
}