/// The one thing the site writes: an address into `public.waitlist`
/// (ADR 0011). Talks to the Supabase Data API directly with the publishable
/// key; the table's trigger owns validation, de-duplication and rate limits,
/// so this side only maps HTTP statuses to what the form should say.
library;

import 'dart:convert';

import 'package:http/http.dart' as http;

/// What happened to a sign-up, as far as the form needs to know.
enum JoinOutcome() {
  /// Stored (or already there — the API does not tell, on purpose).
  joined,

  /// Rate-limited (HTTP 429): try again later.
  tooMany,

  /// The address failed the table's checks (HTTP 400).
  rejected,

  /// Anything else, including no network: worth a retry.
  failed,
}

/// The cheap client-side check that keeps obvious typos from a round trip.
/// The table applies the same shape server-side.
bool looksLikeEmail(String value) => _emailShape.hasMatch(value);

final _emailShape = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

/// Adds [email] to the waitlist through [client].
Future<JoinOutcome> joinWaitlist(
  http.Client client, {
  required String email,
  required Uri supabaseUrl,
  required String publishableKey,
  String source = 'landing',
}) async {
  final http.Response response;
  try {
    response = await client.post(
      supabaseUrl.resolve('/rest/v1/waitlist'),
      headers: {
        'apikey': publishableKey,
        'authorization': 'Bearer $publishableKey',
        'content-type': 'application/json',
        // No select privilege on the table, so nothing could come back anyway.
        'prefer': 'return=minimal',
      },
      body: jsonEncode({'email': email, 'source': source}),
    );
  } on http.ClientException {
    return JoinOutcome.failed;
  }
  return switch (response.statusCode) {
    201 => JoinOutcome.joined,
    429 => JoinOutcome.tooMany,
    400 => JoinOutcome.rejected,
    _ => JoinOutcome.failed,
  };
}

/// What the confirm link led to.
enum ConfirmOutcome() {
  /// The address is confirmed, from this click.
  confirmed,

  /// The token matched no waiting row: already used, a week old, or made up.
  unknown,

  /// Anything else, including no network: worth a retry.
  failed,
}

/// Redeems the [token] from a confirmation mail through [client]: the
/// anon-callable RPC `confirm_waitlist` (ADR 0011) answers `true` exactly
/// once per row.
Future<ConfirmOutcome> confirmWaitlist(
  http.Client client, {
  required String token,
  required Uri supabaseUrl,
  required String publishableKey,
}) async {
  final http.Response response;
  try {
    response = await client.post(
      supabaseUrl.resolve('/rest/v1/rpc/confirm_waitlist'),
      headers: {
        'apikey': publishableKey,
        'authorization': 'Bearer $publishableKey',
        'content-type': 'application/json',
      },
      body: jsonEncode({'token': token}),
    );
  } on http.ClientException {
    return ConfirmOutcome.failed;
  }
  return switch (response.statusCode) {
    200 when response.body.trim() == 'true' => ConfirmOutcome.confirmed,
    // `false`, or a token Postgres would not even parse as a uuid.
    200 || 400 => ConfirmOutcome.unknown,
    _ => ConfirmOutcome.failed,
  };
}
