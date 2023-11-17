import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MasjidsList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: MasjidsStreamBuilder(collection: 'masjids'),
    );
  }
}

class MasjidsStreamBuilder extends StatelessWidget {
  final String collection;

  const MasjidsStreamBuilder({required this.collection, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection(collection).snapshots(),
      builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.hasError) {
          return const Text('Error: Something went wrong');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        }

        return ListView(
          children: snapshot.data!.docs.map((DocumentSnapshot document) {
            final data = document.data() as Map<String, dynamic>;
            final name = data['name'] ?? '';
            final coords = data['coords'];

            print(data);

            // Check if 'coords' is a GeoPoint
            if (coords is GeoPoint) {
              double latitude = coords.latitude;
              double longitude = coords.longitude;
              return ListTile(
                title: Text(name),
                subtitle: Text('Lat $latitude, Long: $longitude'),
              );
            } else {
              return ListTile(
                title: Text(name),
                subtitle: const Text('Invalid coordinates format'),
              );
            }
          }).toList(),
        );
      },
    );
  }
}
