/// Server side of `analytics.dart`: there is no browser, so nothing to send.
library;

/// See `analytics_web.dart`; a no-op here.
void track(String event, Map<String, Object?> properties) {}
