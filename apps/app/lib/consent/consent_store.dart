import 'package:emotely/consent/consent_text.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// The app's side of the consent record: whether the signed-in user has
/// agreed to the current notice version, and the two writes that change
/// that. Read from the server, never from the device — a local flag would
/// not survive a reinstall and would not be the proof Art. 7 (1) asks the
/// controller for.
class const ConsentStore({required final SupabaseClient supabase}) {
  static const _consents = 'consents';

  /// Whether consent to [consentVersion] stands right now.
  ///
  /// False covers three cases the screen does not need to tell apart: never
  /// asked, withdrawn, and consented to an older wording only. All three
  /// mean the same thing — ask before the next session.
  Future<bool> isGranted() async {
    final row = await supabase
        .from(_consents)
        .select('withdrawn_at')
        .eq('version', consentVersion)
        .maybeSingle();
    return row != null && row['withdrawn_at'] == null;
  }

  /// Records consent to the current wording. Idempotent on the server, so a
  /// double tap or a retry writes one row.
  Future<void> grant() =>
      supabase.rpc<void>('record_consent', params: {'version': consentVersion});

  /// Takes it back (Art. 7 (3)). Idempotent, and harmless if no consent was
  /// ever recorded.
  Future<void> withdraw() => supabase.rpc<void>(
    'withdraw_consent',
    params: {'version': consentVersion},
  );
}
