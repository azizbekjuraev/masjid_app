import 'package:flutter/material.dart';
import 'package:masjid_app/examples/utils/show_alert_dialog.dart';
import 'package:masjid_app/examples/widgets/modal_body_view.dart';
import 'package:yandex_mapkit/yandex_mapkit.dart';
import 'package:masjid_app/examples/map_point.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:csv/csv.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:async' show Future;

typedef LocationLayerInitCallback = Future<void> Function();

class MapScreen extends StatefulWidget {
  final LocationLayerInitCallback? onLocationLayerInit;
  const MapScreen({super.key, this.onLocationLayerInit});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late final YandexMapController _mapController;
  late TextEditingController searchController;
  GlobalKey mapKey = GlobalKey();

  var collection = FirebaseFirestore.instance.collection('masjids');
  var prayerCollection = FirebaseFirestore.instance.collection('prayer_time');
  late List<MapPoint> items = [];
  late List<Map<String, dynamic>> prayerItems = [];
  List<MapPoint> originalItems = [];
  bool isLoaded = false;
  bool isSearchMode = false;
  int? _currentOpenModalIndex;

  // var _mapZoom = 0.0;
  CameraPosition? _userLocation;

  final animation =
      const MapAnimation(type: MapAnimationType.smooth, duration: 2.0);

  @override
  void initState() {
    super.initState();
    searchController = TextEditingController();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  List<MapPoint> getFilteredItems(String searchText) {
    if (searchText.isEmpty) {
      return originalItems;
    }
    return originalItems
        .where((item) =>
            item.name.toLowerCase().contains(searchText.toLowerCase()))
        .toList();
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
        originalItems = mapPoints;
        prayerItems = prayerTimes;
        isLoaded = true;
      });
    } catch (e) {
      if (!context.mounted) return;
      showAlertDialog(context, 'Error fetching data', '$e');
    }
  }

  Future<void> onLocationLayerInit() async {
    await _initLocationLayer();
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
    return items.asMap().entries.map((entry) {
      final index = entry.key;
      final point = entry.value;
      return PlacemarkMapObject(
        mapId: MapObjectId('MapObject $index'),
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
        onTap: (_, __) {
          // Check if another modal is already open
          if (_currentOpenModalIndex != null) {
            Navigator.pop(context); // Close the currently open modal
            // If the tapped marker is the same as the open one, clear the index
            if (_currentOpenModalIndex == index) {
              _currentOpenModalIndex = null;
              return;
            }
          }
          showModalBottomSheet(
            enableDrag: true,
            showDragHandle: true,
            context: context,
            builder: (context) => ModalBodyView(
              point: point,
              prayerTimes: _getPrayerTimesForLocation(point),
              onLocationLayerInit: onLocationLayerInit,
            ),
          ).whenComplete(() {
            _currentOpenModalIndex = null;
          });
          _currentOpenModalIndex = index;
        },
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
    double listViewHeight = items.length * 65.0;
    listViewHeight = listViewHeight.clamp(65.0, 207.0);
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: isSearchMode
            ? TextField(
                onChanged: (text) {
                  setState(() {
                    items = getFilteredItems(text);
                  });
                },
                controller: searchController,
                autofocus: true,
                decoration: const InputDecoration(
                    hintText: 'Qidirmoq...',
                    border: InputBorder.none,
                    hintStyle: TextStyle(color: Colors.black12)),
                style: const TextStyle(color: Colors.black),
              )
            : const FittedBox(child: Text('Masjidlar Takbir Vaqtlari')),
        actions: [
          IconButton(
            icon: isSearchMode
                ? const Icon(Icons.close)
                : const Icon(Icons.search),
            onPressed: () {
              setState(() {
                isSearchMode = !isSearchMode;
                searchController.text = '';
              });
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          YandexMap(
            onMapCreated: (controller) async {
              _mapController = controller;
              await _initLocationLayer();
              // await uploadToFirestore();
              // await uploadPrayerTimesToFirestore();
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
                  borderRadius: BorderRadius.circular(10)),
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
                  borderRadius: BorderRadius.circular(10)),
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
          IgnorePointer(
            ignoring: !isSearchMode,
            child: GestureDetector(
              onTap: () {
                FocusScope.of(context).unfocus();
                setState(() {
                  isSearchMode = !isSearchMode;
                });
              },
              child: Container(color: Colors.transparent),
            ),
          ),
          isSearchMode
              ? Positioned(
                  top: 0,
                  width: MediaQuery.of(context).size.width,
                  height: listViewHeight,
                  child: Container(
                    color: Colors.white,
                    child: ListView.builder(
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                            horizontalTitleGap: 3.0,
                            title: Text(items[index].name),
                            leading: const Icon(
                              Icons.location_on_sharp,
                              size: 32,
                            ),
                            onTap: () => cameraMover(
                                items[index].latitude, items[index].longitude));
                      },
                    ),
                  ))
              : Container(),
        ],
      ),
    );
  }

  Future<void> cameraMover(double latitude, double longitude) async {
    final Point point = Point(latitude: latitude, longitude: longitude);
    await _mapController
        .moveCamera(
          CameraUpdate.newCameraPosition(CameraPosition(target: point)),
        )
        .then((value) => setState(() {
              isSearchMode = !isSearchMode;
            }));
    //buni hali korib chiqaman!
    await _initLocationLayer();
  }
}
