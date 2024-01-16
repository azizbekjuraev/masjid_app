import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:masjid_app/examples/data/user_data.dart';
import 'package:masjid_app/examples/utils/show_alert_dialog.dart';
import 'package:toastification/toastification.dart';

void showSignOutConfirmationDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const FittedBox(child: Text('Chiqishni tasdiqlash')),
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
                Navigator.of(context).pop();
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
                Navigator.of(context).pop();
                await FirebaseAuth.instance
                    .signOut()
                    .then((value) => showAlertDialog(
                        context,
                        title: "Xayr. Salomat bo'ling!",
                        "Siz tizimdan muvaffaqiyatli chiqdingiz...",
                        toastType: ToastificationType.success,
                        toastAlignment: Alignment.bottomCenter,
                        margin: const EdgeInsets.only(bottom: 35.0)))
                    .then((value) => Navigator.of(context).pop());

                UserData.clearThePreferences();
              } catch (e) {
                // Handle the error
                debugPrint('Error signing out: $e');
              }
            },
          ),
        ],
      );
    },
  );
}
