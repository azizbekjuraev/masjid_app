import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csv/csv.dart';
import 'package:flutter/services.dart' show rootBundle;

Future<void> uploadMasjidsToFirestore() async {
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
