/// Everything the app tells PostHog, and the one rule it all obeys: nothing a
/// user wrote ever leaves the device (ADR 0005). The event builders accept
/// ids, types, counts and status codes only; the error reporter withholds
/// every message it does not know to be content-free; and the SDK's own
/// uncaught-error path is filtered on the wire the same way.
library;

export 'src/auth_analytics.dart';
export 'src/consent_analytics.dart';
export 'src/error_reporter.dart';
export 'src/error_tracking.dart';
export 'src/journal_analytics.dart';
export 'src/register.dart';
export 'src/session_analytics.dart';
