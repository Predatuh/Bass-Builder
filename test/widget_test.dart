import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bass_builder_flutter/app.dart';

void main() {
  testWidgets('boots the Bass Builder app', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const BassBuilderApp());
    await tester.pump();

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
