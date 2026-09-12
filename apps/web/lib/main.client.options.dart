// dart format off
// ignore_for_file: type=lint

// GENERATED FILE, DO NOT MODIFY
// Generated with jaspr_builder

import 'package:jaspr/client.dart';

import 'package:emotely_web/components/confirm_waitlist.dart'
    deferred as _confirm_waitlist;
import 'package:emotely_web/components/waitlist_form.dart'
    deferred as _waitlist_form;

/// Default [ClientOptions] for use with your Jaspr project.
///
/// Use this to initialize Jaspr **before** calling [runApp].
///
/// Example:
/// ```dart
/// import 'main.client.options.dart';
///
/// void main() {
///   Jaspr.initializeApp(
///     options: defaultClientOptions,
///   );
///
///   runApp(...);
/// }
/// ```
ClientOptions get defaultClientOptions => ClientOptions(
  clients: {
    'confirm_waitlist': ClientLoader(
      (p) => _confirm_waitlist.ConfirmWaitlist(),
      loader: _confirm_waitlist.loadLibrary,
    ),
    'waitlist_form': ClientLoader(
      (p) => _waitlist_form.WaitlistForm(),
      loader: _waitlist_form.loadLibrary,
    ),
  },
);
