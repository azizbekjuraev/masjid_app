import 'package:flutter/material.dart';
import 'package:yandex_mapkit/yandex_mapkit.dart';
import 'package:map_launcher/map_launcher.dart';
import 'package:masjid_app/examples/map_point.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:flutter_svg/flutter_svg.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late final YandexMapController _mapController;
  GlobalKey mapKey = GlobalKey();

  var collection = FirebaseFirestore.instance.collection('masjids');
  var prayerCollection = FirebaseFirestore.instance.collection('prayer_time');
  late List<MapPoint> items = [];
  late List<Map<String, dynamic>> prayerItems = [];
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
            content: Text('No access to user location'),
          ),
        );
      });
    }

    try {
      var data = await collection.get();
      var prayerData = await prayerCollection.get();
      List<MapPoint> mapPoints = _getMapPoints(data.docs);
      List<Map<String, dynamic>> prayerTimes = _getPrayerTimes(prayerData.docs);

      setState(() {
        items = mapPoints;
        prayerItems = prayerTimes;
        isLoaded = true;
      });

      // _updatePlacemarkObjects();
    } catch (e) {
      print('Error fetching data: $e');
    }
  }

  List<Map<String, dynamic>> _getPrayerTimes(
      List<QueryDocumentSnapshot> documents) {
    return documents.map((DocumentSnapshot document) {
      return document.data() as Map<String, dynamic>;
    }).toList();
  }

  List<MapPoint> _getMapPoints(List<QueryDocumentSnapshot> documents) {
    return documents.map((DocumentSnapshot document) {
      final data = document.data() as Map<String, dynamic>;
      final docId = document.id;
      final name = data['name'] ?? '';
      final coords = data['coords'];

      print(docId);

      if (coords is GeoPoint) {
        double latitude = coords.latitude;
        double longitude = coords.longitude;
        return MapPoint(
            documentId: docId,
            name: name,
            latitude: latitude,
            longitude: longitude);
      } else {
        return MapPoint(
            documentId: docId, name: name, latitude: 0.0, longitude: 0.0);
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
            prayerTimes: _getPrayerTimesForLocation(point),
          ),
        ),
      );
    }).toList();
  }

  List<Map<String, String>> _getPrayerTimesForLocation(MapPoint point) {
    var prayerTimes = prayerItems.where((prayerTime) {
      // Assuming 'masjid' is a reference to a Firestore document
      DocumentReference masjidRef = prayerTime['masjid'];
      // Extract the document ID from the reference
      String masjidId = masjidRef.id;

      print("Masjid ID: $masjidId");

      // Map the document ID from the 'masjid' field
      String prayerTimeMasjidId = masjidRef.id;

      // Now, you can compare the mapped masjidId with point.documentId
      return prayerTimeMasjidId == point.documentId;
    }).toList();

    var formattedPrayerTimes = prayerTimes
        .map((prayerTime) => {
              'bomdod': _formatTimestamp(prayerTime['bomdod']),
              'bomdod_takbir': _formatTimestamp(prayerTime['bomdod_takbir']),
              'peshin': _formatTimestamp(prayerTime['peshin']),
              'peshin_takbir': _formatTimestamp(prayerTime['peshin_takbir']),
              'asr': _formatTimestamp(prayerTime['asr']),
              'asr_takbir': _formatTimestamp(prayerTime['asr_takbir']),
              'shom': _formatTimestamp(prayerTime['shom']),
              'shom_takbir': _formatTimestamp(prayerTime['shom_takbir']),
              'xufton': _formatTimestamp(prayerTime['xufton']),
              'xufton_takbir': _formatTimestamp(prayerTime['xufton_takbir']),
              'created_at': _formatTimestamp(prayerTime['created_at']),
            })
        .toList();

    print(formattedPrayerTimes);
    return formattedPrayerTimes;
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) {
      return 'N/A';
    } else {
      var formatter = DateFormat('hh:mm'
          '');
      return formatter.format(timestamp.toDate());
    }
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
}

class _ModalBodyView extends StatelessWidget {
  const _ModalBodyView({required this.point, required this.prayerTimes});

  final MapPoint point;
  final List<Map<String, String>> prayerTimes;

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
                  await _openMapsSheet(context);
                },
                child: Icon(Icons.location_on_outlined),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Display formatted prayer times
          for (var time in prayerTimes)
            Container(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0),
                    child: Table(
                      // textDirection: TextDirection.rtl,
                      defaultVerticalAlignment:
                          TableCellVerticalAlignment.bottom,
                      border: TableBorder.all(width: 1.0, color: Colors.blue),
                      children: [
                        TableRow(
                          children: [
                            TableCell(
                              child: Container(
                                color: Colors.lightBlueAccent,
                                child: Center(
                                  child: Text(
                                    'Namoz vaqtlari',
                                    textScaleFactor: 2,
                                  ),
                                ),
                              ),
                            ),
                            TableCell(
                              child: Container(
                                color: Colors.lightBlueAccent,
                                child: Center(
                                  child: Text(
                                    'Takbir vaqtlari',
                                    textScaleFactor: 2,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        TableRow(
                          children: [
                            TableCell(
                              child: Center(
                                child: Text(
                                  'Bomdod - ${time['bomdod']}',
                                  textScaleFactor: 1.3,
                                ),
                              ),
                            ),
                            TableCell(
                              child: Center(
                                child: Text(
                                  'Bomdod Takbir - ${time['bomdod_takbir']}',
                                  textScaleFactor: 1.3,
                                ),
                              ),
                            ),
                          ],
                        ),
                        TableRow(
                          children: [
                            Center(
                              child: TableCell(
                                child: Text(
                                  "Peshin - ${time['peshin']}",
                                  textScaleFactor: 1.3,
                                ),
                              ),
                            ),
                            Center(
                              child: TableCell(
                                child: Text(
                                  "Peshin Takbiri - ${time['peshin_takbir']}",
                                  textScaleFactor: 1.3,
                                ),
                              ),
                            ),
                          ],
                        ),
                        TableRow(
                          children: [
                            Center(
                              child: TableCell(
                                child: Text(
                                  "Asr - ${time['asr']}",
                                  textScaleFactor: 1.3,
                                ),
                              ),
                            ),
                            Center(
                              child: TableCell(
                                child: Text(
                                  "Asr Takbiri - ${time['asr_takbir']}",
                                  textScaleFactor: 1.3,
                                ),
                              ),
                            ),
                          ],
                        ),
                        TableRow(
                          children: [
                            Center(
                              child: TableCell(
                                child: Text(
                                  "Shom - ${time['shom']}",
                                  textScaleFactor: 1.3,
                                ),
                              ),
                            ),
                            Center(
                              child: TableCell(
                                child: Text(
                                  "Shom Takbir - ${time['shom_takbir']}",
                                  textScaleFactor: 1.3,
                                ),
                              ),
                            ),
                          ],
                        ),
                        TableRow(children: [
                          Center(
                            child: TableCell(
                                child: Text(
                              "Xufton - ${time['xufton']}",
                              textScaleFactor: 1.3,
                            )),
                          ),
                          Center(
                            child: TableCell(
                                child: Text(
                              "Xufton Takbiri - ${time['xufton_takbir']}",
                              textScaleFactor: 1.3,
                            )),
                          )
                        ])
                      ],
                    ),
                  ),
                  Container(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.history),
                            Text(
                              'Yangilandi: ${time['created_at']}',
                              style: TextStyle(fontSize: 20),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _openMapsSheet(BuildContext context) async {
    try {
      final coords = Coords(point.latitude, point.longitude);
      final title = point.name;
      final availableMaps = await MapLauncher.installedMaps;

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
}
