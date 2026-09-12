@TestOn('browser')
library;

import 'package:emotely_web/components/waitlist_form.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_test/client_test.dart';

/// Runs [body] with every `http.Client()` the form creates answering
/// [status]; what the form sent is collected in [seen].
Future<void> withApi(
  Future<void> Function() body, {
  required List<http.Request> seen,
  int status = 201,
}) => http.runWithClient(
  body,
  () => MockClient((request) async {
    seen.add(request);
    return http.Response('', status);
  }),
);

void main() {
  group('WaitlistForm', () {
    testClient('a valid address is sent once and the reader is thanked', (
      tester,
    ) async {
      final seen = <http.Request>[];
      await withApi(seen: seen, () async {
        tester.pumpComponent(const WaitlistForm());
        await tester.input(
          find.byKey(const Key('email')),
          value: 'alice@example.com',
        );
        await tester.click(find.byKey(const Key('join')));
        await pumpEventQueue();

        expect(seen, hasLength(1));
        expect(seen.single.body, contains('alice@example.com'));
        expect(find.textContaining("You're on the list"), findsOneComponent);
        expect(find.byKey(const Key('join')), findsNothing);
      });
    });

    testClient('an address that is not one never leaves the page', (
      tester,
    ) async {
      final seen = <http.Request>[];
      await withApi(seen: seen, () async {
        tester.pumpComponent(const WaitlistForm());
        await tester.input(
          find.byKey(const Key('email')),
          value: 'not an address',
        );
        await tester.click(find.byKey(const Key('join')));
        await pumpEventQueue();

        expect(seen, isEmpty);
        expect(
          find.textContaining("doesn't look like an email"),
          findsOneComponent,
        );
        expect(find.byKey(const Key('join')), findsOneComponent);
      });
    });

    testClient('a rate-limited reader is told to come back later', (
      tester,
    ) async {
      final seen = <http.Request>[];
      await withApi(seen: seen, status: 429, () async {
        tester.pumpComponent(const WaitlistForm());
        await tester.input(
          find.byKey(const Key('email')),
          value: 'bob@example.com',
        );
        await tester.click(find.byKey(const Key('join')));
        await pumpEventQueue();

        expect(find.textContaining('Too many sign-ups'), findsOneComponent);
        expect(find.byKey(const Key('join')), findsOneComponent);
      });
    });

    testClient('a failure invites a retry and keeps the form', (tester) async {
      final seen = <http.Request>[];
      await withApi(seen: seen, status: 503, () async {
        tester.pumpComponent(const WaitlistForm());
        await tester.input(
          find.byKey(const Key('email')),
          value: 'carol@example.com',
        );
        await tester.click(find.byKey(const Key('join')));
        await pumpEventQueue();

        expect(find.textContaining('Something went wrong'), findsOneComponent);
        expect(find.byKey(const Key('join')), findsOneComponent);
      });
    });

    testClient(
      'a bot that fills the hidden field gets a thank-you and nothing is sent',
      (tester) async {
        final seen = <http.Request>[];
        await withApi(seen: seen, () async {
          tester.pumpComponent(const WaitlistForm());
          await tester.input(
            find.byKey(const Key('email')),
            value: 'bot@example.com',
          );
          await tester.input(
            find.byKey(const Key('website')),
            value: 'https://spam.example',
          );
          await tester.click(find.byKey(const Key('join')));
          await pumpEventQueue();

          expect(seen, isEmpty);
          expect(find.textContaining("You're on the list"), findsOneComponent);
        });
      },
    );
  });
}
