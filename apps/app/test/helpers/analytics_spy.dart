import 'package:emotely/analytics/auth_analytics.dart';
import 'package:emotely/analytics/journal_analytics.dart';
import 'package:emotely/analytics/session_analytics.dart';
import 'package:mockito/mockito.dart';

import '../mocks.mocks.dart';

/// One captured PostHog event as `{'event': name, 'properties': {...}}` —
/// a map, so `expect` compares it deeply (records would compare maps by
/// identity).
typedef CapturedEvent = Map<String, Object>;

/// Records everything the app would send to PostHog.
class AnalyticsSpy() {
  this {
    when(
      posthog.capture(
        eventName: anyNamed('eventName'),
        properties: anyNamed('properties'),
      ),
    ).thenAnswer((invocation) {
      events.add({
        'event': invocation.namedArguments[#eventName] as String,
        'properties':
            invocation.namedArguments[#properties] as Map<String, Object>? ??
            const <String, Object>{},
      });
      return Future<void>.value();
    });
    when(
      posthog.identify(
        userId: anyNamed('userId'),
        userProperties: anyNamed('userProperties'),
        userPropertiesSetOnce: anyNamed('userPropertiesSetOnce'),
      ),
    ).thenAnswer((invocation) {
      identified.add(invocation.namedArguments[#userId] as String);
      return Future<void>.value();
    });
    when(posthog.reset()).thenAnswer((_) {
      resets++;
      return Future<void>.value();
    });
  }

  final posthog = MockPosthog();
  final events = <CapturedEvent>[];

  /// The user ids the app identified PostHog with, in order.
  final identified = <String>[];

  /// How often the app told PostHog to forget the user.
  var resets = 0;

  /// The [SessionAnalytics] the app is given.
  SessionAnalytics get analytics => SessionAnalytics(posthog: posthog);

  /// The [AuthAnalytics] the app is given.
  AuthAnalytics get authAnalytics => AuthAnalytics(posthog: posthog);

  /// The [JournalAnalytics] the app is given.
  JournalAnalytics get journalAnalytics => JournalAnalytics(posthog: posthog);

  /// Every string that would leave the device: event names, properties and
  /// identities.
  Iterable<String> get outgoingStrings sync* {
    yield* identified;
    for (final event in events) {
      yield event['event']! as String;
      final properties = event['properties']! as Map<String, Object>;
      for (final MapEntry(:key, :value) in properties.entries) {
        yield key;
        yield '$value';
      }
    }
  }
}

/// A captured event literal, for readable expectations.
CapturedEvent event(String name, [Map<String, Object> properties = const {}]) =>
    {'event': name, 'properties': properties};
