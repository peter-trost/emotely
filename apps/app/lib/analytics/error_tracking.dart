/// PostHog error tracking, configured in one tested place (ADR 0004, ADR
/// 0005): which uncaught errors the SDK captures on its own, and the
/// content-free rule applied to every `$exception` event on its way out.
library;

import 'dart:async';

import 'package:posthog_flutter/posthog_flutter.dart';

/// Exception types whose `toString()` may leave the device: the agent's
/// own error message, transport errors that only name a host, and the
/// stand-in that already withheld its message. The wire counterpart of
/// `ErrorReporter.contentFree`; every other exception item goes out as its
/// type alone.
const forwardedTypes = {
  'AgentException',
  'ClientException',
  'TimeoutException',
  'WithheldException',
};

/// Configures [config] for error tracking. With [autocapture], uncaught
/// Flutter, platform-dispatcher and isolate errors are captured by the SDK;
/// off in debug runs so simulators and CI never fill the one production
/// project with overflow and assertion noise (handled failures are still
/// reported by `ErrorReporter`). Exception steps stay off: they are free
/// text nothing here writes yet, kept in a native buffer that a `reset()`
/// does not clear. [contentFreeExceptions] runs before anything is sent.
PostHogConfig withErrorTracking(
  PostHogConfig config, {
  required bool autocapture,
}) {
  config.errorTrackingConfig
    ..captureFlutterErrors = autocapture
    ..capturePlatformDispatcherErrors = autocapture
    ..captureIsolateErrors = autocapture
    ..exceptionSteps.enabled = false;
  config.beforeSend = [contentFreeExceptions];
  return config;
}

/// The content-free rule on the wire (ADR 0005), for the `$exception`
/// events the SDK builds itself from uncaught errors and as a backstop for
/// every other: each exception item keeps its type and frames but loses
/// its `value` unless the type is one of [forwardedTypes], and the Flutter
/// error details keep only the library and the silent flag — `context`,
/// `information` and `error_summary` are free text that can quote a widget's
/// content. Other events pass untouched.
FutureOr<PostHogEvent?> contentFreeExceptions(PostHogEvent event) {
  if (event.event != r'$exception') {
    return event;
  }
  final properties = event.properties;
  if (properties == null) {
    return event;
  }
  if (properties[r'$exception_list'] case final List<Object?> items) {
    // An item that is not the SDK's map shape can only be free text: gone.
    properties[r'$exception_list'] = [
      for (final item in items)
        if (item case final Map<String, Object?> item) _withheld(item),
    ];
  }
  if (properties['flutter_error_details']
      case final Map<String, Object?> details) {
    properties['flutter_error_details'] = {
      for (final key in const ['library', 'silent'])
        if (details[key] case final Object value) key: value,
    };
  }
  return event;
}

Map<String, Object?> _withheld(Map<String, Object?> item) {
  final type = item['type'];
  if (forwardedTypes.contains(type) || !item.containsKey('value')) {
    return item;
  }
  return {...item, 'value': '$type (message withheld, ADR 0005)'};
}
