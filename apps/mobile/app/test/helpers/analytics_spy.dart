import 'dart:async';

import 'package:emotely/analytics/auth_analytics.dart';
import 'package:emotely/analytics/consent_analytics.dart';
import 'package:emotely/analytics/error_reporter.dart';
import 'package:emotely/analytics/journal_analytics.dart';
import 'package:emotely/analytics/session_analytics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:testing/testing.dart';

/// One captured PostHog event as `{'event': name, 'properties': {...}}` —
/// a map, so `expect` compares it deeply (records would compare maps by
/// identity).
typedef CapturedEvent = Map<String, Object>;

/// One exception the app would send to PostHog error tracking.
class const CapturedException({
  required final Object error,
  required final StackTrace? stackTrace,
  required final Map<String, Object> properties,
});

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
      posthog.captureException(
        error: anyNamed('error'),
        stackTrace: anyNamed('stackTrace'),
        properties: anyNamed('properties'),
      ),
    ).thenAnswer((invocation) {
      exceptions.add(
        CapturedException(
          error: invocation.namedArguments[#error] as Object,
          stackTrace: invocation.namedArguments[#stackTrace] as StackTrace?,
          properties:
              invocation.namedArguments[#properties] as Map<String, Object>? ??
              const <String, Object>{},
        ),
      );
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

  /// The exceptions the app reported, in order.
  final exceptions = <CapturedException>[];

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

  /// The [ConsentAnalytics] the app is given.
  ConsentAnalytics get consentAnalytics => ConsentAnalytics(posthog: posthog);

  /// The [ErrorReporter] the app is given.
  ErrorReporter get errorReporter => ErrorReporter(posthog: posthog);

  /// Every string that would leave the device: event names, properties,
  /// identities, and each reported exception's type, text, causes,
  /// properties and stack trace.
  Iterable<String> get outgoingStrings sync* {
    yield* identified;
    for (final event in events) {
      yield event['event']! as String;
      yield* _strings(event['properties']! as Map<String, Object>);
    }
    for (final exception in exceptions) {
      yield* _errorStrings(exception.error, Set.identity());
      yield '${exception.stackTrace}';
      yield* _strings(exception.properties);
    }
  }

  static Iterable<String> _strings(Map<String, Object> properties) sync* {
    for (final MapEntry(:key, :value) in properties.entries) {
      yield key;
      yield '$value';
    }
  }

  /// The SDK appends an error's causes as further exception items: an
  /// [AsyncError]'s error, every failure of a [ParallelWaitError], and a
  /// duck-typed `cause` getter. Mirror that walk, cycle-guarded.
  static Iterable<String> _errorStrings(Object error, Set<Object> seen) sync* {
    if (!seen.add(error)) {
      return;
    }
    yield '${error.runtimeType}';
    yield '$error';
    for (final cause in _causes(error)) {
      yield* _errorStrings(cause, seen);
    }
  }

  static Iterable<Object> _causes(Object error) sync* {
    switch (error) {
      case AsyncError(:final error):
        yield error;
      case ParallelWaitError<Object?, Object?>(:final errors):
        if (errors case final Iterable<Object?> errors) {
          yield* errors.nonNulls;
        }
      default:
        final Object? cause;
        try {
          cause = (error as dynamic).cause as Object?;
          // The SDK probes the getter exactly like this; an error without
          // one is the normal case, not a bug to surface.
          // ignore: avoid_catching_errors
        } on NoSuchMethodError {
          return;
        }
        if (cause != null) {
          yield cause;
        }
    }
  }
}

/// A captured event literal, for readable expectations.
CapturedEvent event(String name, [Map<String, Object> properties = const {}]) =>
    {'event': name, 'properties': properties};

/// Matches a reported exception: [error] itself (or its content-free
/// stand-in), with exactly [properties] and a stack trace attached.
Matcher captured(Object error, Map<String, Object> properties) =>
    isA<CapturedException>()
        .having((captured) => captured.error, 'error', error)
        .having((captured) => captured.properties, 'properties', properties)
        .having((captured) => captured.stackTrace, 'stackTrace', isNotNull);

/// What a [type] of exception looks like once its message is withheld.
WithheldException withheld(Type type, {String? code, int? statusCode}) =>
    WithheldException(type, code: code, statusCode: statusCode);
