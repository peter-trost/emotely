import 'package:emotely/app/environment.dart';
import 'package:emotely/contract/contract.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/helpers.dart';
import '../session_robot.dart';

/// The force-update screen, driven through the real app: the server names
/// a minimum the running version does not meet.
void main() {
  group('update required', () {
    Round blocking() => awaiting(
      toolCallId: 'c1',
      question: SessionRobot.rate,
      minAppVersion: '9.0.0',
    );

    testWidgets('the update button opens the store', (tester) async {
      final launcher = UrlLauncherSpy.setup();
      final agent = AgentStub()..script([blocking()]);
      final robot = SessionRobot(tester, agent);
      await robot.launch();
      await robot.settle();

      await robot.tapUpdate();

      expect(launcher.launched, [storeUrl]);
    });

    testWidgets('blocks mid-session too, without posting anything more', (
      tester,
    ) async {
      final agent = AgentStub()
        ..script([
          awaiting(toolCallId: 'c1', question: SessionRobot.rate),
          completed(
            summary: 'never shown',
            answers: const {'q-rate': Answer.rating(7)},
            minAppVersion: '9.0.0',
          ),
        ]);
      final robot = SessionRobot(tester, agent);
      await robot.launch();
      await robot.settle();

      await robot.answerRating(7);

      expect(robot.updateRequired, findsOneWidget);
      expect(robot.summary, findsNothing);
      expect(agent.requests, hasLength(2));
    });

    testWidgets('analytics reports both versions and nothing else', (
      tester,
    ) async {
      final agent = AgentStub()..script([blocking()]);
      final robot = SessionRobot(tester, agent);
      await robot.launch();
      await robot.settle();

      expect(robot.analytics.events, [
        event('session_started'),
        event('update_required', {
          'min_app_version': '9.0.0',
          'app_version': AgentStub.appVersion,
        }),
      ]);
    });

    testWidgets('meets accessibility guidelines', (tester) async {
      final agent = AgentStub()..script([blocking()]);
      final robot = SessionRobot(tester, agent);

      await tester.expectMeetsAccessibilityGuidelines(
        robot.app,
        prepare: (tester) => robot.settle(),
      );
    });
  });
}
