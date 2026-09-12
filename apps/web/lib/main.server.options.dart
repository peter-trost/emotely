// dart format off
// ignore_for_file: type=lint

// GENERATED FILE, DO NOT MODIFY
// Generated with jaspr_builder

import 'package:jaspr/server.dart';
import 'package:emotely_web/components/confirm_waitlist.dart'
    as _confirm_waitlist;
import 'package:emotely_web/components/waitlist_form.dart' as _waitlist_form;

/// Default [ServerOptions] for use with your Jaspr project.
///
/// Use this to initialize Jaspr **before** calling [runApp].
///
/// Example:
/// ```dart
/// import 'main.server.options.dart';
///
/// void main() {
///   Jaspr.initializeApp(
///     options: defaultServerOptions,
///   );
///
///   runApp(...);
/// }
/// ```
ServerOptions get defaultServerOptions => ServerOptions(
  clientId: 'main.client.dart.js',
  clients: {
    _confirm_waitlist.ConfirmWaitlist:
        ClientTarget<_confirm_waitlist.ConfirmWaitlist>('confirm_waitlist'),
    _waitlist_form.WaitlistForm: ClientTarget<_waitlist_form.WaitlistForm>(
      'waitlist_form',
    ),
  },
);
