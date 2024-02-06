import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:masjid_app/examples/data/user_data.dart';
import 'package:masjid_app/examples/styles/app_styles.dart';
import 'package:masjid_app/examples/utils/signout_dialog.dart';
import 'package:masjid_app/examples/utils/show_alert_dialog.dart';

class DrawerWidgets extends StatefulWidget {
  const DrawerWidgets({super.key});

  @override
  _DrawerWidgetsState createState() => _DrawerWidgetsState();
}

class _DrawerWidgetsState extends State<DrawerWidgets> {
  late Future<bool> internetConnection;
  late String currUser;

  @override
  void initState() {
    super.initState();
    currUser = UserData.getUserEmail() ?? "";
    internetConnection = isInternetConnected();
  }

  Future<bool> isInternetConnected() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  void updateCurrUser() {
    setState(() {
      currUser = UserData.getUserEmail() ?? "";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            accountName: Container(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: AppStyles.backgroundColorGreen700,
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: const Text(
                'Hush kelibsiz!',
                style: AppStyles.textStyleYellow,
              ),
            ),
            accountEmail: null,
            currentAccountPicture: CircleAvatar(
              child: ClipOval(
                child: FutureBuilder<bool>(
                  future: internetConnection,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const CircularProgressIndicator();
                    } else if (snapshot.hasError) {
                      return const Icon(Icons.error);
                    } else {
                      return snapshot.data == true
                          ? Image.network(
                              'https://cdn-icons-png.flaticon.com/512/4264/4264711.png',
                              fit: BoxFit.cover,
                              width: 90,
                              height: 90,
                            )
                          : Container();
                    }
                  },
                ),
              ),
            ),
            otherAccountsPictures: [
              IconButton(
                icon: const Icon(Icons.cancel),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
            decoration: BoxDecoration(
              color: AppStyles.backgroundColorGreen900,
              image: const DecorationImage(
                fit: BoxFit.fill,
                image: NetworkImage(
                    'https://mybayutcdn.bayut.com/mybayut/wp-content/uploads/Agency-Posts-Cover-B-01.jpg'),
              ),
            ),
          ),
          if (currUser.isEmpty)
            ListTile(
              leading: const Icon(Icons.login),
              title: const Text('Tizimga kirish'),
              onTap: () {
                Navigator.pushNamed(context, './login/');
              },
            ),
          if (currUser.isNotEmpty)
            ListTile(
              title: const Text('Tizimdan chiqish'),
              leading: const Icon(Icons.exit_to_app),
              onTap: () async {
                try {
                  showSignOutConfirmationDialog(context);
                } catch (e) {
                  showAlertDialog(context, 'Error');
                }
              },
            ),
        ],
      ),
    );
  }
}
