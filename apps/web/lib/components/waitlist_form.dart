import 'dart:async';

import 'package:emotely_web/analytics.dart';
import 'package:emotely_web/attribution.dart';
import 'package:emotely_web/environment.dart';
import 'package:emotely_web/waitlist.dart';
import 'package:http/http.dart' as http;
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:universal_web/web.dart' as web;

/// The one interactive island on the site: an address in, a thank-you out.
///
/// `@client` components take only serialisable parameters, so the HTTP
/// client is not injected; `http.Client()` honours `http.runWithClient`,
/// which is how tests put a fake behind it.
//
// jaspr_builder parses @client files with analyzer 12, which cannot read a
// primary constructor yet, so this one file keeps the classic form.
// ignore_for_file: use_primary_constructors
// The classic form repeats the type name in the constructor; the fix this
// rule proposes is the primary constructor the builder cannot parse.
// ignore_for_file: unnecessary_type_name_in_constructor
@client
class WaitlistForm extends StatefulComponent {
  const WaitlistForm({super.key});

  @override
  State<WaitlistForm> createState() => _WaitlistFormState();
}

enum _Phase { idle, sending, joined }

class _WaitlistFormState extends State<WaitlistForm> {
  var _email = '';
  // A field no person sees or fills; bots fill everything.
  var _website = '';
  _Phase _phase = .idle;
  String? _message;

  Future<void> _submit() async {
    final source = sourceFrom(
      query: web.window.location.search,
      referrer: web.document.referrer,
    );
    if (_website.isNotEmpty) {
      setState(() => _phase = .joined);
      return;
    }
    final email = _email.trim();
    if (!looksLikeEmail(email)) {
      track('waitlist_refused', {'source': source, 'reason': 'invalid'});
      setState(() => _message = "That doesn't look like an email address.");
      return;
    }
    setState(() {
      _phase = .sending;
      _message = null;
    });
    final client = http.Client();
    try {
      final outcome = await joinWaitlist(
        client,
        email: email,
        source: source,
        supabaseUrl: supabaseUrl,
        publishableKey: supabasePublishableKey,
      );
      if (outcome == .joined) {
        track('waitlist_joined', {'source': source});
      } else {
        track('waitlist_refused', {'source': source, 'reason': outcome.name});
      }
      setState(() {
        switch (outcome) {
          case .joined:
            _phase = .joined;
          case .tooMany:
            _phase = .idle;
            _message =
                'Too many sign-ups from your network right now. '
                'Try again in an hour.';
          case .rejected:
            _phase = .idle;
            _message = 'That address was refused. Check it and try again.';
          case .failed:
            _phase = .idle;
            _message = 'Something went wrong. Try again in a moment.';
        }
      });
    } finally {
      client.close();
    }
  }

  @override
  Component build(BuildContext context) {
    if (_phase == .joined) {
      return const div(classes: 'waitlist waitlist-done', [
        p(classes: 'waitlist-thanks', [
          .text(
            'Check your inbox: one click on the link there and your spot '
            'is held.',
          ),
        ]),
      ]);
    }
    return form(
      classes: 'waitlist',
      noValidate: true,
      events: {
        'submit': (event) {
          event.preventDefault();
          unawaited(_submit());
        },
      },
      [
        const label(htmlFor: 'waitlist-email', classes: 'sr-only', [
          .text('Email address'),
        ]),
        input<String>(
          key: const Key('email'),
          id: 'waitlist-email',
          type: .email,
          name: 'email',
          value: _email,
          onInput: (value) => _email = value,
          attributes: const {
            'placeholder': 'you@example.com',
            'autocomplete': 'email',
            'inputmode': 'email',
          },
        ),
        input<String>(
          key: const Key('website'),
          classes: 'hp',
          type: .text,
          name: 'website',
          value: _website,
          onInput: (value) => _website = value,
          attributes: const {
            'tabindex': '-1',
            'autocomplete': 'off',
            'aria-hidden': 'true',
          },
        ),
        button(
          key: const Key('join'),
          type: .submit,
          classes: 'cta',
          disabled: _phase == .sending,
          [
            .text(
              _phase == .sending ? 'Saving your spot…' : 'Get early access',
            ),
          ],
        ),
        if (_message case final message?)
          p(classes: 'waitlist-message', [.text(message)]),
        const p(classes: 'waitlist-consent', [
          .text(
            'One email when your spot opens, nothing else. '
            'Delete your address any time by writing to ',
          ),
          a(href: 'mailto:$contactEmail', [.text(contactEmail)]),
          .text('.'),
        ]),
      ],
    );
  }
}
