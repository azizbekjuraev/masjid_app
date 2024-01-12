import 'package:flutter/material.dart';

class PrayerTimeTable extends StatelessWidget {
  final List<Map<String, String>> prayerTimes;
  final TextStyle textStyle;
  final String title;
  final Color titleColor;
  final Color borderColor;
  final Color clockColor;
  final List<Widget> Function(Map<String, dynamic>, TextStyle, Color)
      buildCells;

  const PrayerTimeTable(
      {super.key,
      required this.prayerTimes,
      required this.textStyle,
      required this.title,
      required this.titleColor,
      required this.borderColor,
      required this.buildCells,
      required this.clockColor});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          title,
          style: TextStyle(color: titleColor),
        ),
        const SizedBox(height: 5),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 1.0),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            SizedBox(
              height: 120,
              width: 300,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      for (var time in prayerTimes)
                        ...buildCells(time, textStyle, clockColor),
                    ],
                  ),
                ],
              ),
            )
          ]),
        ),
        const SizedBox(height: 5),
      ],
    );
  }
}
