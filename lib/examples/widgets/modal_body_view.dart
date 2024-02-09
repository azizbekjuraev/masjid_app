import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:masjid_app/examples/data/user_data.dart';
import 'package:masjid_app/examples/map_point.dart';
import 'package:masjid_app/examples/map_screen.dart';
import 'package:masjid_app/examples/styles/app_styles.dart';
import 'package:masjid_app/examples/utils/edit_masjid_name.dart';
import 'package:masjid_app/examples/utils/open_maps_sheet.dart';
import 'package:masjid_app/examples/utils/show_alert_dialog.dart';
import 'package:masjid_app/examples/widgets/edit_prayer_times_screen.dart';
import 'package:masjid_app/examples/utils/analog_clock_builder.dart';
import 'package:masjid_app/examples/widgets/prayer_time_table.dart';
import 'package:toastification/toastification.dart';

class ModalBodyView extends StatefulWidget {
  const ModalBodyView(
      {super.key,
      required this.point,
      required this.prayerTimes,
      required this.onLocationLayerInit});
  final MapPoint point;
  final List<Map<String, String>> prayerTimes;
  final LocationLayerInitCallback onLocationLayerInit;
  @override
  State<ModalBodyView> createState() => _ModalBodyViewState();
}

class _ModalBodyViewState extends State<ModalBodyView> {
  String currentName = '';
  String currentId = '';
  bool isDeleting = false;

  @override
  void initState() {
    super.initState();
    currentName = widget.point.name;
    currentId = widget.point.documentId;
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double dynamicFontSize = screenWidth * 0.04;
    final currUser = UserData.getUserEmail();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: InteractiveViewer(
        minScale: 1,
        maxScale: 3,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: FittedBox(
                        child: Text(widget.point.name,
                            style: TextStyle(fontSize: dynamicFontSize)),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0),
                      child: FloatingActionButton.small(
                        elevation: 0,
                        onPressed: () async {
                          await openMapsSheet(context, widget.point.latitude,
                              widget.point.longitude, widget.point.name);
                        },
                        backgroundColor: AppStyles.backgroundColorGreen700,
                        foregroundColor: AppStyles.foregroundColorYellow,
                        child: const Icon(Icons.route),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              for (var time in widget.prayerTimes)
                Column(
                  children: [
                    PrayerTimeTable(
                      clockColor: Colors.black,
                      prayerTimes: widget.prayerTimes,
                      textStyle: myTextStyle,
                      title: 'Azon Vaqtlari',
                      titleColor: AppStyles.foregroundColorRed,
                      borderColor: AppStyles.backgroundColorGreen700,
                      buildCells: buildAzonPrayerTimeCells,
                    ),
                    PrayerTimeTable(
                      clockColor: Colors.black,
                      prayerTimes: widget.prayerTimes,
                      textStyle: myTextStyle,
                      title: 'Takbir Vaqtlari',
                      titleColor: AppStyles.foregroundColorBlue,
                      borderColor: AppStyles.backgroundColorGreen700,
                      buildCells: buildTakbirPrayerTimeCells,
                    ),
                    //Yangilash
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Visibility(
                            visible: currUser != null,
                            child: PopupMenuButton<void Function()>(
                              color: AppStyles.backgroundColorGreen700,
                              itemBuilder: (context) {
                                return [
                                  PopupMenuItem(
                                      value: () async {
                                        showDialog(
                                          context: context,
                                          builder: (BuildContext context) {
                                            return AlertDialog(
                                              title: const Text("Tasdiqlash"),
                                              content: const Text(
                                                  "Haqiqatan ham bu masjidni oʻchirib tashlamoqchimisiz?"),
                                              actions: [
                                                TextButton(
                                                  onPressed: () {
                                                    Navigator.pop(context);
                                                  },
                                                  child: const Text(
                                                      "Bekor qilish"),
                                                ),
                                                TextButton(
                                                  onPressed: () async {
                                                    showDialog(
                                                      context: context,
                                                      barrierDismissible: false,
                                                      builder: (BuildContext
                                                          context) {
                                                        return const Center(
                                                          child:
                                                              CircularProgressIndicator
                                                                  .adaptive(),
                                                        );
                                                      },
                                                    );
                                                    await deleteMasjid(widget
                                                        .point.documentId);

                                                    if (!context.mounted) {
                                                      return;
                                                    }
                                                    Navigator.pop(context);
                                                    Navigator.pop(context);
                                                  },
                                                  child:
                                                      const Text("Oʻchirish"),
                                                ),
                                              ],
                                            );
                                          },
                                        );
                                      },
                                      child: const Row(
                                        children: [
                                          Icon(
                                            Icons.delete,
                                            color:
                                                AppStyles.foregroundColorYellow,
                                          ),
                                          SizedBox(
                                            width: 5,
                                          ),
                                          Text(
                                            "Masjidni o'chirish",
                                            style: TextStyle(
                                                color: AppStyles
                                                    .foregroundColorYellow),
                                          )
                                        ],
                                      )),
                                  PopupMenuItem(
                                    value: () async {
                                      await showModalBottomSheet(
                                        isScrollControlled: true,
                                        showDragHandle: true,
                                        context: context,
                                        builder: (BuildContext context) {
                                          return SingleChildScrollView(
                                            child: Container(
                                              padding: EdgeInsets.only(
                                                bottom: MediaQuery.of(context)
                                                    .viewInsets
                                                    .bottom,
                                              ),
                                              child: EditModal(
                                                currentName: currentName,
                                                currentId: currentId,
                                                onNameUpdated: (newName) {
                                                  setState(() {
                                                    widget.point.name = newName;
                                                  });
                                                },
                                              ),
                                            ),
                                          );
                                        },
                                      );
                                    },
                                    child: const Row(children: [
                                      Icon(
                                        Icons.edit,
                                        color: AppStyles.foregroundColorYellow,
                                      ),
                                      SizedBox(
                                        width: 5,
                                      ),
                                      Text(
                                        "Masjid nomini o'zgartirish",
                                        style: TextStyle(
                                            color: AppStyles
                                                .foregroundColorYellow),
                                      ),
                                    ]),
                                  ),
                                  PopupMenuItem(
                                      value: () async {
                                        await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                EditPrayerTimesScreen(
                                              point: widget.point,
                                              prayerTimes: widget.prayerTimes,
                                              onLocationLayerInit:
                                                  widget.onLocationLayerInit,
                                            ),
                                          ),
                                        );
                                        // if (!context.mounted) return;
                                        // Navigator.pop(context);
                                      },
                                      child: const Row(
                                        children: [
                                          Icon(
                                            Icons.access_time,
                                            color:
                                                AppStyles.foregroundColorYellow,
                                          ),
                                          SizedBox(
                                            width: 5,
                                          ),
                                          Text(
                                            "Masjidni vaqtini yangilash",
                                            style: TextStyle(
                                                color: AppStyles
                                                    .foregroundColorYellow),
                                          )
                                        ],
                                      )),
                                ];
                              },
                              onSelected: (fn) => fn(),
                            ),
                          ),
                          Column(
                            children: [
                              const Text(
                                'Yangilangan sana:',
                              ),
                              Text(
                                '${time['created_at']}',
                                style: const TextStyle(
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> deleteMasjid(String masjidId) async {
    try {
      // Step 1: Delete prayer documents associated with the masjid
      await FirebaseFirestore.instance
          .collection('prayer_time')
          .where('masjid',
              isEqualTo: FirebaseFirestore.instance
                  .collection('masjids')
                  .doc(masjidId))
          .get()
          .then((querySnapshot) {
        for (var prayerDoc in querySnapshot.docs) {
          prayerDoc.reference.delete();
        }
      });

      // Step 2: Delete the masjid document
      await FirebaseFirestore.instance
          .collection('masjids')
          .doc(masjidId)
          .delete();

      if (!context.mounted) return;
      showAlertDialog(
          context,
          title: "🕌",
          "Siz ushbu masjidni o'chirib tashladingiz...",
          toastType: ToastificationType.success,
          toastAlignment: Alignment.topCenter,
          margin: const EdgeInsets.only(top: 28.0));
      Navigator.pop(context);
      widget.onLocationLayerInit();
    } catch (e) {
      debugPrint('Error deleting masjid and prayer documents: $e');
    }
  }

  TextStyle myTextStyle = const TextStyle(fontSize: 15);
}
