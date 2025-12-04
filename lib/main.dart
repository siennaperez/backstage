import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'screens/signup.dart';
import 'firebase_options.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    if (kIsWeb) {
      await dotenv.load(fileName: ".env");
    } else {
      await dotenv.load(fileName: ".env");
    }
  } catch (e) {
    print('Error loading .env file: $e');
  }

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    if (kIsWeb) {
      try {
        FirebaseFirestore.instance.settings = const Settings(
          persistenceEnabled: true,
          cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
        );
        print('✅ Firestore persistence enabled for web');
      } catch (e) {
        print('⚠️ Could not enable Firestore persistence: $e');
      }
    }
  } catch (e) {
    print('Error initializing Firebase: $e');
    rethrow;
  }

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Backstage',
      debugShowCheckedModeBanner: false,
      home: SignUpScreen(),
    );
  }
}
