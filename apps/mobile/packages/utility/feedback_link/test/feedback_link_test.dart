import 'package:feedback_link/feedback_link.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:testing/testing.dart';

void main() {
  group(BuildInfo, () {
    const build = BuildInfo(
      version: '1.2.3',
      buildNumber: '42',
      platform: 'iOS',
      operatingSystemVersion: 'Version 18.5 (Build 22F76)',
    );

    test('addresses the feedback mail to hello@getemotely.com', () {
      expect(feedbackMailUri(build).scheme, 'mailto');
      expect(feedbackMailUri(build).path, feedbackAddress);
      expect(feedbackAddress, 'hello@getemotely.com');
    });

    test('names version, build, platform and OS version in the subject', () {
      expect(
        feedbackMailUri(build).queryParameters['subject'],
        'emotely feedback (1.2.3+42, iOS Version 18.5 (Build 22F76))',
      );
    });

    test('leaves the user a blank line above a footer of the same facts', () {
      final body = feedbackMailUri(build).queryParameters['body']!;

      expect(body, startsWith('\n\n'));
      expect(body, contains('App version: 1.2.3+42'));
      expect(body, contains('Platform: iOS'));
      expect(body, contains('OS version: Version 18.5 (Build 22F76)'));
    });

    test('carries nothing but the build facts it names', () {
      final uri = feedbackMailUri(
        const BuildInfo(
          version: '1.0.0',
          buildNumber: '1',
          platform: 'Android',
          operatingSystemVersion: '14',
          deviceModel: 'Pixel 8',
        ),
      );

      expect(uri.queryParameters.keys, ['subject', 'body']);
      expect(uri.queryParameters['body'], contains('Device: Pixel 8'));
    });

    test('omits the device line when the model is not known', () {
      expect(
        feedbackMailUri(build).queryParameters['body'],
        isNot(contains('Device:')),
      );
    });

    test('encodes the spaces and newlines the mail app must read back', () {
      final uri = feedbackMailUri(build);

      expect(uri.query, isNot(contains(' ')));
      expect(uri.query, isNot(contains('\n')));
      // Round-tripping is what the mail app does to the string it is handed.
      final reparsed = Uri.parse(uri.toString()).queryParameters;
      expect(reparsed['subject'], uri.queryParameters['subject']);
      expect(reparsed['body'], uri.queryParameters['body']);
    });

    test('reads the running platform when the app does not name one', () {
      final build = BuildInfo.ofPlatform(version: '1.0.0', buildNumber: '7');

      expect(build.version, '1.0.0');
      expect(build.buildNumber, '7');
      expect(build.platform, isNotEmpty);
      expect(build.operatingSystemVersion, isNotEmpty);
    });
  });

  group('registerFeedbackLink', () {
    test('registers the build the app hands in, as a singleton', () {
      final getIt = GetIt.asNewInstance();

      registerFeedbackLink(getIt, build: testBuildInfo);

      expect(getIt<BuildInfo>(), same(testBuildInfo));
      expect(getIt<BuildInfo>(), same(getIt<BuildInfo>()));
    });
  });

  group('openFeedbackMail', () {
    testWidgets('hands the mail app the prefilled message', (tester) async {
      final launcher = UrlLauncherSpy.setup();
      const build = BuildInfo(
        version: '2.0.0',
        buildNumber: '9',
        platform: 'iOS',
        operatingSystemVersion: '18.0',
      );

      await openFeedbackMail(build);

      expect(launcher.launched, [feedbackMailUri(build).toString()]);
    });
  });
}
