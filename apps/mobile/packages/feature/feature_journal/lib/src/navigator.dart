import 'package:flutter/widgets.dart';

/// What the journal asks of the app and cannot do itself, because a feature
/// never knows another feature (ADR 0015): the session and the consent
/// screen are other features' routes. Its own screens it reaches itself
/// (ADR 0016). The app implements this with those features' routes; a test
/// fakes it and records what was asked.
///
/// Every method takes the [BuildContext] of the tap that asked. The journal
/// awaits the server before it asks, so it checks `context.mounted` first:
/// a page that is gone by the time the server answers navigates nowhere.
abstract class JournalNavigator() {
  /// Runs a session on its own route — a new one, or with [resume] the id
  /// of the stored one, picked up where the journal left it — and completes
  /// when the route is popped, finished or not. Only the id travels; the
  /// session reads the stored round back itself.
  Future<void> startSession(BuildContext context, {String? resume});

  /// Asks for the explicit consent a session needs, on its own route, and
  /// answers whether it now stands. Anything else — a refusal, a failed
  /// write, a dismissed screen — is `false`; what the user is told about it
  /// is the app's, since the app owns the consent screen and its words.
  Future<bool> requestConsent(BuildContext context);
}
