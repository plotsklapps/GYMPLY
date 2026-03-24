import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:toastification/toastification.dart';

// Instead of Snackbars, GYMPLY uses toastification package.
// These are toasts with a consistent look & feel.
class ToastService {
  static void showSuccess({
    required String title,
    required String subtitle,
  }) {
    toastification.show(
      type: ToastificationType.success,
      style: ToastificationStyle.flatColored,
      autoCloseDuration: const Duration(seconds: 5),
      title: Text(title),
      description: Text(subtitle),
      alignment: Alignment.topRight,
      direction: TextDirection.ltr,
      animationDuration: const Duration(milliseconds: 400),
      icon: const Icon(LucideIcons.circleCheck),
      showIcon: true,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(12),
      showProgressBar: true,
      closeOnClick: false,
      pauseOnHover: true,
      dragToClose: true,
      applyBlurEffect: false,
    );
  }

  static void showWarning({
    required String title,
    required String subtitle,
  }) {
    toastification.show(
      type: ToastificationType.warning,
      style: ToastificationStyle.flatColored,
      autoCloseDuration: const Duration(seconds: 5),
      title: Text(title),
      description: Text(subtitle),
      alignment: Alignment.topRight,
      direction: TextDirection.ltr,
      animationDuration: const Duration(milliseconds: 300),
      icon: const Icon(LucideIcons.circleCheck),
      showIcon: true,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(12),
      showProgressBar: true,
      closeOnClick: false,
      pauseOnHover: true,
      dragToClose: true,
      applyBlurEffect: false,
    );
  }

  static void showError({
    required String title,
    required String subtitle,
  }) {
    toastification.show(
      type: ToastificationType.error,
      style: ToastificationStyle.flatColored,
      autoCloseDuration: const Duration(seconds: 5),
      title: Text(title),
      description: Text(subtitle),
      alignment: Alignment.topRight,
      direction: TextDirection.ltr,
      animationDuration: const Duration(milliseconds: 300),
      icon: const Icon(LucideIcons.circleCheck),
      showIcon: true,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(12),
      showProgressBar: true,
      closeOnClick: false,
      pauseOnHover: true,
      dragToClose: true,
      applyBlurEffect: false,
    );
  }
}
