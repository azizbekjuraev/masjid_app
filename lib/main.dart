import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:masjid_app/examples/map_screen.dart';
import 'package:masjid_app/examples/user_layer_page.dart';
import 'package:masjid_app/examples/map_controls_page.dart';
import 'package:masjid_app/examples/search_page.dart';
import 'package:masjid_app/examples/launch_app.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:masjid_app/firebase_options.dart';
// import 'package:masjid_app/examples/widgets/drawer_widget.dart';
import 'package:masjid_app/examples/views/login_view.dart';
import 'package:masjid_app/examples/data/user_data.dart';
import 'package:masjid_app/examples/search_masjids.dart';
import 'package:masjid_app/examples/clusterized_placemark_collection_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await UserData.init();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(MaterialApp(
      home: const MainPage(),
      debugShowCheckedModeBanner: false,
      routes: {
        './login/': (context) => const LoginView(),
        './main/': (context) => const MainPage(),
        './search-masjids/': (context) => const SearchMasjids(),
      }));
}

class MainPage extends StatelessWidget {
  const MainPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   title: const FittedBox(child: Text('Masjidlar Takbir Vaqtlari')),
      //   leading: Builder(
      //     builder: (context) => IconButton(
      //       icon: const Icon(Icons.menu),
      //       onPressed: () {
      //         // Open the drawer using the new context from Builder
      //         Scaffold.of(context).openDrawer();
      //       },
      //     ),
      //   ),
      //   actions: [
      //     IconButton(
      //       icon: const Icon(Icons.search),
      //       onPressed: () {
      //         // Navigate to the search page or perform search actions here
      //         Navigator.pushNamed(context, './search-masjids/');
      //       },
      //     ),
      //   ],
      // ),
      body: MapScreen(),
      // drawer: DrawerWidgets().appBarDrow(context),
    );
  }
}
