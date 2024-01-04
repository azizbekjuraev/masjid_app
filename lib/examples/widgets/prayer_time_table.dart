import 'package:flutter/material.dart';

class PrayerTimeTable extends StatelessWidget {
  final List<Map<String, String>> prayerTimes;
  final TextStyle textStyle;
  final String title;
  final Color titleColor;
  final Color borderColor;
  final List<Widget> Function(Map<String, dynamic>, TextStyle) buildCells;

  const PrayerTimeTable({
    super.key,
    required this.prayerTimes,
    required this.textStyle,
    required this.title,
    required this.titleColor,
    required this.borderColor,
    required this.buildCells,
  });

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
          child: Table(
            defaultVerticalAlignment: TableCellVerticalAlignment.bottom,
            border: TableBorder.all(width: 0, color: borderColor),
            children: [
              TableRow(
                children: [
                  for (var time in prayerTimes)
                    ...buildCells(time, textStyle), // Use the builder function
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 5),
      ],
    );
  }
}
