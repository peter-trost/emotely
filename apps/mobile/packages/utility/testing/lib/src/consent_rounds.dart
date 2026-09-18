import 'package:testing/src/supabase_stub.dart';

/// The endpoints the consent record uses, named once. The state is derived
/// on the server from the append-only history (ADR 0014), so the app asks
/// one question (`consent_stands`) and never walks the events itself.
const consentRead = 'POST /rest/v1/rpc/consent_stands';

/// Records a consent to the current wording.
const consentGrant = 'POST /rest/v1/rpc/record_consent';

/// Takes a consent back.
const consentWithdraw = 'POST /rest/v1/rpc/withdraw_consent';

/// What the server answers when consent stands, or does not.
AuthRound consentStands({bool granted = true}) => rpcReturned(granted);
