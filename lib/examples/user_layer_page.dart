import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:yandex_mapkit/yandex_mapkit.dart';
import 'package:masjid_app/examples/widgets/control_button.dart';
import 'package:masjid_app/examples/search_page.dart';
import 'package:masjid_app/examples/widgets/map_page.dart';

class UserLayerPage extends MapPage {
  const UserLayerPage({Key? key}) : super('User layer example', key: key);

  @override
  Widget build(BuildContext context) {
    return _UserLayerExample();
  }
}

class _UserLayerExample extends StatefulWidget {
  @override
  _UserLayerExampleState createState() => _UserLayerExampleState();
}

class _UserLayerExampleState extends State<_UserLayerExample> {
  late YandexMapController controller;
  GlobalKey mapKey = GlobalKey();

  Future<bool> get locationPermissionNotGranted async =>
      !(await Permission.location.request().isGranted);

  void _showMessage(Text text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: text));
  }

  @override
  Widget build(BuildContext context) {
    // Set initial camera position to a specific region
    final initialPosition =
        Point(latitude: 41.311081, longitude: 69.240562); // Example coordinates

    return Scaffold(
      body: Stack(
        children: [
          YandexMap(
            key: mapKey,
            onMapCreated: (YandexMapController yandexMapController) async {
              controller = yandexMapController;

              // Set the initial camera position using moveCamera method
              await controller.moveCamera(
                CameraUpdate.newCameraPosition(
                  CameraPosition(
                    target: initialPosition,
                    zoom: 6, // You can set the initial zoom level
                  ),
                ),
                animation: const MapAnimation(),
              );
            },
            onUserLocationAdded: (UserLocationView view) async {
              return view.copyWith(
                  pin: view.pin.copyWith(
                      icon: PlacemarkIcon.single(PlacemarkIconStyle(
                          image: BitmapDescriptor.fromAssetImage(
                              'lib/assets/user.png')))),
                  arrow: view.arrow.copyWith(
                      icon: PlacemarkIcon.single(PlacemarkIconStyle(
                          image: BitmapDescriptor.fromAssetImage(
                              'lib/assets/arrow.png')))),
                  accuracyCircle: view.accuracyCircle
                      .copyWith(fillColor: Colors.blue.withOpacity(0.5)));
            },
          ),
          Positioned(
            bottom: 40.0,
            right: 16.0,
            child: FloatingActionButton(
              tooltip: 'Your location',
              onPressed: () async {
                if (await locationPermissionNotGranted) {
                  _showMessage(
                      const Text('Location permission was NOT granted'));
                  return;
                }
                // Your existing code for moving to the user's location
                final mediaQuery = MediaQuery.of(context);
                final height = mapKey.currentContext!.size!.height *
                    mediaQuery.devicePixelRatio;
                final width = mapKey.currentContext!.size!.width *
                    mediaQuery.devicePixelRatio;

                await controller.toggleUserLayer(
                  visible: true,
                  autoZoomEnabled: true,
                  anchor: UserLocationAnchor(
                    course: Offset(0.5 * width, 0.5 * height),
                    normal: Offset(0.5 * width, 0.5 * height),
                  ),
                );
              },
              child: Icon(Icons.location_on),
            ),
          ),
          // Positioned(child: const SearchPage()),
        ],
      ),
    );
  }
}
