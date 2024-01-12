import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:masjid_app/examples/map_point.dart';
import 'package:masjid_app/examples/map_screen.dart';
import 'package:toastification/toastification.dart';

class EditPrayerTimesScreen extends StatefulWidget {
  final MapPoint point;
  final List<Map<String, String>> prayerTimes;
  final LocationLayerInitCallback? onLocationLayerInit;

  const EditPrayerTimesScreen(
      {super.key,
      required this.point,
      required this.prayerTimes,
      this.onLocationLayerInit});

  @override
  EditPrayerTimesScreenState createState() => EditPrayerTimesScreenState();
}

class EditPrayerTimesScreenState extends State<EditPrayerTimesScreen> {
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
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const FittedBox(child: Text('Namoz Vaqtlarini Yangilash')),
      ),
      body: SingleChildScrollView(
        // keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildRow('Bomdod', 'Bomdod Takbir', bomdodController,
                  bomdodTakbirController),
              _buildRow('Peshin', 'Peshin Takbir', peshinController,
                  peshinTakbirController),
              _buildRow(
                  'Asr', 'Asr Takbir', asrController, asrTakbirController),
              _buildRow(
                  'Shom', 'Shom Takbir', shomController, shomTakbirController),
              _buildRow('Xufton', 'Xufton Takbir', xuftonController,
                  xuftonTakbirController),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  // Dismiss the keyboard
                  FocusScope.of(context).unfocus();
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
                  await _updatePrayerTimesInFirestore()
                      .then((value) => Navigator.pop(context))
                      .then((value) => toastification.show(
                            context: context,
                            type: ToastificationType.success,
                            style: ToastificationStyle.flat,
                            title: 'Vaqtlar muoffaqiyatli yangilandi!',
                            alignment: Alignment.bottomLeft,
                            autoCloseDuration: const Duration(seconds: 3),
                            borderRadius: BorderRadius.circular(12.0),
                            boxShadow: lowModeShadow,
                          ))
                      .then((value) => Navigator.pop(context));
                },
                child: const Text('Tayyor'),
              ),
            ],
          ),
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
    widget.onLocationLayerInit!();
  }
}
