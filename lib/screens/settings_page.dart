import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_settings_controller.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettingsController>();
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          SwitchListTile.adaptive(
            title: const Text('Dark Mode'),
            subtitle: const Text('Toggle between dark and light theme'),
            value: settings.isDark,
            onChanged: (_) => settings.toggle(),
          ),
          const Divider(),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('Bass Builder'),
            subtitle: Text('Flutter edition — powered by Dart & fl_chart'),
          ),
        ],
      ),
    );
  }
}
