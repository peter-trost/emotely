import 'package:emotely/main.dart';
import 'package:emotely/session/view/session_page.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/helpers.dart';

void main() {
  group(EmotelyApp, () {
    testWidgets('opens straight into a session', (tester) async {
      final agent = AgentStub()..script([unreachable()]);

      await tester.pumpWidget(
        EmotelyApp(
          agentClient: agent.agentClient,
          analytics: AnalyticsSpy().analytics,
        ),
      );

      expect(find.byType(SessionPage), findsOneWidget);
      expect(find.text('Journaling session'), findsOneWidget);
    });
  });
}
