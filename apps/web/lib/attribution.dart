/// Where a sign-up came from, as one short tag for the waitlist's `source`
/// column: `utm_source/utm_medium/utm_campaign` when the link carried UTM
/// parameters (see `.claude/skills/campaign-links`), otherwise the referrer
/// host, otherwise `landing`. Read from the current visit's URL only; nothing
/// is stored on the device, which is what keeps the site cookieless.
library;

/// The `source` column is `text` with a 64-character check in Postgres.
const sourceMaxLength = 64;

/// Builds the tag from the page's query string ([query], with or without a
/// leading `?`) and the document referrer ([referrer], may be empty).
String sourceFrom({required String query, required String referrer}) {
  final params = Uri(query: query.startsWith('?') ? query.substring(1) : query)
      .queryParameters;
  final utm = [
    params['utm_source'],
    params['utm_medium'],
    params['utm_campaign'],
  ].map(_clean).where((part) => part.isNotEmpty).toList();
  final String tag;
  if (utm.isNotEmpty) {
    tag = utm.join('/');
  } else {
    final host = Uri.tryParse(referrer)?.host ?? '';
    tag = host.isEmpty ? 'landing' : _clean(host);
  }
  return tag.length > sourceMaxLength ? tag.substring(0, sourceMaxLength) : tag;
}

/// Lowercase, trimmed, and only `[a-z0-9._-]`: whatever else the link
/// carried collapses to a single dash so the tag stays readable in a query.
String _clean(String? value) {
  if (value == null) {
    return '';
  }
  return value
      .trim()
      .toLowerCase()
      .replaceAll(_disallowed, '-')
      .replaceAll(_dashRun, '-')
      .replaceAll(_edgeDashes, '');
}

final _disallowed = RegExp('[^a-z0-9._-]+');
final _dashRun = RegExp('-{2,}');
final _edgeDashes = RegExp(r'^-+|-+$');
