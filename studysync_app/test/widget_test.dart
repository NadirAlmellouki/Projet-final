import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:studysync_app/app.dart';

void main() {
  testWidgets('StudySync app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: StudySyncApp(),
      ),
    );
    expect(find.text('StudySync'), findsOneWidget);
  });
}
