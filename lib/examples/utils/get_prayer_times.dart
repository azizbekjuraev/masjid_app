import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:masjid_app/examples/map_point.dart';

List<Map<String, String>> getPrayerTimesForLocation(List<MapPoint> items,
    List<Map<String, dynamic>> prayerItems, String documentId) {
  var prayerTimes = prayerItems.where((prayerTime) {
    DocumentReference masjidRef = prayerTime['masjid'];
    String prayerTimeMasjidId = masjidRef.id;
    return prayerTimeMasjidId == documentId;
  }).toList();

  var formattedPrayerTimes = prayerTimes
      .map((prayerTime) => {
            'bomdod': formatTimestamp(prayerTime['bomdod']),
            'bomdod_takbir': formatTimestamp(prayerTime['bomdod_takbir']),
            'peshin': formatTimestamp(prayerTime['peshin']),
            'peshin_takbir': formatTimestamp(prayerTime['peshin_takbir']),
            'asr': formatTimestamp(prayerTime['asr']),
            'asr_takbir': formatTimestamp(prayerTime['asr_takbir']),
            'shom': formatTimestamp(prayerTime['shom']),
            'shom_takbir': formatTimestamp(prayerTime['shom_takbir']),
            'xufton': formatTimestamp(prayerTime['xufton']),
            'xufton_takbir': formatTimestamp(prayerTime['xufton_takbir']),
            'created_at': formatFullTimestamp(prayerTime['created_at']),
          })
      .toList();
  return formattedPrayerTimes;
}

String formatTimestamp(Timestamp? timestamp) {
  if (timestamp == null) {
    return 'N/A';
  } else {
    var formatter = DateFormat('hh:mm');
    return formatter.format(timestamp.toDate());
  }
}

String formatFullTimestamp(Timestamp? timestamp) {
  if (timestamp == null) {
    return 'N/A';
  } else {
    var formatter = DateFormat('yyyy-MM-dd hh:mm');
    return formatter.format(timestamp.toDate());
  }
}
