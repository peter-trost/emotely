import 'package:flutter/widgets.dart';

/// What the journal asks of the app and cannot do itself, because a feature
/// never knows another feature (ADR 0015): the session and the consent
/// screen are other features' routes. Its own screens it reaches itself
/// (ADR 0016). The app implements this with those features' routes; a test
/// fakes it and records what was asked.
///
/// The methods take the [NavigatorState] rather than a context, because
/// the journal captures it before it awaits the server and must not reach
/// back into a widget tree that may have moved on.
abstract class JournalNavigator() {
  /// Runs a session on its own route — a new one, or with [resume] the id
  /// of the stored one, picked up where the journal left it — and completes
  /// when the route is popped, finished or not. Only the id travels; the
  /// session reads the stored round back itself.
  Future<void> startSession(NavigatorState navigator, {String? resume});

  /// Asks for the explicit consent a session needs, on its own route, and
  /// answers whether it now stands. Anything else — a refusal, a failed
  /// write, a dismissed screen — is `false`; what the user is told about it
  /// is the app's, since the app owns the consent screen and its words.
  Future<bool> requestConsent(NavigatorState navigator);
}
