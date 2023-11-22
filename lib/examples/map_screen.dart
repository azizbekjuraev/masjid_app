import 'package:flutter/material.dart';
import 'package:yandex_mapkit/yandex_mapkit.dart';
import 'package:map_launcher/map_launcher.dart';
import 'package:masjid_app/examples/map_point.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:csv/csv.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:async' show Future;

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
              'assets/mosque.png',
            ),
            scale: 0.25,
          ),
        ),
        onTap: (_, __) => showModalBottomSheet(
          enableDrag: true,
          showDragHandle: true,
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

    // print(formattedPrayerTimes);
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

  Future<void> uploadToFirestore() async {
    final CollectionReference masjids =
        FirebaseFirestore.instance.collection('masjids');
    final myData = await rootBundle.loadString("assets/Masjids.csv");
    List<List<dynamic>> csvTable =
        CsvToListConverter(eol: '\n').convert(myData);
    List<List<dynamic>> data = csvTable;

    for (var i = 0; i < data.length; i++) {
      var latString = data[i][1]?.toString();
      var longString = data[i][2]?.toString();

      // Remove degree symbol and direction indicators
      latString = latString?.replaceAll('° N', '');
      longString = longString?.replaceAll('° E', '');

      var lat = double.tryParse(latString!) ?? 0.0;
      var long = double.tryParse(longString!) ?? 0.0;

      if (lat != null && long != null) {
        var record = {
          'name': data[i][0],
          'coords': GeoPoint(lat, long),
        };

        // Check if the document with the same name and coordinates already exists
        var existingDocs = await masjids
            .where('name', isEqualTo: data[i][0])
            .where('coords', isEqualTo: GeoPoint(lat, long))
            .get();

        if (existingDocs.docs.isEmpty) {
          // Document doesn't exist, add it to Firestore
          await masjids.add(record);
          print('Record added to Firestore');
        } else {
          print('Record already exists in Firestore');
        }
      } else {
        print('Invalid latitude or longitude for record: $i');
      }
    }
  }

  Future<void> uploadPrayerTimesToFirestore() async {
    final masjids = FirebaseFirestore.instance.collection('masjids');
    final masjidDocuments = await masjids.get();

    for (var masjidDocument in masjidDocuments.docs) {
      final masjidRef = masjidDocument.reference;
      final masjidId = masjidRef.id;

      // Generate timestamps for each prayer time
      final bomdodTime = Timestamp.fromDate(DateTime(2023, 11, 18, 5, 45, 0));
      final bomdodTakbirTime =
          Timestamp.fromDate(DateTime(2023, 11, 18, 5, 30, 0));
      final peshinTime = Timestamp.fromDate(DateTime(2023, 11, 18, 13, 14, 57));
      final peshinTakbirTime =
          Timestamp.fromDate(DateTime(2023, 11, 18, 13, 22, 29));
      final asrTime = Timestamp.fromDate(DateTime(2023, 11, 18, 15, 47, 24));
      final asrTakbirTime =
          Timestamp.fromDate(DateTime(2023, 11, 18, 15, 46, 31));
      final shomTime = Timestamp.fromDate(DateTime(2023, 11, 18, 17, 25, 44));
      final shomTakbirTime =
          Timestamp.fromDate(DateTime(2023, 11, 18, 17, 53, 4));
      final xuftonTime = Timestamp.fromDate(DateTime(2023, 11, 18, 18, 43, 44));
      final xuftonTakbirTime =
          Timestamp.fromDate(DateTime(2023, 11, 18, 18, 50, 6));
      final createdAt = Timestamp.fromDate(DateTime(2023, 11, 18, 1, 16, 15));

      // Create a prayer time document
      await FirebaseFirestore.instance.collection('prayer_time').add({
        'masjid': masjidRef, // Reference to the masjid document
        'bomdod': bomdodTime,
        'bomdod_takbir': bomdodTakbirTime,
        'peshin': peshinTime,
        'peshin_takbir': peshinTakbirTime,
        'asr': asrTime,
        'asr_takbir': asrTakbirTime,
        'shom': shomTime,
        'shom_takbir': shomTakbirTime,
        'xufton': xuftonTime,
        'xufton_takbir': xuftonTakbirTime,
        'created_at': createdAt,
      });
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
              // await uploadToFirestore();
              // await uploadPrayerTimesToFirestore();
            },
            onCameraPositionChanged: (cameraPosition, _, __) {
              setState(() {
                _mapZoom = cameraPosition.zoom;
              });
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
                    image:
                        BitmapDescriptor.fromAssetImage('assets/islamic.png'),
                    scale: 0.15,
                  ))),
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
                await _mapController.moveCamera(CameraUpdate.zoomIn());
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
                await _mapController.moveCamera(CameraUpdate.zoomOut());
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
  _ModalBodyView({required this.point, required this.prayerTimes});

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
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0),
                  child: Table(
                    defaultVerticalAlignment: TableCellVerticalAlignment.bottom,
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
                                  style: myTextStyle,
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
                                  style: myTextStyle,
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
                                style: myTextStyle,
                              ),
                            ),
                          ),
                          TableCell(
                            child: Center(
                              child: Text(
                                'Bomdod Takbir - ${time['bomdod_takbir']}',
                                style: myTextStyle,
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
                                "Peshin - ${time['peshin']}",
                                style: myTextStyle,
                              ),
                            ),
                          ),
                          TableCell(
                            child: Center(
                              child: Text(
                                "Peshin Takbiri - ${time['peshin_takbir']}",
                                style: myTextStyle,
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
                                "Asr - ${time['asr']}",
                                style: myTextStyle,
                              ),
                            ),
                          ),
                          TableCell(
                            child: Center(
                              child: Text(
                                "Asr Takbiri - ${time['asr_takbir']}",
                                style: myTextStyle,
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
                                "Shom - ${time['shom']}",
                                style: myTextStyle,
                              ),
                            ),
                          ),
                          TableCell(
                            child: Center(
                              child: Text(
                                "Shom Takbir - ${time['shom_takbir']}",
                                style: myTextStyle,
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
                                "Xufton - ${time['xufton']}",
                                style: myTextStyle,
                              ),
                            ),
                          ),
                          TableCell(
                            child: Center(
                              child: Text(
                                "Xufton Takbiri - ${time['xufton_takbir']}",
                                style: myTextStyle,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.history),
                        Text(
                          'Yangilangan sana: ${time['created_at']}',
                          style: const TextStyle(fontSize: 20),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  TextStyle myTextStyle = const TextStyle(fontSize: 17);

  Future<void> _openMapsSheet(context) async {
    try {
      final coords = Coords(point.latitude, point.longitude);
      final title = point.name;
      final availableMaps = await MapLauncher.installedMaps;

      showModalBottomSheet(
        context: context,
        builder: (BuildContext context) {
          return SafeArea(
            child: SingleChildScrollView(
              child: SizedBox(
                height: 150,
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
