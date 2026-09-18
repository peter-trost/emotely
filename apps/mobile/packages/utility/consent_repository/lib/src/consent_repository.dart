import 'package:supabase_flutter/supabase_flutter.dart';

/// The app's side of the consent record: whether the signed-in user has
/// agreed to [version] of the notice, and the two writes that change that.
/// Read from the server, never from the device — a local flag would not
/// survive a reinstall and would not be the proof Art. 7 (1) asks the
/// controller for.
///
/// [version] names the wording the app currently asks consent for; the app
/// owns the wording and its version (it is user-facing copy), this package
/// only records agreement to it.
class const ConsentRepository({
  required final SupabaseClient supabase,
  required final String version,
}) {
  /// Whether consent to [version] stands right now.
  ///
  /// The server derives this from the latest event, so the app never walks
  /// the history itself. False covers three cases the screen does not need
  /// to tell apart: never asked, withdrawn, and consented to an older
  /// wording only. All three mean the same thing — ask before the next
  /// session.
  Future<bool> isGranted() =>
      supabase.rpc<bool>('consent_stands', params: {'version': version});

  /// Records consent to the current wording. Idempotent on the server, so a
  /// double tap or a retry writes one row.
  Future<void> grant() =>
      supabase.rpc<void>('record_consent', params: {'version': version});

  /// Takes it back (Art. 7 (3)). Idempotent, and harmless if no consent was
  /// ever recorded.
  Future<void> withdraw() =>
      supabase.rpc<void>('withdraw_consent', params: {'version': version});
}
