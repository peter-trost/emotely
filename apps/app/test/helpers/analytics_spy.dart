import 'package:emotely/analytics/session_analytics.dart';
import 'package:mockito/mockito.dart';

import '../mocks.mocks.dart';

/// One captured PostHog event as `{'event': name, 'properties': {...}}` —
/// a map, so `expect` compares it deeply (records would compare maps by
/// identity).
typedef CapturedEvent = Map<String, Object>;

/// Records everything the app would send to PostHog.
class AnalyticsSpy() {
  final MockPosthog posthog = MockPosthog();
  final events = <CapturedEvent>[];

  /// The [SessionAnalytics] the app is given.
  SessionAnalytics get analytics {
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
    return SessionAnalytics(posthog: posthog);
  }

  /// Every string that would leave the device, event names included.
  Iterable<String> get outgoingStrings sync* {
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
