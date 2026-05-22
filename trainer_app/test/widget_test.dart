// Basic smoke test for the Trainer App.
//
// Full unit tests live in shared/test/ (message_test, schedule_validator_test,
// session_duration_test). This file verifies the app widget can be created.

import 'package:flutter_test/flutter_test.dart';
import 'package:trainer_app/app.dart';

void main() {
  testWidgets('TrainerApp smoke test — renders without crashing', (tester) async {
    await tester.pumpWidget(const TrainerApp());
    // App should render the login screen since no user is logged in
    expect(find.text('WTF Trainer'), findsOneWidget);
  });
}
