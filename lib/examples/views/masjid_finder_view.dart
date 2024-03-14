import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class MasjidFinderView extends StatefulWidget {
  const MasjidFinderView({
    super.key,
  });

  @override
  _MasjidFinderViewState createState() => _MasjidFinderViewState();
}

class _MasjidFinderViewState extends State<MasjidFinderView> {
  bool _hasPermissions = false;
  double kaabaLatitude = 21.422487;
  double kaabaLongitude = 39.826206;
  Position? userLocation;
  @override
  void initState() {
    super.initState();
    getCurrentLocation();
    _fetchPermissionStatus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Qibla'),
      ),
      body: Builder(builder: (context) {
        if (_hasPermissions) {
          return SizedBox(
            width: 1000,
            height: 1000,
            child: _buildCompass(),
          );
        } else {
          return _buildPermissionSheet();
        }
      }),
    );
  }

  Widget _buildCompass() {
    return StreamBuilder<CompassEvent>(
      stream: FlutterCompass.events,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text('Error reading heading: ${snapshot.error}');
        }

        if (snapshot.connectionState == ConnectionState.waiting ||
            snapshot.data == null) {
          return const Center(
            child: CircularProgressIndicator.adaptive(),
          );
        }
        double? direction = snapshot.data?.heading;
        if (direction == null) {
          return const Center(
            child: Text("Device does not have sensors !"),
          );
        }

        double calculateAngle(
            double lat1, double lon1, double lat2, double lon2) {
          const double degreesPerRadian = 180.0 / math.pi;
          // const double radiansPerDegree = math.pi / 180.0;
          double dLon = (lon2 - lon1).abs();
          double y = math.sin(dLon) * math.cos(lat2);
          double x = math.cos(lat1) * math.sin(lat2) -
              math.sin(lat1) * math.cos(lat2) * math.cos(dLon);
          double angle = math.atan2(y, x);
          return (angle * degreesPerRadian + 360) % 360;
        }

        double calculateBearing(
            double heading, double latitude, double longitude) {
          double kaabaBearing = calculateAngle(
              latitude, longitude, kaabaLatitude, kaabaLongitude);
          kaabaBearing -= heading;
          return kaabaBearing;
        }

        double distanceToKaaba = calculateBearing(
            direction, userLocation!.latitude, userLocation!.longitude);

        return Material(
          // shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          elevation: 4.0,
          child: Container(
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
            ),
            child: Transform.rotate(
              angle: (distanceToKaaba * (math.pi / 180)),
              child: Image.asset(
                'assets/unnamed.png',
                width: 1000,
                height: 1000,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPermissionSheet() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Text('Location Permission Required'),
          ElevatedButton(
            child: const Text('Request Permissions'),
            onPressed: () {
              Permission.locationWhenInUse.request().then((ignored) {
                _fetchPermissionStatus();
              });
            },
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            child: const Text('Open App Settings'),
            onPressed: () {
              openAppSettings().then((opened) {
                //
              });
            },
          )
        ],
      ),
    );
  }

  void _fetchPermissionStatus() {
    Permission.locationWhenInUse.status.then((status) {
      if (mounted) {
        setState(() => _hasPermissions = status == PermissionStatus.granted);
      }
    });
  }

  Future<void> getCurrentLocation() async {
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    setState(() {
      userLocation = position;
      // print(position);
      // print(userLocation);
    });
  }
}
