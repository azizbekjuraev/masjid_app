import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> uploadPrayerTimesToFirestore() async {
  final masjids = FirebaseFirestore.instance.collection('masjids');
  final masjidDocuments = await masjids.get();

  for (var masjidDocument in masjidDocuments.docs) {
    final masjidRef = masjidDocument.reference;

    final existingPrayerTimes = await FirebaseFirestore.instance
        .collection('prayer_time')
        .where('masjid', isEqualTo: masjidRef)
        .get();
    print(existingPrayerTimes);
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
