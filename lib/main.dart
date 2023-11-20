import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:masjid_app/examples/map_screen.dart';
import 'package:masjid_app/examples/user_layer_page.dart';
import 'package:masjid_app/examples/map_controls_page.dart';
import 'package:masjid_app/examples/search_page.dart';
import 'package:masjid_app/examples/launch_app.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:masjid_app/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MaterialApp(home: MainPage()));
}

class MainPage extends StatelessWidget {
  const MainPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text('Masjid App')), body: MapScreen());
  }
}
