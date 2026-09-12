import 'dart:async';

import 'package:emotely_web/analytics.dart';
import 'package:emotely_web/environment.dart';
import 'package:emotely_web/waitlist.dart';
import 'package:http/http.dart' as http;
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:universal_web/web.dart' as web;

/// The second island: the page the confirmation mail links to. It reads the
/// token from the link, redeems it once, and says what happened. Nothing
/// to type, nothing to click; the click was the link.
///
/// Pre-rendered at build time too (static mode), where there is no window:
/// that render shows the "checking" state and the browser takes over.
//
// jaspr_builder parses @client files with analyzer 12, which cannot read a
// primary constructor yet, so this one file keeps the classic form.
// ignore_for_file: use_primary_constructors
// The classic form repeats the type name in the constructor; the fix this
// rule proposes is the primary constructor the builder cannot parse.
// ignore_for_file: unnecessary_type_name_in_constructor
@client
class ConfirmWaitlist extends StatefulComponent {
  const ConfirmWaitlist({super.key});

  @override
  State<ConfirmWaitlist> createState() => _ConfirmWaitlistState();
}

enum _Phase { checking, confirmed, unknown, failed }

class _ConfirmWaitlistState extends State<ConfirmWaitlist> {
  _Phase _phase = .checking;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      return;
    }
    final token = Uri.parse(web.window.location.href).queryParameters['t'];
    if (token == null || token.isEmpty) {
      _phase = .unknown;
      return;
    }
    unawaited(_confirm(token));
  }

  Future<void> _confirm(String token) async {
    final outcome = await confirmWaitlist(
      http.Client(),
      token: token,
      supabaseUrl: supabaseUrl,
      publishableKey: supabasePublishableKey,
    );
    switch (outcome) {
      case .confirmed:
        track('waitlist_confirmed', {});
      case .unknown:
        track('waitlist_confirm_refused', {'reason': 'unknown'});
      case .failed:
        track('waitlist_confirm_refused', {'reason': 'failed'});
    }
    setState(() {
      _phase = switch (outcome) {
        .confirmed => .confirmed,
        .unknown => .unknown,
        .failed => .failed,
      };
    });
  }

  @override
  Component build(BuildContext context) => switch (_phase) {
    .checking => const div(classes: 'confirm', [
      h1([.text('One moment')]),
      p([.text('Checking your link…')]),
    ]),
    .confirmed => const div(classes: 'confirm', [
      h1([.text('Confirmed. Your spot is held.')]),
      p([
        .text(
          'That was the last step. You will hear from hello@getemotely.com '
          'when early access opens for you, and from no one else.',
        ),
      ]),
    ]),
    .unknown => const div(classes: 'confirm', [
      h1([.text('This link is no longer valid')]),
      p([
        .text(
          'It was used already, is older than a week, or did not survive '
          'the trip into your mail app in one piece. ',
        ),
        a(href: '/', [.text('Sign up again')]),
        .text(' and a fresh one is on its way.'),
      ]),
    ]),
    .failed => const div(classes: 'confirm', [
      h1([.text('Something went wrong')]),
      p([.text('Reload this page to try again.')]),
    ]),
  };
}
