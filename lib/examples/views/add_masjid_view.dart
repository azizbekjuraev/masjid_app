import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:masjid_app/examples/map_screen.dart';
import 'package:masjid_app/examples/styles/app_styles.dart';
import 'package:masjid_app/examples/utils/show_alert_dialog.dart';
import 'package:masjid_app/examples/utils/upload_prayer_times_to_firestore.dart';
import 'package:toastification/toastification.dart';
import 'package:yandex_mapkit/yandex_mapkit.dart';

class AddMasjidView extends StatefulWidget {
  final Point? newMasjidPoint;
  final LocationLayerInitCallback onLocationLayerInit;

  const AddMasjidView(
      {super.key,
      required this.newMasjidPoint,
      required this.onLocationLayerInit});

  @override
  AddMasjidViewState createState() => AddMasjidViewState();
}

class AddMasjidViewState extends State<AddMasjidView> {
  final TextEditingController _masjidNameController = TextEditingController();
  bool isLoading = false;

  Future<void> uploadToFirestore() async {
    try {
      setState(() {
        isLoading = true;
      });
      final CollectionReference masjids =
          FirebaseFirestore.instance.collection('masjids');

      var record = {
        'name': _masjidNameController.text,
        'coords': GeoPoint(
            widget.newMasjidPoint!.latitude, widget.newMasjidPoint!.longitude),
      };

      var existingDocs = await masjids
          .where('name', isEqualTo: _masjidNameController.text)
          .where(
            'coords',
            isEqualTo: GeoPoint(widget.newMasjidPoint!.latitude,
                widget.newMasjidPoint!.longitude),
          )
          .get();

      if (existingDocs.docs.isEmpty) {
        await masjids.add(record);
      }
      await uploadPrayerTimesToFirestore();
      widget.onLocationLayerInit();
      if (!context.mounted) return;
      // on success
      showAlertDialog(
          context,
          title: "Tabriklaymiz!",
          "Siz masjidlar ro'yxatiga yangi masjid qo'shdingiz...",
          toastType: ToastificationType.success,
          toastAlignment: Alignment.topCenter,
          margin: const EdgeInsets.only(top: 28.0));
      Navigator.pop(context);
    } catch (e) {
      debugPrint('$e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Masjid Qo'shish"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            isLoading
                ? Center(
                    child: LinearProgressIndicator(
                      backgroundColor: Colors.grey,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppStyles.backgroundColorGreen700,
                      ),
                    ),
                  )
                : Container(),
            Image.asset(
              'assets/mosque.png',
              width: 200,
              height: 200,
              fit: BoxFit.fill, // or BoxFit.contain, BoxFit.cover, etc.
            ),
            const SizedBox(
              height: 25,
            ),
            TextField(
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Masjid nomini kiriting...',
              ),
              controller: _masjidNameController,
              autocorrect: false,
              autofocus: true,
            ),
            const SizedBox(
              height: 25,
            ),
            SizedBox(
              width: 140,
              height: 50,
              child: FloatingActionButton(
                backgroundColor: AppStyles.backgroundColorGreen700,
                foregroundColor: AppStyles.foregroundColorYellow,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                onPressed: isLoading
                    ? null
                    : () async {
                        FocusScope.of(context).unfocus();
                        // Check if the masjid name is empty
                        if (_masjidNameController.text.trim().isEmpty) {
                          // Show a warning to the user
                          showAlertDialog(
                            context, "Avval masjid nomini kiriting...",
                            toastType: ToastificationType.warning,
                            toastAlignment: Alignment.topCenter,
                            // margin: const EdgeInsets.only(top: 35.0)
                          );
                        } else {
                          // Continue with the upload process
                          await uploadToFirestore();
                        }
                      },
                child: const Text("Qoshish"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
