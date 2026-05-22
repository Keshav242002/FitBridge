// Basic smoke test for the Guru App.
//
// Full unit tests live in shared/test/ (message_test, schedule_validator_test,
// session_duration_test). This file verifies the app widget can be created.

import 'package:flutter_test/flutter_test.dart';
import 'package:guru_app/app.dart';

void main() {
  testWidgets('GuruApp smoke test — renders without crashing', (tester) async {
    await tester.pumpWidget(const GuruApp());
    // App should render the onboarding screen since no user has onboarded
    expect(find.text('WTF Guru'), findsOneWidget);
  });
}
