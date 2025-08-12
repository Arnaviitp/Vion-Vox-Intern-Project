import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'registration_form.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyAZayVp9NCWr-OrKDfS41DZgdidIa6TG9w",
      authDomain: "vion-57e59.firebaseapp.com",
      databaseURL:
          "https://vion-57e59-default-rtdb.asia-southeast1.firebasedatabase.app",
      projectId: "vion-57e59",
      storageBucket: "vion-57e59.appspot.com",
      messagingSenderId: "30464705100",
      appId: "1:30464705100:web:1d1564a6f17b21f012aae9",
      measurementId: "G-D4982KNWX6",
    ),
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: RegistrationForm(),
    );
  }
}
