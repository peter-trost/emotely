/// Browser side of `analytics.dart`.
library;

import 'dart:js_interop';
import 'dart:js_interop_unsafe';

/// Sends [event] with [properties] to `window.posthog` if it is loaded; a
/// no-op without a key (no script emitted) or when the script was blocked.
void track(String event, Map<String, Object?> properties) {
  final posthog = globalContext.getProperty<JSObject?>('posthog'.toJS);
  if (posthog == null) {
    return;
  }
  posthog.callMethod('capture'.toJS, event.toJS, properties.jsify());
}
