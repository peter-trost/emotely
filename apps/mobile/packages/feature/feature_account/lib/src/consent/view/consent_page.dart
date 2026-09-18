import 'dart:async';

import 'package:feature_account/src/consent/bloc/consent_bloc.dart';
import 'package:feature_account/src/consent/consent_text.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:legal_links/legal_links.dart';
import 'package:material_ui/material_ui.dart';

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
              // Still reading. Showing the question here would flash it for
              // a moment and then answer it, which is not how a decision
              // this size should arrive.
              ConsentUnknown() ||
              ConsentBusy() => const Center(child: CircularProgressIndicator()),
              ConsentWriteFailure() => const _WriteFailed(),
              // The read failed: the app does not know whether consent
              // already stands, and asking again would re-prompt someone
              // who has consented — consent fatigue, on a flaky network.
              // Say what happened and offer to look again.
              ConsentFailure() => const _ReadFailed(),
              // `known(granted: true)` is handled by the listener above;
              // a known `false` asks the question. A failed *withdrawal*
              // can only be reached from the account screen, which owns
              // that act, so it asks here too rather than being a state of
              // its own.
              ConsentKnown() || ConsentWithdrawFailure() => const _Ask(),
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
          Text(consentNoTraining, style: theme.textTheme.bodyLarge),
          Text(consentSensitivity, style: theme.textTheme.bodyLarge),
          Text(consentIrreversible, style: theme.textTheme.bodyLarge),
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
          // A disabled button reads as just "dimmed" to a screen reader,
          // which leaves someone who cannot see the checkbox with no way to
          // know why the button does nothing. The hint says what to do.
          Semantics(
            enabled: _ticked,
            hint: _ticked ? null : consentAgreeBlockedHint,
            child: FilledButton(
              key: ConsentView.agreeKey,
              // Disabled until the box is ticked: the button alone is not
              // the affirmative act, the pair is.
              onPressed: _ticked
                  ? () => context.read<ConsentBloc>().add(
                      const ConsentEvent.granted(),
                    )
                  : null,
              child: const Text(consentAgreeLabel),
            ),
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

/// Whether consent already stands could not be read. Distinct from the
/// question itself: re-asking someone who has already consented, every time
/// the network hiccups, trains them to tick the box without reading it —
/// and a consent given that way is not much of a consent.
class const _ReadFailed() extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: 16,
    children: [
      Text(
        consentUnknownMessage,
        style: TextStyle(color: Theme.of(context).colorScheme.error),
        textAlign: TextAlign.center,
      ),
      FilledButton(
        key: ConsentView.retryKey,
        onPressed: () =>
            context.read<ConsentBloc>().add(const ConsentEvent.loaded()),
        child: const Text('Try again'),
      ),
      TextButton(
        key: ConsentView.declineKey,
        onPressed: () => Navigator.of(context).pop(false),
        child: const Text('Back'),
      ),
    ],
  );
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
