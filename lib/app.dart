import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/bass_builder_screen.dart';
import 'services/port_preset_service.dart';
import 'state/bass_builder_controller.dart';
import 'theme/app_theme.dart';

class BassBuilderApp extends StatelessWidget {
  const BassBuilderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => BassBuilderController()..initialize()),
        ChangeNotifierProvider(create: (_) => PortPresetService()..load()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Bass Builder',
        theme: AppTheme.theme,
        home: const BassBuilderScreen(),
      ),
    );
  }
}