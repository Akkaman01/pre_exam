import 'package:flutter_test/flutter_test.dart';

import 'package:pre_exam/main.dart';

void main() {
  testWidgets('App loads home screen', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.text('Election Monitor'), findsOneWidget);
    expect(find.text('Open Report List'), findsOneWidget);
  });
}
