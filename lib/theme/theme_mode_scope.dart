import 'package:flutter/material.dart';
import 'theme_mode_controller.dart';

class ThemeModeScope extends InheritedNotifier<ThemeModeController> {
  const ThemeModeScope({super.key, required ThemeModeController controller, required super.child})
      : super(notifier: controller);

  static ThemeModeController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<ThemeModeScope>();
    assert(scope != null, 'ThemeModeScope tidak ditemukan pada widget tree.');
    return scope!.notifier!;
  }
}
