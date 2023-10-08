import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'Home.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
      options: FirebaseOptions(
          apiKey: "AIzaSyD-bkm94NGnEla-3DZBrscLmnVY08zf5PQ",
          authDomain: "appcrudfirestore-55964.firebaseapp.com",
          projectId: "appcrudfirestore-55964",
          storageBucket: "appcrudfirestore-55964.appspot.com",
          messagingSenderId: "385723714694",
          appId: "1:385723714694:web:132dafd1ebf7545bb05507"));

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      // Remove the debug banner

      debugShowCheckedModeBanner: false,

      title: 'App Cookes',

      home: HomePage(),
    );
  }
}
