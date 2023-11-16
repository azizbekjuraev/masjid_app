// launch_app.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/link.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:map_launcher/map_launcher.dart';

class LaunchApp extends StatelessWidget {
  const LaunchApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const LaunchAppHomePage(),
    );
  }
}

class LaunchAppHomePage extends StatefulWidget {
  const LaunchAppHomePage({Key? key}) : super(key: key);

  @override
  State<LaunchAppHomePage> createState() => _LaunchAppHomePageState();
}

class _LaunchAppHomePageState extends State<LaunchAppHomePage> {
  Future<void>? _launched;

  Future<void> _launchInApp(Uri url) async {
    if (!await launchUrl(url, mode: LaunchMode.inAppBrowserView)) {
      throw Exception('Could not launch $url');
    }
  }

  Widget _launchStatus(BuildContext context, AsyncSnapshot<void> snapshot) {
    if (snapshot.hasError) {
      return Text('Error: ${snapshot.error}');
    } else {
      return const Text('');
    }
  }

  @override
  Widget build(BuildContext context) {
    final double latitude = 55.755864;
    final double longitude = 37.617698;

    final Uri toLaunch = Uri(
        scheme: 'https',
        host: 'maps.google.com',
        path: '',
        queryParameters: {
          'daddr': '$latitude, $longitude',
        });

    return Scaffold(
      body: ListView(
        children: <Widget>[
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(toLaunch.toString()),
              ),
              ElevatedButton(
                onPressed: () => setState(() {
                  _launched = _launchInApp(toLaunch);
                }),
                child: const Text('Launch in app'),
              ),
              const Padding(padding: EdgeInsets.all(16.0)),
              const Padding(padding: EdgeInsets.all(16.0)),
              FutureBuilder<void>(future: _launched, builder: _launchStatus),
            ],
          ),
        ],
      ),
    );
  }
}
