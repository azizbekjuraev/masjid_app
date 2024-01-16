import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:map_launcher/map_launcher.dart';

Future<void> openMapsSheet(context, lat, long, masjidName) async {
  try {
    final coords = Coords(lat!, long!);
    final title = masjidName;
    final availableMaps = await MapLauncher.installedMaps;
    showModalBottomSheet(
      showDragHandle: true,
      context: context,
      builder: (BuildContext context) {
        double screenWidth = MediaQuery.of(context).size.width;
        double screenHeight = MediaQuery.of(context).size.height;
        return SafeArea(
          child: SizedBox(
            height: screenHeight * 0.8,
            width: screenWidth,
            child: Wrap(
              children: <Widget>[
                for (var map in availableMaps)
                  GestureDetector(
                    onTap: () => map.showMarker(
                      coords: coords,
                      title: title,
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(10.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SvgPicture.asset(
                            map.icon,
                            height: 50,
                            width: 50,
                          ),
                          const SizedBox(height: 8.0),
                          Text(
                            map.mapName,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  } catch (e) {
    debugPrint('$e');
  }
}
