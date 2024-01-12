import 'dart:math';
import 'package:flutter/material.dart';
import 'package:masjid_app/examples/styles/app_styles.dart';
import 'package:masjid_app/examples/utils/get_prayer_times.dart';
import 'package:masjid_app/examples/utils/getter_functions.dart';
// ignore: unused_import
import 'package:masjid_app/examples/utils/upload_masjids_to_firestore.dart';
// ignore: unused_import
import 'package:masjid_app/examples/utils/upload_prayer_times_to_firestore.dart';
import 'package:masjid_app/examples/widgets/modal_body_view.dart';
import 'package:yandex_mapkit/yandex_mapkit.dart';
import 'package:masjid_app/examples/map_point.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
      List<MapPoint> mapPoints = getMapPoints(data.docs);
      List<Map<String, dynamic>> prayerTimes = getPrayerTimes(prayerData.docs);
      setState(() {
        items = mapPoints;
        originalItems = mapPoints;
        prayerItems = prayerTimes;
        isLoaded = true;
      });
    } catch (e) {
      if (!context.mounted) return;
      debugPrint("$e");
    }
  }

  Future<void> onLocationLayerInit() async {
    await _initLocationLayer();
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
    return getPrayerTimesForLocation(prayerItems, point.documentId);
  }

  // String formatTimestamp(Timestamp? timestamp) {
  //   return formatTimestamp(timestamp);
  // }

  // String formatFullTimestamp(Timestamp? timestamp) {
  //   return formatFullTimestamp(timestamp);
  // }

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
              // await uploadMasjidsToFirestore();
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
          // FloatingActionButton(
          //   tooltip: 'Find Closest Masjid',
          //   onPressed: () {
          //     _moveToClosestMasjid();
          //   },
          //   // Customize as needed
          //   child: const Icon(Icons.location_searching),
          // ),
          Positioned(
            bottom: 450.0,
            right: 5,
            child: FloatingActionButton.small(
              backgroundColor: AppStyles.backgroundColorWhite,
              foregroundColor: AppStyles.foregroundColorBlack,
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
              backgroundColor: AppStyles.backgroundColorWhite,
              foregroundColor: AppStyles.foregroundColorBlack,
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
              backgroundColor: AppStyles.backgroundColorGreen700,
              foregroundColor: AppStyles.foregroundColorYellow,
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
                    color: AppStyles.backgroundColorWhite,
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

  void _moveToClosestMasjid() async {
    if (_userLocation != null) {
      // Get the closest masjid to the user's location
      MapPoint closestMasjid = findClosestMasjid(
        _userLocation!.target.latitude,
        _userLocation!.target.longitude,
        items,
      );

      // Move the camera to the closest masjid's location
      // await _mapController.moveCamera(
      //   CameraUpdate.newCameraPosition(
      //     CameraPosition(
      //       target: Point(
      //         latitude: closestMasjid.latitude,
      //         longitude: closestMasjid.longitude,
      //       ),
      //     ),
      //   ),
      //   animation:
      //       const MapAnimation(type: MapAnimationType.smooth, duration: 2.0),
      // );

      // Get the prayer times for the closest masjid
      print(closestMasjid);
      List<Map<String, String>> prayerTimes =
          _getPrayerTimesForLocation(closestMasjid);

      // Print prayer times in the console
      print('Prayer Times for ${closestMasjid.name}:');
      print(prayerTimes);
    } else {
      // Handle the case when user location is not available
      print('User location not available');
    }
  }
}

MapPoint findClosestMasjid(
    double userLatitude, double userLongitude, List<MapPoint> masjids) {
  double minDistance = double.infinity;
  MapPoint closestMasjid = masjids.first;

  for (MapPoint masjid in masjids) {
    double distance = calculateDistance(
      userLatitude,
      userLongitude,
      masjid.latitude,
      masjid.longitude,
    );

    if (distance < minDistance) {
      minDistance = distance;
      closestMasjid = masjid;
    }
  }

  return closestMasjid;
}

double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
  const R = 6371.0; // Radius of the Earth in kilometers

  double dLat = radians(lat2 - lat1);
  double dLon = radians(lon2 - lon1);

  double a = sin(dLat / 2) * sin(dLat / 2) +
      cos(radians(lat1)) * cos(radians(lat2)) * sin(dLon / 2) * sin(dLon / 2);
  double c = 2 * atan2(sqrt(a), sqrt(1 - a));

  double distance = R * c; // Distance in kilometers

  return distance;
}

double radians(double degrees) {
  return degrees * pi / 180;
}
