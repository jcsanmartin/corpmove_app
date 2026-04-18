import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:corpmove_app/main.dart';

void main() {
  testWidgets('La app inicia correctamente', (WidgetTester tester) async {
    await tester.pumpWidget(const CorpMoveApp());
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}