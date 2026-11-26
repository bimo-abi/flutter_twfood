import 'package:flutter/material.dart';
import '../theme/theme_mode_scope.dart';
import '../theme/theme_mode_controller.dart';

/// Baris pengaturan tema yang dapat digunakan pada halaman Pelanggan dan Mitra.
class ThemeModeTile extends StatelessWidget {
  const ThemeModeTile({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = ThemeModeScope.of(context);
    return Card(
      elevation: 0,
      child: ListTile(
        leading: const Icon(Icons.palette_outlined),
        title: const Text('Tampilan aplikasi'),
        subtitle: Text(_label(controller.themeMode)),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () => _showThemePicker(context, controller),
      ),
    );
  }

  String _label(ThemeMode mode) => switch (mode) {
        ThemeMode.system => 'Mengikuti tema sistem HP',
        ThemeMode.light => 'Light Mode',
        ThemeMode.dark => 'Dark Mode',
      };

  Future<void> _showThemePicker(BuildContext context, ThemeModeController controller) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Tema aplikasi', style: Theme.of(sheetContext).textTheme.titleLarge),
              const SizedBox(height: 8),
              for (final option in <(ThemeMode, String, IconData)>[
                (ThemeMode.system, 'Ikuti tema sistem HP', Icons.settings_suggest_rounded),
                (ThemeMode.light, 'Light Mode', Icons.light_mode_rounded),
                (ThemeMode.dark, 'Dark Mode', Icons.dark_mode_rounded),
              ])
                RadioListTile<ThemeMode>(
                  value: option.$1,
                  groupValue: controller.themeMode,
                  secondary: Icon(option.$3),
                  title: Text(option.$2),
                  onChanged: (mode) async {
                    if (mode == null) return;
                    await controller.setThemeMode(mode);
                    if (sheetContext.mounted) Navigator.pop(sheetContext);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
