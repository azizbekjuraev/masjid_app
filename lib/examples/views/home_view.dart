import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:masjid_app/examples/constants/constants.dart';
import 'package:masjid_app/examples/utils/analog_clock_builder.dart';
import 'package:masjid_app/examples/widgets/drawer_widget.dart';
import 'package:masjid_app/examples/styles/app_styles.dart';
import 'package:masjid_app/models/prayer_times_model.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  _HomeViewState createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  String selectedCity = 'Toshkent'; // Default city

  PrayerData? prayerTimesData;

  @override
  void initState() {
    super.initState();
    // Don't call fetchPrayerTimesData here; it will be called by FutureBuilder
  }

  Future<PrayerData?> fetchPrayerTimesData() async {
    try {
      final response = await http.get(Uri.parse(
          'https://islomapi.uz/api/present/day?region=$selectedCity'));

      if (response.statusCode == 200) {
        return PrayerData.fromJson(json.decode(response.body));
      } else {
        throw Exception(
            'Failed to load prayer times. Status code: ${response.statusCode}');
      }
    } on SocketException catch (error) {
      return null;
    } on HttpException catch (error) {
      return null;
    } on Exception catch (error) {
      return null;
    }
  }

  Future<void> _refreshData() async {
    setState(() {
      fetchPrayerTimesData();
    });
  }

  Widget buildPrayerTimesUI() {
    DrawerWidgets drawerWidgets = DrawerWidgets();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Asosiy'),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(10.0),
          child: SizedBox(),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16.0),
                  color: AppStyles.backgroundColorGreen900),
              margin: const EdgeInsets.all(12.0),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: 120,
                    width: 300,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            PrayerTimes(
                                prayerName: "Tong",
                                prayerTimesData?.times?.tongSaharlik! ?? ''),
                            PrayerTimes(
                                prayerName: 'Quyosh',
                                prayerTimesData?.times?.quyosh! ?? ''),
                            PrayerTimes(
                                prayerName: 'Peshin',
                                prayerTimesData?.times?.peshin! ?? ''),
                            PrayerTimes(
                                prayerName: 'Asr',
                                prayerTimesData?.times?.asr! ?? ''),
                            PrayerTimes(
                                prayerName: 'Shom',
                                prayerTimesData?.times?.shomIftor! ?? ''),
                            PrayerTimes(
                                prayerName: 'Xufton',
                                prayerTimesData?.times?.hufton! ?? ''),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          dropdownColor: Colors.black,
                          value: selectedCity,
                          items: Constants.cities.map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(
                                value,
                                style: AppStyles.textStyleYellow,
                              ),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              setState(() {
                                selectedCity = newValue;
                              });
                              fetchPrayerTimesData();
                            }
                          },
                          isExpanded: false,
                          hint: const Text('Select City'),
                          icon: const Icon(
                            Icons.keyboard_arrow_down,
                            color: AppStyles.foregroundColorYellow,
                          ),
                        ),
                      ),
                      Column(
                        children: [
                          Text(
                            prayerTimesData?.weekday ?? '',
                            style: AppStyles.textStyleYellow,
                          ),
                          Text(
                            prayerTimesData?.date ?? '',
                            style: AppStyles.textStyleYellow,
                          ),
                        ],
                      )
                    ],
                  ),
                  const SizedBox(height: 10.0),
                ],
              ),
            ),
          ],
        ),
      ),
      drawer: drawerWidgets.buildDrawer(context),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PrayerData?>(
      future: fetchPrayerTimesData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(
              child: CircularProgressIndicator(
                color: AppStyles.backgroundColorGreen700,
              ),
            ),
          );
        } else if (snapshot.hasError || snapshot.data == null) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment
                    .center, // Ensure the column is centered vertically
                crossAxisAlignment: CrossAxisAlignment
                    .center, // Ensure the column is centered horizontally
                children: [
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text(
                      'Xato: Namoz vaqtlari yuklanmadi, Internetni tekshirib, qayta urinib koring!',
                      textAlign: TextAlign.center,
                    ),
                  ),
                  TextButton(
                    onPressed: () => _refreshData(),
                    child: const Icon(Icons.refresh_outlined),
                  )
                ],
              ),
            ),
          );
        } else {
          // Data is available, update the UI
          prayerTimesData = snapshot.data;
          return buildPrayerTimesUI();
        }
      },
    );
  }
}

class PrayerTimes extends StatelessWidget {
  final String itemName;
  final String prayerName;

  const PrayerTimes(this.itemName, {super.key, required this.prayerName});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          Text(
            prayerName,
            style: AppStyles.textStyleYellow,
          ),
          if (itemName.isNotEmpty)
            buildAnalogClock(itemName, AppStyles.foregroundColorYellow),
        ],
      ),
    );
  }
}
