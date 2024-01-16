import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:masjid_app/examples/map_screen.dart';
import 'package:masjid_app/examples/styles/app_styles.dart';
import 'package:masjid_app/examples/user_layer_page.dart';
import 'package:masjid_app/examples/map_controls_page.dart';
import 'package:masjid_app/examples/search_page.dart';
import 'package:masjid_app/examples/launch_app.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:masjid_app/examples/widgets/drawer_widget.dart';
import 'package:masjid_app/firebase_options.dart';
// import 'package:masjid_app/examples/widgets/drawer_widget.dart';
import 'package:masjid_app/examples/views/login_view.dart';
import 'package:masjid_app/examples/data/user_data.dart';
import 'package:masjid_app/examples/search_masjids.dart';
import 'package:masjid_app/examples/clusterized_placemark_collection_page.dart';
import 'package:masjid_app/examples/views/home_view.dart';
import 'package:masjid_app/examples/views/settings_view.dart';
import 'package:masjid_app/examples/widgets/close_masjid_prayer_times.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await UserData.init();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(MaterialApp(
      home: const MainPage(),
      theme: ThemeData(
          colorScheme: const ColorScheme.light()
              .copyWith(primary: AppStyles.backgroundColorGreen700)),
      debugShowCheckedModeBanner: false,
      routes: {
        './main/': (context) => const MainPage(),
        './login/': (context) => const LoginView(),
        './map-screen/': (context) => const MapScreen(),
        './search-masjids/': (context) => const SearchMasjids(),
        './home-view/': (context) => const HomeView(),
        './close-masjid/': (context) => const CloseMasjidPrayerTimes(),
      }));
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0;

  static const List<Widget> _widgetOptions = <Widget>[
    // HomeView(),
    CloseMasjidPrayerTimes(),
    MapScreen(),
    MapControlsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _widgetOptions,
      ),
      bottomNavigationBar: BottomNavigationBar(
        showUnselectedLabels: false,
        selectedItemColor: Colors.green.shade700,
        type: BottomNavigationBarType.fixed,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Asosiy',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.location_on_outlined),
            label: 'Masjidlar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Sozlamalar',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }
}
