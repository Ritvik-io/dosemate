import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'notification_service.dart';
import 'screens/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Start the app FIRST.
  runApp(const DoseMateApp());

  // Initialize notifications after the UI has started.
  try {
    await NotificationService.instance.initialize();
    print('NOTIFICATIONS INITIALIZED SUCCESSFULLY');
  } catch (e, stackTrace) {
    print('NOTIFICATION INITIALIZATION FAILED: $e');
    print(stackTrace);
  }
}

class DoseMateApp extends StatelessWidget {
  const DoseMateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'DoseMate',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF3563E9),
        ),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}