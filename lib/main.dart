import 'package:flutter/material.dart';
import 'package:yandex_mapkit/yandex_mapkit.dart';
import 'package:masjid_app/examples/widgets/map_page.dart';
import 'package:masjid_app/examples/circle_map_object_page.dart';
import 'package:masjid_app/examples/clusterized_placemark_collection_page.dart';
import 'package:masjid_app/examples/bicycle_page.dart';
import 'package:masjid_app/examples/driving_page.dart';
import 'package:masjid_app/examples/map_controls_page.dart';
import 'package:masjid_app/examples/map_object_collection_page.dart';
import 'package:masjid_app/examples/placemark_map_object_page.dart';
import 'package:masjid_app/examples/polyline_map_object_page.dart';
import 'package:masjid_app/examples/polygon_map_object_page.dart';
import 'package:masjid_app/examples/reverse_search_page.dart';
import 'package:masjid_app/examples/search_page.dart';
import 'package:masjid_app/examples/suggest_page.dart';
import 'package:masjid_app/examples/user_layer_page.dart';

void main() {
  // AndroidYandexMap.useAndroidViewSurface = false;
  runApp(const MaterialApp(home: MainPage()));
}

const List<MapPage> _allPages = <MapPage>[
  // MapControlsPage(),
  // ClusterizedPlacemarkCollectionPage(),
  // MapObjectCollectionPage(),
  // PlacemarkMapObjectPage(),
  // PolylineMapObjectPage(),
  // PolygonMapObjectPage(),
  // CircleMapObjectPage(),
  UserLayerPage(),
  // SuggestionsPage(),
  // SearchPage(),
  // ReverseSearchPage(),
  // BicyclePage(),
  // DrivingPage(),
];

class MainPage extends StatelessWidget {
  const MainPage({Key? key}) : super(key: key);

  void _pushPage(BuildContext context, MapPage page) {
    Navigator.push(
        context,
        MaterialPageRoute<void>(
            builder: (_) => Scaffold(
                appBar: AppBar(title: Text(page.title)),
                body:
                    Container(padding: const EdgeInsets.all(0), child: page))));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text('Masjid App')),
        body: const UserLayerPage());
  }
}
