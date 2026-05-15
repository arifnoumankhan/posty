import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:posty/posty.dart';

void main() {
  testWidgets('PostyScreen builds', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: PostyScreen(initialBaseUrl: 'https://httpbin.org')),
    );
    expect(find.text('Posty'), findsOneWidget);
    expect(find.text('Send'), findsOneWidget);
  });
}
