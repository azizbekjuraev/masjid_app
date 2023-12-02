import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:masjid_app/examples/utils/signout_dialog.dart';
import 'package:masjid_app/examples/data/user_data.dart';

class DrowerWidgets {
  Widget appBarDrow(BuildContext context) {
    final displayName = UserData.getDisplayName();
    final currUser = FirebaseAuth.instance.currentUser;

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            accountName: Row(
              children: [if (displayName != null) Text(displayName)],
            ),
            accountEmail: Row(children: [
              if (currUser?.email != null) Text(currUser?.email as String)
            ]),
            currentAccountPicture: CircleAvatar(
              child: ClipOval(
                child: Image.network(
                  'https://cdn-icons-png.flaticon.com/512/4264/4264711.png',
                  fit: BoxFit.cover,
                  width: 90,
                  height: 90,
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
            decoration: const BoxDecoration(
              color: Colors.blue,
              image: DecorationImage(
                fit: BoxFit.fill,
                image: NetworkImage(
                    'https://mybayutcdn.bayut.com/mybayut/wp-content/uploads/Agency-Posts-Cover-B-01.jpg'),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.favorite),
            title: const Text('Favorites'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Friends'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.share),
            title: const Text('Share'),
            onTap: () {},
          ),
          const ListTile(
            leading: Icon(Icons.notifications),
            title: Text('Request'),
          ),
          ListTile(
            leading: const Icon(Icons.login),
            title: const Text('Tizimga Kirish'),
            onTap: () {
              Navigator.pushNamed(context, './login/');
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.description),
            title: const Text('Policies'),
            onTap: () {},
          ),
          const Divider(),
          ListTile(
            title: const Text('Exit'),
            leading: const Icon(Icons.exit_to_app),
            onTap: () async {
              try {
                showSignOutConfirmationDialog(context);
              } catch (e) {
                print("$e");
              }
            },
          ),
        ],
      ),
    );
  }
}
