import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:map_launcher/map_launcher.dart';
import 'package:masjid_app/examples/data/user_data.dart';
import 'package:masjid_app/examples/map_point.dart';
import 'package:masjid_app/examples/map_screen.dart';
import 'package:masjid_app/examples/utils/show_alert_dialog.dart';
import 'package:masjid_app/examples/widgets/edit_prayer_times_screen.dart';
import 'package:masjid_app/examples/utils/analog_clock_builder.dart';
import 'package:masjid_app/examples/widgets/prayer_time_table.dart';

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
  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double dynamicFontSize = screenWidth * 0.04;
    final currUser = FirebaseAuth.instance.currentUser;
    final userEmail = UserData.getUserEmail();

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
                        onPressed: () async {
                          await _openMapsSheet(context);
                        },
                        child: const Icon(Icons.location_on_outlined),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 5),
              for (var time in widget.prayerTimes)
                Column(
                  children: [
                    PrayerTimeTable(
                      prayerTimes: widget.prayerTimes,
                      textStyle: myTextStyle,
                      title: 'Azon Vaqtlari',
                      titleColor: Colors.redAccent,
                      borderColor: Colors.black,
                      buildCells: buildAzonPrayerTimeCells,
                    ),
                    PrayerTimeTable(
                      prayerTimes: widget.prayerTimes,
                      textStyle: myTextStyle,
                      title: 'Takbir Vaqtlari',
                      titleColor: Colors.blueAccent,
                      borderColor: Colors.black,
                      buildCells: buildTakbirPrayerTimeCells,
                    ),
                    //Yangilash
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Visibility(
                            visible: currUser?.email == userEmail &&
                                currUser?.email != null,
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => EditPrayerTimesScreen(
                                      point: widget.point,
                                      prayerTimes: widget.prayerTimes,
                                      onLocationLayerInit:
                                          widget.onLocationLayerInit,
                                    ),
                                  ),
                                );
                                if (!context.mounted) return;
                                Navigator.pop(context);
                              },
                              icon: const Icon(
                                Icons.edit_outlined,
                                size: 15,
                              ),
                              label: const Text('Yangilash'),
                            ),
                          ),
                          Column(
                            children: [
                              const Text(
                                'Yangilangan sana:',
                                style: TextStyle(color: Colors.deepPurple),
                              ),
                              Text(
                                '${time['created_at']}',
                                style: const TextStyle(fontSize: 15),
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

  TextStyle myTextStyle = const TextStyle(fontSize: 15);

  Future<void> _openMapsSheet(context) async {
    try {
      final coords = Coords(widget.point.latitude, widget.point.longitude);
      final title = widget.point.name;
      final availableMaps = await MapLauncher.installedMaps;

      showModalBottomSheet(
        context: context,
        builder: (BuildContext context) {
          return SafeArea(
            child: SingleChildScrollView(
              child: SizedBox(
                height: 150,
                child: Wrap(
                  children: <Widget>[
                    for (var map in availableMaps)
                      ListTile(
                        onTap: () => map.showMarker(
                          coords: coords,
                          title: title,
                        ),
                        title: Text(map.mapName),
                        leading: SvgPicture.asset(
                          map.icon,
                          height: 30,
                          width: 30,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    } catch (e) {
      showAlertDialog(context, 'Xatolik', '$e');
    }
  }
}
