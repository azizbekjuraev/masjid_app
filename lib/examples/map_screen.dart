import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:map_launcher/map_launcher.dart';
import 'package:masjid_app/examples/map_point.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:yandex_mapkit/yandex_mapkit.dart';
import 'package:flutter_svg/flutter_svg.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late final YandexMapController _mapController;
  GlobalKey mapKey = GlobalKey();

  var collection = FirebaseFirestore.instance.collection('masjids');
  late List<MapPoint> items = [];
  bool isLoaded = false;

  var _mapZoom = 0.0;
  CameraPosition? _userLocation;

  final animation =
      const MapAnimation(type: MapAnimationType.smooth, duration: 2.0);

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          YandexMap(
            onMapCreated: (controller) async {
              _mapController = controller;
              await _initLocationLayer();
            },
            onCameraPositionChanged: (cameraPosition, _, __) {
              setState(() {
                _mapZoom = cameraPosition.zoom;
              });
            },
            onMapTap: (Point point) async {
              print("Map tapped at $point");
              await _mapController.deselectGeoObject();
            },
            mapObjects: _getPlacemarkObjects(context),
            onUserLocationAdded: (view) async {
              _userLocation = await _mapController.getUserCameraPosition();
              if (_userLocation != null) {
                await _mapController.moveCamera(
                  CameraUpdate.newCameraPosition(
                    _userLocation!.copyWith(zoom: 13),
                  ),
                  animation: animation,
                );
              }
              return view.copyWith(
                  pin: view.pin.copyWith(
                      icon: PlacemarkIcon.single(PlacemarkIconStyle(
                          image: BitmapDescriptor.fromAssetImage(
                              'assets/user.png')))),
                  arrow: view.arrow.copyWith(
                      icon: PlacemarkIcon.single(PlacemarkIconStyle(
                          image: BitmapDescriptor.fromAssetImage(
                              'assets/arrow.png')))),
                  accuracyCircle: view.accuracyCircle
                      .copyWith(fillColor: Colors.blue.withOpacity(0.5)));
            },
          ),
          Positioned(
            bottom: 450.0,
            right: 5,
            child: FloatingActionButton.small(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(0)),
              onPressed: () async {
                await _mapController.moveCamera(CameraUpdate.zoomIn(),
                    animation: animation);
              },
              child: Icon(Icons.add),
            ),
          ),
          Positioned(
            bottom: 400.0,
            right: 5,
            child: FloatingActionButton.small(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(0)),
              onPressed: () async {
                await _mapController.moveCamera(CameraUpdate.zoomOut(),
                    animation: animation);
              },
              child: Icon(Icons.remove),
            ),
          ),
          Positioned(
            bottom: 40.0,
            right: 5,
            child: FloatingActionButton(
              tooltip: 'Your location',
              onPressed: () async {
                _userLocation = await _mapController.getUserCameraPosition();

                if (_userLocation != null) {
                  await _mapController.moveCamera(
                      CameraUpdate.newCameraPosition(
                        _userLocation!.copyWith(zoom: 13),
                      ),
                      animation: const MapAnimation(
                          type: MapAnimationType.linear, duration: 0.6));
                  print('Moved camera to user location: $_userLocation');
                }
              },
              child: Icon(Icons.my_location_rounded),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _initLocationLayer() async {
    final locationPermissionIsGranted =
        await Permission.location.request().isGranted;

    if (locationPermissionIsGranted) {
      await _mapController.toggleUserLayer(
          visible: true, autoZoomEnabled: true);
    } else {
      WidgetsBinding.instance?.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Нет доступа к местоположению пользователя'),
          ),
        );
      });
    }

    var data = await collection.get();
    List<MapPoint> mapPoints = _getMapPoints(data.docs);
    setState(() {
      items = mapPoints;
      isLoaded = true;
    });
  }

  List<MapPoint> _getMapPoints(List<QueryDocumentSnapshot> documents) {
    return documents.map((DocumentSnapshot document) {
      final data = document.data() as Map<String, dynamic>;
      final name = data['name'] ?? '';
      final coords = data['coords'];

      // Check if 'coords' is a GeoPoint
      if (coords is GeoPoint) {
        double latitude = coords.latitude;
        double longitude = coords.longitude;
        return MapPoint(name: name, latitude: latitude, longitude: longitude);
      } else {
        // Handle the case where coordinates are not in GeoPoint format
        return MapPoint(
            name: name,
            latitude: 0.0,
            longitude: 0.0); // Provide default values or handle accordingly
      }
    }).toList();
  }

  List<PlacemarkMapObject> _getPlacemarkObjects(BuildContext context) {
    return items.map((point) {
      return PlacemarkMapObject(
        mapId: MapObjectId('MapObject $point'),
        point: Point(latitude: point.latitude, longitude: point.longitude),
        opacity: 1,
        icon: PlacemarkIcon.single(
          PlacemarkIconStyle(
            image: BitmapDescriptor.fromAssetImage(
              'assets/icons/place.png',
            ),
            scale: 1,
          ),
        ),
        onTap: (_, __) => showModalBottomSheet(
          context: context,
          builder: (context) => _ModalBodyView(
            point: point,
          ),
        ),
      );
    }).toList();
  }
}

class _ModalBodyView extends StatelessWidget {
  const _ModalBodyView({required this.point});

  final MapPoint point;

  Future<void> _openMapsSheet(BuildContext context) async {
    try {
      final coords = Coords(point.latitude, point.longitude);
      final title = point.name;
      final availableMaps = await MapLauncher.installedMaps;
      print(context);
      showModalBottomSheet(
        context: context,
        builder: (BuildContext context) {
          return SafeArea(
            child: SingleChildScrollView(
              child: Container(
                child: Wrap(
                  children: <Widget>[
                    for (var map in availableMaps)
                      ListTile(
                        onTap: () => map.showMarker(
                          coords: coords,
                          title: title,
                        ),
                        title: Text(map.mapName),
                        leading: SvgPicture.asset(
                          map.icon,
                          height: 30,
                          width: 30,
                        ),
                      ),
                  ],
                ),
                height: 150,
              ),
            ),
          );
        },
      );
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 30),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(point.name, style: const TextStyle(fontSize: 20)),
              TextButton(
                onPressed: () async {
                  // Show the maps sheet when the button is pressed
                  await _openMapsSheet(context);
                },
                child: Icon(Icons.location_on_outlined),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            '${point.latitude}, ${point.longitude}',
            style: const TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
