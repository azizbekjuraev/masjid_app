import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';

void showAlertDialog(BuildContext context, String content,
    {bool showProgress = false,
    String title = "Xato",
    ToastificationType toastType = ToastificationType.error,
    EdgeInsets margin = const EdgeInsets.only(top: 25.0),
    Alignment toastAlignment = Alignment.topCenter}) {
  toastification.show(
    margin: margin,
    context: context,
    type: toastType,
    style: ToastificationStyle.flat,
    title: Text(title),
    description: Text(content),
    alignment: toastAlignment,
    autoCloseDuration: const Duration(seconds: 4),
    showProgressBar: showProgress,
    animationBuilder: (
      context,
      animation,
      alignment,
      child,
    ) {
      return FadeTransition(
        opacity: animation,
        child: child,
      );
    },
    borderRadius: BorderRadius.circular(12.0),
    boxShadow: highModeShadow,
  );
}
