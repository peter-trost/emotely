import 'dart:async';

import 'package:emotely/consent/bloc/consent_bloc.dart';
import 'package:emotely/consent/consent_text.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

/// Asks for the explicit consent (Art. 9 (2) (a) GDPR) a session needs, on
/// its own route, before the first session and never again once it stands.
///
/// It reads the [ConsentBloc] already in scope rather than making one: the
/// journal owns that bloc, because the answer decides what the journal does
/// when Start is tapped, and two blocs would mean two answers.
///
/// Pops with `true` once consent is recorded, `false` if the user declined
/// or left — so the caller starts a session on exactly one of those.
class const ConsentPage({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const ConsentView();
}

/// The consent screen itself: what is sent where, the unticked box, and the
/// two ways out.
class const ConsentView({super.key}) extends StatelessWidget {
  static const checkboxKey = Key('consent_view.checkbox');
  static const agreeKey = Key('consent_view.agree');
  static const declineKey = Key('consent_view.decline');
  static const noticeKey = Key('consent_view.notice');
  static const retryKey = Key('consent_view.retry');

  @override
  Widget build(BuildContext context) => BlocConsumer<ConsentBloc, ConsentState>(
    listenWhen: (previous, state) => state.allowsSession,
    // Recorded: this route is done, and the caller starts the session.
    listener: (context, _) {
      if (ModalRoute.of(context)?.isCurrent ?? false) {
        Navigator.of(context).pop(true);
      }
    },
    builder: (context, state) => PopScope(
      // The write is in flight; leaving now would strand it and could
      // start a session on a consent that had not landed.
      canPop: state is! ConsentBusy,
      child: Scaffold(
        appBar: AppBar(title: const Text(consentTitle)),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: switch (state) {
              ConsentBusy() => const Center(child: CircularProgressIndicator()),
              ConsentWriteFailure() => const _WriteFailed(),
              // `known(granted: true)` is handled by the listener above;
              // everything else asks the question.
              _ => const _Ask(),
            },
          ),
        ),
      ),
    ),
  );
}

/// The question, the box, and the two answers. Stateful for one reason: the
/// tick is a local intention until the button is pressed, and nothing
/// outside this screen has any business knowing about a half-made decision.
class const _Ask() extends StatefulWidget {
  @override
  State<_Ask> createState() => _AskState();
}

class _AskState() extends State<_Ask> {
  /// Unticked, always, on every build of this screen. No pre-ticked box and
  /// no remembered tick: the act has to be made here, now.
  var _ticked = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 16,
        children: [
          Text(consentWhatIsSent, style: theme.textTheme.bodyLarge),
          Text(consentRecipients, style: theme.textTheme.bodyLarge),
          Text(consentSensitivity, style: theme.textTheme.bodyLarge),
          Text(consentLegalBasis, style: theme.textTheme.bodyLarge),
          TextButton(
            key: ConsentView.noticeKey,
            onPressed: () => unawaited(openPrivacyNotice()),
            child: const Text(consentReadNoticeLabel),
          ),
          CheckboxListTile(
            key: ConsentView.checkboxKey,
            value: _ticked,
            // The label is the checkbox's own semantics, so a screen reader
            // reads the thing being agreed to, not "checkbox, unchecked".
            title: const Text(consentCheckboxLabel),
            controlAffinity: ListTileControlAffinity.leading,
            onChanged: (ticked) => setState(() => _ticked = ticked ?? false),
          ),
          FilledButton(
            key: ConsentView.agreeKey,
            // Disabled until the box is ticked: the button alone is not the
            // affirmative act, the pair is.
            onPressed: _ticked
                ? () => context.read<ConsentBloc>().add(
                    const ConsentEvent.granted(),
                  )
                : null,
            child: const Text(consentAgreeLabel),
          ),
          TextButton(
            key: ConsentView.declineKey,
            onPressed: () {
              context.read<ConsentBloc>().add(const ConsentEvent.declined());
              // Declining is an answer, not a dead end: back to the journal,
              // which stays entirely usable.
              Navigator.of(context).pop(false);
            },
            child: const Text(consentDeclineLabel),
          ),
        ],
      ),
    );
  }
}

/// The consent could not be written down. The session does not start on
/// this: an unrecorded consent is one nobody can demonstrate later.
class const _WriteFailed() extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: 16,
    children: [
      Text(
        consentFailureMessage,
        style: TextStyle(color: Theme.of(context).colorScheme.error),
        textAlign: TextAlign.center,
      ),
      FilledButton(
        key: ConsentView.retryKey,
        onPressed: () =>
            context.read<ConsentBloc>().add(const ConsentEvent.granted()),
        child: const Text('Try again'),
      ),
      TextButton(
        key: ConsentView.declineKey,
        onPressed: () => Navigator.of(context).pop(false),
        child: const Text(consentDeclineLabel),
      ),
    ],
  );
}

/// Opens the full notice in the browser. Fire-and-forget like the store
/// link: if no browser can be opened there is nothing the screen can do,
/// and the text on it already says the essentials.
Future<void> openPrivacyNotice() => launchUrl(
  Uri.parse(privacyNoticeUrl),
  mode: LaunchMode.externalApplication,
);

/// Opens the imprint (§ 5 DDG), from the account screen.
Future<void> openImprint() =>
    launchUrl(Uri.parse(imprintUrl), mode: LaunchMode.externalApplication);
