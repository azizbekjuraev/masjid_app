import 'package:flutter/material.dart';
import 'package:analog_clock/analog_clock.dart';

String removeSuffix(String prayer) {
  return prayer.replaceAll('_Takbir', '');
}

List<Widget> buildAzonPrayerTimeCells(
    Map<String, dynamic> time, TextStyle myTextStyle) {
  return [
    for (var prayer in ['Bomdod', 'Peshin', 'Asr', 'Shom', 'Xufton'])
      ...buildTableCell(prayer, time[prayer.toLowerCase()]!, myTextStyle),
  ];
}

List<Widget> buildTakbirPrayerTimeCells(
    Map<String, dynamic> time, TextStyle myTextStyle) {
  return [
    for (var prayer in [
      'Bomdod_Takbir',
      'Peshin_Takbir',
      'Asr_Takbir',
      'Shom_Takbir',
      'Xufton_Takbir'
    ])
      Column(
        children: [
          FittedBox(
            child: Text(
              removeSuffix(prayer),
              style: myTextStyle,
            ),
          ),
          buildAnalogClock(time[prayer.toLowerCase()]!, Colors.black),
        ],
      ),
  ];
}

List<Widget> buildTableCell(String label, String time, TextStyle myTextStyle) {
  return [
    Column(
      children: [
        FittedBox(
          child: Text(
            label,
            style: myTextStyle,
          ),
        ),
        buildAnalogClock(time, Colors.black),
      ],
    ),
  ];
}

Widget buildAnalogClock(String time, Color clockColor) {
  String dateTimeString = "2023-01-01 $time";

  return AnalogClock(
    width: 70,
    height: 70,
    decoration: const BoxDecoration(
      color: Colors.transparent,
    ),
    hourHandColor: clockColor,
    minuteHandColor: clockColor,
    numberColor: clockColor,
    showNumbers: true,
    showSecondHand: false,
    textScaleFactor: 2.4,
    showTicks: true,
    showDigitalClock: false,
    showAllNumbers: true,
    datetime: DateTime.parse(dateTimeString),
  );
}
