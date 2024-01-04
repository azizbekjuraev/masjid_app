import 'package:flutter/material.dart';
import 'package:masjid_app/examples/widgets/drawer_widget.dart';
import 'package:http/http.dart' as https;
import 'dart:convert';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    DrawerWidgets drawerWidgets = DrawerWidgets();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bosh sahifa'),
      ),
      body: Center(
        child: TextButton(
          onPressed: () {
            getData();
          },
          child: const Text('fetch data'),
        ),
      ),
      drawer: drawerWidgets.buildDrawer(context),
    );
  }
}

void getData() async {
  var url = Uri.parse('https://islomapi.uz/api/present/day?region=Namangan');
  var response = await https.get(url);
  Map data = jsonDecode(response.body); // this requires import dart:convert
  print(data);
}
