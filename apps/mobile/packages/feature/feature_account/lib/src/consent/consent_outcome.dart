/// How the consent screen was left, as its route answers. A route that
/// pops without one of these was left without an answer — the back arrow,
/// or the way out of a failed read — and there is nothing to tell the user
/// that they do not already know.
enum ConsentOutcome() {
  /// Consent stands: the server recorded it before the screen closed.
  granted,

  /// The user said no, here, a moment ago. Not the same as having no
  /// record: the journal may truthfully say "Not now" and nothing else.
  declined,

  /// The user ticked the box and the record did not land. Telling someone
  /// who hit a network error that they chose "Not now" is untrue, so this
  /// is its own answer.
  writeFailed,
}
