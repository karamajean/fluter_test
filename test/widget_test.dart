import 'package:flutter_test/flutter_test.dart';

import 'package:fluter_test/main.dart';

void main() {
  testWidgets('Counter increments and resets', (tester) async {
    await tester.pumpWidget(const DemoApp());

    expect(find.text('0'), findsOneWidget);
    await tester.tap(find.text('加一'));
    await tester.pump();
    expect(find.text('1'), findsOneWidget);

    await tester.tap(find.text('歸零'));
    await tester.pump();
    expect(find.text('0'), findsOneWidget);
  });
}
