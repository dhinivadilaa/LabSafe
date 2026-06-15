import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:labsafe/main.dart';

void main() {
  testWidgets('LabSafe app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const LabSafeApp());
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
