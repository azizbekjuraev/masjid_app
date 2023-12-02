import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

void showSignOutConfirmationDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Sign Out Confirmation'),
        content: const Text('Are you sure you want to sign out?'),
        actions: <Widget>[
          TextButton(
            child: const Text('Cancel'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          TextButton(
            child: const Text('Sign Out'),
            onPressed: () async {
              try {
                // Display a CircularProgressIndicator to indicate the sign-out process
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (BuildContext context) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  },
                );

                await FirebaseAuth.instance.signOut();

                Future.delayed(const Duration(seconds: 1), () {
                  Navigator.pushNamed(context, './main/');
                });
              } catch (e) {
                // Handle the error
                print('Error signing out: $e');
              }
            },
          ),
        ],
      );
    },
  );
}
