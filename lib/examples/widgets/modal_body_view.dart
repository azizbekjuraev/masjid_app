import 'package:flutter/material.dart';
import 'package:masjid_app/examples/data/user_data.dart';
import 'package:masjid_app/examples/map_point.dart';
import 'package:masjid_app/examples/map_screen.dart';
import 'package:masjid_app/examples/styles/app_styles.dart';
import 'package:masjid_app/examples/utils/open_maps_sheet.dart';
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
                        onPressed: () async {
                          await openMapsSheet(context, widget.point.latitude,
                              widget.point.longitude, widget.point.name);
                        },
                        backgroundColor: AppStyles.backgroundColorGreen700,
                        foregroundColor: AppStyles.foregroundColorYellow,
                        child: const Icon(Icons.location_on_outlined),
                      ),
                    ),
                  ],
                ),
              ),
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
                              icon: Icon(
                                Icons.edit_outlined,
                                size: 15,
                                color: AppStyles.backgroundColorGreen700,
                              ),
                              label: const Text(
                                'Yangilash',
                              ),
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

  TextStyle myTextStyle = const TextStyle(fontSize: 15);
}
