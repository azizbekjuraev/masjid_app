import 'package:flutter/material.dart';

void showAlertDialog(BuildContext context, String title, Object content,
    {bool showProgress = false}) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(title),
        content: showProgress
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 8),
                  Text(content as String),
                ],
              )
            : Text(content as String),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context, rootNavigator: true).pop(context);
            },
            child: const Text('OK'),
          ),
        ],
      );
    },
  );
}
