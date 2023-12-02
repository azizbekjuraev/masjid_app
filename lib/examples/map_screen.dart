import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:yandex_mapkit/yandex_mapkit.dart';
import 'package:map_launcher/map_launcher.dart';
import 'package:masjid_app/examples/map_point.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:csv/csv.dart';
import 'package:analog_clock/analog_clock.dart';
import 'package:masjid_app/examples/data/user_data.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:async' show Future;

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

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

  // var _mapZoom = 0.0;
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
      WidgetsBinding.instance.addPostFrameCallback((_) {
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
      DocumentReference masjidRef = prayerTime['masjid'];
      String prayerTimeMasjidId = masjidRef.id;
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
              'created_at': _formatFullTimestamp(prayerTime['created_at']),
            })
        .toList();
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

  String _formatFullTimestamp(Timestamp? timestamp) {
    if (timestamp == null) {
      return 'N/A';
    } else {
      var formatter = DateFormat('yyyy-MM-dd hh:mm');
      return formatter.format(timestamp.toDate());
    }
  }

  Future<void> uploadToFirestore() async {
    final CollectionReference masjids =
        FirebaseFirestore.instance.collection('masjids');
    final myData = await rootBundle.loadString("assets/Masjids.csv");
    List<List<dynamic>> csvTable =
        const CsvToListConverter(eol: '\n').convert(myData);
    List<List<dynamic>> data = csvTable;

    for (var i = 0; i < data.length; i++) {
      var latString = data[i][1]?.toString();
      var longString = data[i][2]?.toString();

      latString = latString?.replaceAll('° N', '');
      longString = longString?.replaceAll('° E', '');

      var lat = double.tryParse(latString!) ?? 0.0;
      var long = double.tryParse(longString!) ?? 0.0;

      var record = {
        'name': data[i][0],
        'coords': GeoPoint(lat, long),
      };

      var existingDocs = await masjids
          .where('name', isEqualTo: data[i][0])
          .where('coords', isEqualTo: GeoPoint(lat, long))
          .get();

      if (existingDocs.docs.isEmpty) {
        await masjids.add(record);
        print('Record added to Firestore');
      } else {
        print('Record already exists in Firestore');
      }
    }
  }

  Future<void> uploadPrayerTimesToFirestore() async {
    final masjids = FirebaseFirestore.instance.collection('masjids');
    final masjidDocuments = await masjids.get();

    for (var masjidDocument in masjidDocuments.docs) {
      final masjidRef = masjidDocument.reference;

      final existingPrayerTimes = await FirebaseFirestore.instance
          .collection('prayer_time')
          .where('masjid', isEqualTo: masjidRef)
          .get();

      if (existingPrayerTimes.docs.isNotEmpty) {
        continue;
      }
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
            // onCameraPositionChanged: (cameraPosition, _, __) {
            //   setState(() {
            //     _mapZoom = cameraPosition.zoom;
            //   });
            // },
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
                    image: BitmapDescriptor.fromAssetImage('assets/user.png'),
                    scale: 1,
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
              child: const Icon(Icons.add),
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
              child: const Icon(Icons.remove),
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
                }
              },
              child: const Icon(Icons.my_location_rounded),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModalBodyView extends StatefulWidget {
  const _ModalBodyView({required this.point, required this.prayerTimes});
  final MapPoint point;
  final List<Map<String, String>> prayerTimes;

  @override
  State<_ModalBodyView> createState() => _ModalBodyViewState();
}

class _ModalBodyViewState extends State<_ModalBodyView> {
  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double dynamicFontSize = screenWidth * 0.04;
    final currUser = FirebaseAuth.instance.currentUser;
    final userEmail = UserData.getUserEmail();
    print(currUser?.email);
    print(userEmail);
    print(currUser?.email == userEmail); // this is true

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: InteractiveViewer(
        minScale: 1,
        maxScale: 3,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(widget.point.name,
                    style: TextStyle(fontSize: dynamicFontSize)),
                TextButton(
                  onPressed: () async {
                    await _openMapsSheet(context);
                  },
                  child: const Icon(Icons.location_on_outlined),
                ),
              ],
            ),
            const SizedBox(height: 5),
            for (var time in widget.prayerTimes)
              Column(
                children: [
                  const Text(
                    'Azon Vaqtlari',
                    style: TextStyle(color: Colors.redAccent),
                  ),
                  const SizedBox(height: 5),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10.0, vertical: 1.0),
                    child: Table(
                      defaultVerticalAlignment:
                          TableCellVerticalAlignment.bottom,
                      border: TableBorder.all(width: 0, color: Colors.black),
                      children: [
                        TableRow(
                          children: [
                            for (var time in widget.prayerTimes)
                              ..._buildAzonPrayerTimeCells(time, myTextStyle),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 5),

                  const Text(
                    'Takbir Vaqtlari',
                    style: TextStyle(color: Colors.blueAccent),
                  ),
                  const SizedBox(height: 5),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10.0, vertical: 1.0),
                    child: Table(
                      defaultVerticalAlignment:
                          TableCellVerticalAlignment.bottom,
                      border: TableBorder.all(width: 0, color: Colors.black),
                      children: [
                        TableRow(
                          children: [
                            for (var time in widget.prayerTimes)
                              ..._buildTakbirPrayerTimeCells(time, myTextStyle),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 5),
                  //Yangilash
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Visibility(
                          visible: currUser?.email == userEmail,
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => EditPrayerTimesScreen(
                                    point: widget.point,
                                    prayerTimes: widget.prayerTimes,
                                  ),
                                ),
                              );
                              //
                            },
                            icon: const Icon(
                              Icons.edit_outlined,
                              size: 15,
                            ),
                            label: const Text('Yangilash'),
                          ),
                        ),
                        Column(
                          children: [
                            const Text(
                              'Yangilangan sana:',
                              style: TextStyle(color: Colors.deepPurple),
                            ),
                            Text(
                              '${time['created_at']}',
                              style: const TextStyle(fontSize: 15),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildAzonPrayerTimeCells(
      Map<String, dynamic> time, TextStyle myTextStyle) {
    return [
      for (var prayer in ['Bomdod', 'Peshin', 'Asr', 'Shom', 'Xufton'])
        ..._buildTableCell(prayer, time[prayer.toLowerCase()]!, myTextStyle),
    ];
  }

  String removeSuffix(String prayer) {
    return prayer.replaceAll('_Takbir', '');
  }

  List<Widget> _buildTakbirPrayerTimeCells(
      Map<String, dynamic> time, TextStyle myTextStyle) {
    return [
      for (var prayer in [
        'Bomdod_Takbir',
        'Peshin_Takbir',
        'Asr_Takbir',
        'Shom_Takbir',
        'Xufton_Takbir'
      ])
        Column(
          children: [
            Text(
              removeSuffix(prayer),
              style: myTextStyle,
            ),
            _buildAnalogClock(time[prayer.toLowerCase()]!),
          ],
        ),
    ];
  }

  List<Widget> _buildTableCell(
      String label, String time, TextStyle myTextStyle) {
    return [
      Column(
        children: [
          Text(
            label,
            style: myTextStyle,
          ),
          _buildAnalogClock(time),
        ],
      ),
    ];
  }

  Widget _buildAnalogClock(String time) {
    String dateTimeString = "2023-01-01 $time";

    return AnalogClock(
      width: 70,
      height: 70,
      decoration: const BoxDecoration(
        color: Colors.transparent,
      ),
      hourHandColor: Colors.black,
      minuteHandColor: Colors.black,
      numberColor: Colors.black,
      showNumbers: true,
      showSecondHand: false,
      textScaleFactor: 2.4,
      showTicks: true,
      showDigitalClock: false,
      showAllNumbers: true,
      datetime: DateTime.parse(dateTimeString),
    );
  }

  TextStyle myTextStyle = const TextStyle(fontSize: 15);

  Future<void> _openMapsSheet(context) async {
    try {
      final coords = Coords(widget.point.latitude, widget.point.longitude);
      final title = widget.point.name;
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

class EditPrayerTimesScreen extends StatefulWidget {
  final MapPoint point;
  final List<Map<String, String>> prayerTimes;

  const EditPrayerTimesScreen(
      {super.key, required this.point, required this.prayerTimes});

  @override
  _EditPrayerTimesScreenState createState() => _EditPrayerTimesScreenState();
}

class _EditPrayerTimesScreenState extends State<EditPrayerTimesScreen> {
  // Add controllers for the edited timestamps
  late TextEditingController bomdodController;
  late TextEditingController bomdodTakbirController;
  late TextEditingController peshinController;
  late TextEditingController peshinTakbirController;
  late TextEditingController asrController;
  late TextEditingController asrTakbirController;
  late TextEditingController shomController;
  late TextEditingController shomTakbirController;
  late TextEditingController xuftonController;
  late TextEditingController xuftonTakbirController;

  @override
  void initState() {
    super.initState();
    // Initialize controllers with existing values
    bomdodController =
        TextEditingController(text: widget.prayerTimes[0]['bomdod']);
    bomdodTakbirController =
        TextEditingController(text: widget.prayerTimes[0]['bomdod_takbir']);
    peshinController =
        TextEditingController(text: widget.prayerTimes[0]['peshin']);
    peshinTakbirController =
        TextEditingController(text: widget.prayerTimes[0]['peshin_takbir']);
    asrController = TextEditingController(text: widget.prayerTimes[0]['asr']);
    asrTakbirController =
        TextEditingController(text: widget.prayerTimes[0]['asr_takbir']);
    shomController = TextEditingController(text: widget.prayerTimes[0]['shom']);
    shomTakbirController =
        TextEditingController(text: widget.prayerTimes[0]['shom_takbir']);
    xuftonController =
        TextEditingController(text: widget.prayerTimes[0]['xufton']);
    xuftonTakbirController =
        TextEditingController(text: widget.prayerTimes[0]['xufton_takbir']);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Namoz Vaqtlarini Yangilash'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildRow('Bomdod', 'Bomdod Takbir', bomdodController,
                bomdodTakbirController),
            _buildRow('Peshin', 'Peshin Takbir', peshinController,
                peshinTakbirController),
            _buildRow('Asr', 'Asr Takbir', asrController, asrTakbirController),
            _buildRow(
                'Shom', 'Shom Takbir', shomController, shomTakbirController),
            _buildRow('Xufton', 'Xufton Takbir', xuftonController,
                xuftonTakbirController),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                // Show loading indicator
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  },
                  barrierDismissible: false,
                );
                // Perform async operation (e.g., updating data in Firestore)
                await _updatePrayerTimesInFirestore();
                // Close the loading indicator
                Navigator.pop(context);
                // Push to the new screen
                Navigator.pushNamed(context, './main/');
              },
              child: const Text('Tayyor'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(String label1, String label2,
      TextEditingController controller1, TextEditingController controller2) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller1,
            decoration: InputDecoration(labelText: label1),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: TextField(
            controller: controller2,
            decoration: InputDecoration(labelText: label2),
          ),
        ),
      ],
    );
  }

  Future<void> _updatePrayerTimesInFirestore() async {
    final prayerTimeSnapshot = await FirebaseFirestore.instance
        .collection('prayer_time')
        .where('masjid',
            isEqualTo: FirebaseFirestore.instance
                .collection('masjids')
                .doc(widget.point.documentId))
        .get();

    if (prayerTimeSnapshot.docs.isNotEmpty) {
      final prayerTimeDocRef = prayerTimeSnapshot.docs.first.reference;

      await prayerTimeDocRef.update({
        'bomdod': Timestamp.fromDate(
            DateFormat('HH:mm').parse(bomdodController.text)),
        'bomdod_takbir': Timestamp.fromDate(
            DateFormat('HH:mm').parse(bomdodTakbirController.text)),
        'peshin': Timestamp.fromDate(
            DateFormat('HH:mm').parse(peshinController.text)),
        'peshin_takbir': Timestamp.fromDate(
            DateFormat('HH:mm').parse(peshinTakbirController.text)),
        'asr':
            Timestamp.fromDate(DateFormat('HH:mm').parse(asrController.text)),
        'asr_takbir': Timestamp.fromDate(
            DateFormat('HH:mm').parse(asrTakbirController.text)),
        'shom':
            Timestamp.fromDate(DateFormat('HH:mm').parse(shomController.text)),
        'shom_takbir': Timestamp.fromDate(
            DateFormat('HH:mm').parse(shomTakbirController.text)),
        'xufton': Timestamp.fromDate(
            DateFormat('HH:mm').parse(xuftonController.text)),
        'xufton_takbir': Timestamp.fromDate(
            DateFormat('HH:mm').parse(xuftonTakbirController.text)),
        'created_at': Timestamp.fromDate(DateTime.now()),
      });
    }
  }
}
