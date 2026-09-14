import 'dart:async';

import 'package:emotely_web/analytics.dart';
import 'package:emotely_web/delete_account.dart';
import 'package:emotely_web/environment.dart';
import 'package:emotely_web/waitlist.dart' show looksLikeEmail;
import 'package:http/http.dart' as http;
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

/// The deletion form, for people who no longer have the app installed: an
/// address, the six-digit code that proves the mailbox is theirs, and the
/// account is gone. The same proof the app asks for, and the same
/// `delete_account()` call it makes.
///
/// Two states worth knowing about:
///
/// * An address with no account is answered exactly like one that has, so
///   the form cannot be used to find out who has an emotely account. The
///   copy on the code step is conditional for that reason ("if that
///   address has an account").
/// * Nothing is stored anywhere: the access token lives for the length of
///   the delete call and the page keeps no session, so there is nothing to
///   sign back in with when it is done.
//
// jaspr_builder parses @client files with analyzer 12, which cannot read a
// primary constructor yet, so this one file keeps the classic form.
// ignore_for_file: use_primary_constructors
// The classic form repeats the type name in the constructor; the fix this
// rule proposes is the primary constructor the builder cannot parse.
// ignore_for_file: unnecessary_type_name_in_constructor
@client
class DeleteAccountForm extends StatefulComponent {
  const DeleteAccountForm({super.key});

  @override
  State<DeleteAccountForm> createState() => _DeleteAccountFormState();
}

enum _Step { address, code, done }

class _DeleteAccountFormState extends State<DeleteAccountForm> {
  var _email = '';
  var _code = '';
  _Step _step = .address;
  var _busy = false;
  String? _message;

  Future<void> _sendCode() async {
    final email = _email.trim();
    if (!looksLikeEmail(email)) {
      setState(() => _message = "That doesn't look like an email address.");
      return;
    }
    setState(() {
      _busy = true;
      _message = null;
    });
    final client = http.Client();
    try {
      final outcome = await requestDeletionCode(
        client,
        email: email,
        supabaseUrl: supabaseUrl,
        publishableKey: supabasePublishableKey,
      );
      // No `source`, no address, no code: a deletion is not a campaign and
      // the event must not say whose account it was (ADR 0005).
      track('delete_code_requested', {'outcome': outcome.name});
      setState(() {
        _busy = false;
        switch (outcome) {
          // `sent` covers "no such account" too, on purpose.
          case .sent:
            _step = .code;
          case .tooMany:
            _message =
                'Too many requests from your network right now. '
                'Try again in an hour.';
          case .failed:
            _message = 'Something went wrong. Try again in a moment.';
        }
      });
    } finally {
      client.close();
    }
  }

  Future<void> _delete() async {
    final code = _code.trim();
    if (!looksLikeCode(code)) {
      setState(() => _message = 'The code is six digits.');
      return;
    }
    setState(() {
      _busy = true;
      _message = null;
    });
    final client = http.Client();
    try {
      final outcome = await deleteAccountWithCode(
        client,
        email: _email.trim(),
        code: code,
        supabaseUrl: supabaseUrl,
        publishableKey: supabasePublishableKey,
      );
      track('delete_account_web', {'outcome': outcome.name});
      setState(() {
        _busy = false;
        switch (outcome) {
          case .deleted:
            _step = .done;
          case .badCode:
            _message =
                'That code did not match, or it is older than ten '
                'minutes. Check the newest email and try again.';
          case .failed:
            _message = 'Something went wrong. Try again in a moment.';
        }
      });
    } finally {
      client.close();
    }
  }

  @override
  Component build(BuildContext context) => switch (_step) {
    .address => _addressStep(),
    .code => _codeStep(),
    .done => const div(classes: 'delete-account delete-account-done', [
      h2([.text('Your account is gone')]),
      p([
        .text(
          'The account and everything in it — every entry, every session, '
          'the address itself — was deleted just now. Nothing is kept, so '
          'there is nothing left to undo and nothing to sign in to. If you '
          'come back one day, you start fresh.',
        ),
      ]),
    ]),
  };

  Component _addressStep() => form(
    classes: 'delete-account',
    noValidate: true,
    events: {
      'submit': (event) {
        event.preventDefault();
        unawaited(_sendCode());
      },
    },
    [
      const label(htmlFor: 'delete-email', [
        .text('The email address of the account'),
      ]),
      input<String>(
        key: const Key('email'),
        id: 'delete-email',
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
      button(
        key: const Key('send-code'),
        type: .submit,
        classes: 'cta',
        disabled: _busy,
        [.text(_busy ? 'Sending the code…' : 'Send me a code')],
      ),
      if (_message case final message?)
        p(classes: 'delete-account-message', [.text(message)]),
    ],
  );

  Component _codeStep() => form(
    classes: 'delete-account',
    noValidate: true,
    events: {
      'submit': (event) {
        event.preventDefault();
        unawaited(_delete());
      },
    },
    [
      // Conditional on purpose: saying "we sent you a code" would tell a
      // stranger that this address has an emotely account.
      const p([
        .text(
          'If that address has an account, a six-digit code is on its way '
          'to it. Type the code below and the account is deleted — there '
          'is no confirmation step after this one.',
        ),
      ]),
      const label(htmlFor: 'delete-code', [.text('The six-digit code')]),
      input<String>(
        key: const Key('code'),
        id: 'delete-code',
        type: .text,
        name: 'code',
        value: _code,
        onInput: (value) => _code = value,
        attributes: const {
          'placeholder': '123456',
          'autocomplete': 'one-time-code',
          'inputmode': 'numeric',
          'maxlength': '6',
        },
      ),
      button(
        key: const Key('delete'),
        type: .submit,
        classes: 'cta delete-account-confirm',
        disabled: _busy,
        [.text(_busy ? 'Deleting…' : 'Delete my account for good')],
      ),
      if (_message case final message?)
        p(classes: 'delete-account-message', [.text(message)]),
    ],
  );
}
