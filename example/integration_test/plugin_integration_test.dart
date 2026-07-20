// Integration test: exercises the real platform channel end to end.
//
// WhiskrKit is fire-and-forget, so all that can be asserted from Dart is that
// the calls dispatch without throwing — outcomes are intentionally
// unobservable (see the plugin's design notes).

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:flutter_whiskrkit/flutter_whiskrkit.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('fire-and-forget calls dispatch without throwing', (
    WidgetTester tester,
  ) async {
    final plugin = FlutterWhiskrkit();
    await plugin.initialize('integration-test-key', withMockedSurveys: true);
    await plugin.present('welcome-toast');
    await plugin.checkAndPresent('choice-survey');
  });
}
