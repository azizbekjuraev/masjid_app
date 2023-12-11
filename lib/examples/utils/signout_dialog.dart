import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

void showSignOutConfirmationDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Chiqishni tasdiqlash'),
        content: const Text('Haqiqatan ham tizimdan chiqmoqchimisiz?'),
        actions: <Widget>[
          TextButton(
            child: const Text('Bekor qilish'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          TextButton(
            child: const Text('Tizimdan chiqish'),
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

                await FirebaseAuth.instance
                    .signOut()
                    .then((value) => Navigator.pushNamed(context, './main/'));

                // Future.delayed(const Duration(seconds: 1), () {
                //   Navigator.pushNamed(context, './main/');
                // });
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
