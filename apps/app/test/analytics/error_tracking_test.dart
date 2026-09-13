import 'package:emotely/analytics/error_tracking.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:posthog_flutter/posthog_flutter.dart';

void main() {
  group(withErrorTracking, () {
    test('captures uncaught errors only when asked, never records steps', () {
      final release = withErrorTracking(
        PostHogConfig('phc_test'),
        autocapture: true,
      );
      final debug = withErrorTracking(
        PostHogConfig('phc_test'),
        autocapture: false,
      );

      for (final (config, expected) in [(release, true), (debug, false)]) {
        expect(config.errorTrackingConfig.captureFlutterErrors, expected);
        expect(
          config.errorTrackingConfig.capturePlatformDispatcherErrors,
          expected,
        );
        expect(config.errorTrackingConfig.captureIsolateErrors, expected);
        // Steps are breadcrumbs of free text nothing here writes, kept in a
        // native buffer that outlives reset(); off until there is a policy.
        expect(config.errorTrackingConfig.exceptionSteps.enabled, isFalse);
        expect(config.beforeSend, [contentFreeExceptions]);
      }
    });
  });

  group(contentFreeExceptions, () {
    const needle = 'the day the sea turned violet';

    test(
      'withholds the message of every exception item but the known ones',
      () async {
        // The shape the SDK builds for an uncaught error: the wrapper and its
        // cause as items, the Flutter details alongside.
        final event = PostHogEvent(
          event: r'$exception',
          properties: {
            r'$exception_level': 'error',
            r'$exception_list': [
              {
                'type': 'StateError',
                'value': 'Bad state: could not render "$needle"',
                'mechanism': {'handled': false, 'type': 'FlutterError'},
                'stacktrace': {
                  'frames': [
                    {'function': 'build', 'in_app': true},
                  ],
                  'type': 'raw',
                },
              },
              {
                'type': 'FormatException',
                'value': 'Unexpected character: $needle',
                'mechanism': {'handled': false, 'type': 'FlutterError'},
              },
              {
                'type': 'AgentException',
                'value': 'AgentException(500): model unavailable',
                'mechanism': {'handled': true, 'type': 'generic'},
              },
              // Not the SDK's shape, so it can only be free text.
              'stray: $needle',
            ],
            'flutter_error_details': {
              'context': 'building Text("$needle")',
              'information': 'The relevant error-causing widget was: $needle',
              'library': 'widgets library',
              'error_summary': 'Bad state: $needle',
              'silent': false,
            },
            'step': 'session_round',
          },
        );

        final scrubbed = (await contentFreeExceptions(event))!;

        expect(scrubbed.event, r'$exception');
        expect(scrubbed.properties, {
          r'$exception_level': 'error',
          r'$exception_list': [
            {
              'type': 'StateError',
              'value': 'StateError (message withheld, ADR 0005)',
              'mechanism': {'handled': false, 'type': 'FlutterError'},
              'stacktrace': {
                'frames': [
                  {'function': 'build', 'in_app': true},
                ],
                'type': 'raw',
              },
            },
            {
              'type': 'FormatException',
              'value': 'FormatException (message withheld, ADR 0005)',
              'mechanism': {'handled': false, 'type': 'FlutterError'},
            },
            {
              'type': 'AgentException',
              'value': 'AgentException(500): model unavailable',
              'mechanism': {'handled': true, 'type': 'generic'},
            },
          ],
          'flutter_error_details': {
            'library': 'widgets library',
            'silent': false,
          },
          'step': 'session_round',
        });
        expect('${scrubbed.properties}', isNot(contains('violet')));
      },
    );

    test('leaves every other event alone', () async {
      final event = PostHogEvent(
        event: 'session_failed',
        properties: {'status_code': 429},
      );

      expect(await contentFreeExceptions(event), same(event));
      expect(event.properties, {'status_code': 429});
    });

    test('copes with an exception event carrying no list', () async {
      final event = PostHogEvent(event: r'$exception');

      expect(await contentFreeExceptions(event), same(event));
    });
  });
}
