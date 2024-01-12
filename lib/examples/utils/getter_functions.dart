import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:masjid_app/examples/map_point.dart';

List<Map<String, dynamic>> getPrayerTimes(
    List<QueryDocumentSnapshot> documents) {
  return documents.map((DocumentSnapshot document) {
    return document.data() as Map<String, dynamic>;
  }).toList();
}

List<MapPoint> getMapPoints(List<QueryDocumentSnapshot> documents) {
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
