import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/bass_builder_screen.dart';
import 'state/bass_builder_controller.dart';
import 'theme/app_theme.dart';

class BassBuilderApp extends StatelessWidget {
  const BassBuilderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => BassBuilderController()..initialize(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Bass Builder',
        theme: AppTheme.theme,
        home: const BassBuilderScreen(),
      ),
    );
  }
}