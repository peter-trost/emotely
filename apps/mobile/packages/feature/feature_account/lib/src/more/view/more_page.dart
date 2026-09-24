import 'dart:async';

import 'package:feature_account/src/account/bloc/account_bloc.dart';
import 'package:feature_account/src/consent/bloc/consent_bloc.dart';
import 'package:feature_account/src/consent/consent_text.dart';
import 'package:feature_account/src/navigator.dart';
import 'package:feature_account/src/routes.dart';
import 'package:feedback_link/feedback_link.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:legal_links/legal_links.dart';
import 'package:material_ui/material_ui.dart';

/// The More tab: everything that is not the journal, as sections of rows
/// with a heading each — the account, consent, the legal documents,
/// feedback — and signing out at the very end.
///
/// Reads the [ConsentBloc] the route provides, and brings an [AccountBloc]
/// of its own for the feedback mail, which carries the build the app runs
/// and so goes through a bloc rather than being launched from here
/// (ADR 0015).
class const MorePage({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => GetIt.I<AccountBloc>(),
    child: const MoreView(),
  );
}

/// The sections themselves.
class const MoreView({super.key}) extends StatelessWidget {
  static const accountKey = Key('more_view.account');
  static const withdrawConsentKey = Key('more_view.withdraw_consent');
  static const restoreConsentKey = Key('more_view.restore_consent');
  static const consentRetryKey = Key('more_view.consent_retry');
  static const privacyNoticeKey = Key('more_view.privacy_notice');
  static const imprintKey = Key('more_view.imprint');
  static const feedbackKey = Key('more_view.feedback');
  static const signOutKey = Key('more_view.sign_out');

  static const accountSection = 'Account';
  static const consentSection = 'Consent';
  static const legalSection = 'Legal';
  static const feedbackSection = 'Feedback';

  static const accountLabel = 'Your account';
  static const accountExplanation = 'Delete your account and every entry.';

  /// Under the feedback row: says what the mail already contains, so
  /// nobody has to wonder whether tapping it sends anything they wrote.
  static const feedbackExplanation =
      'Opens your mail app. Carries your app version and device, '
      'nothing from your journal.';

  /// While a consent write is in flight.
  static const consentBusyLabel = 'Updating your consent…';

  /// The row that reads consent again after a failed read.
  static const consentRetryLabel = 'Check again';

  static const signOutLabel = 'Sign out';

  /// The gap above every section heading, and above the sign-out row: what
  /// tells one section from the next at a glance.
  static const sectionGap = 24.0;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('More')),
    body: const SafeArea(
      // A handful of rows, all built at once rather than as they scroll
      // into view: a screen reader, and a test, can reach every row
      // without scrolling first.
      child: SingleChildScrollView(
        padding: EdgeInsets.only(bottom: sectionGap),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Section(title: accountSection, children: [_AccountRow()]),
            _Section(title: consentSection, children: [_Consent()]),
            // The privacy notice and the imprint are required to be
            // reachable from inside the app — Apple guideline 5.1.1 (i) and
            // Google Play's User Data policy for the notice, § 5 DDG for the
            // imprint of a German provider.
            _Section(
              title: legalSection,
              children: [_PrivacyNoticeRow(), _ImprintRow()],
            ),
            _Section(title: feedbackSection, children: [_FeedbackRow()]),
            // Last, on its own, below everything the user might want first.
            _SignOutRow(),
          ],
        ),
      ),
    ),
  );
}

/// The account screen, on the feature's own route (ADR 0016).
class const _AccountRow() extends StatelessWidget {
  @override
  Widget build(BuildContext context) => ListTile(
    key: MoreView.accountKey,
    title: const Text(MoreView.accountLabel),
    subtitle: const Text(MoreView.accountExplanation),
    trailing: const Icon(Icons.chevron_right),
    onTap: () => const AccountRoute().go(context),
  );
}

/// The privacy notice, opened in the browser.
class const _PrivacyNoticeRow() extends StatelessWidget {
  @override
  Widget build(BuildContext context) => ListTile(
    key: MoreView.privacyNoticeKey,
    title: const Text(privacyNoticeLabel),
    trailing: const Icon(Icons.open_in_new),
    onTap: () => unawaited(openPrivacyNotice()),
  );
}

/// The imprint, opened in the browser.
class const _ImprintRow() extends StatelessWidget {
  @override
  Widget build(BuildContext context) => ListTile(
    key: MoreView.imprintKey,
    title: const Text(imprintLabel),
    trailing: const Icon(Icons.open_in_new),
    onTap: () => unawaited(openImprint()),
  );
}

/// The feedback mail, which the [AccountBloc] composes because it carries
/// the build the app runs.
class const _FeedbackRow() extends StatelessWidget {
  @override
  Widget build(BuildContext context) => ListTile(
    key: MoreView.feedbackKey,
    title: const Text(feedbackLabel),
    subtitle: const Text(MoreView.feedbackExplanation),
    trailing: const Icon(Icons.mail_outline),
    onTap: () =>
        context.read<AccountBloc>().add(const AccountEvent.feedbackRequested()),
  );
}

/// Signing out, set off from the last section by [MoreView.sectionGap].
class const _SignOutRow() extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: MoreView.sectionGap),
    child: ListTile(
      key: MoreView.signOutKey,
      leading: const Icon(Icons.logout),
      title: const Text(MoreView.signOutLabel),
      onTap: () => GetIt.I<AccountNavigator>().signOut(context),
    ),
  );
}

/// A heading and the rows under it, set off from the section above by
/// [MoreView.sectionGap].
class const _Section({
  required final String title,
  required final List<Widget> children,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, MoreView.sectionGap, 16, 4),
          child: Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
        ),
        ...children,
      ],
    );
  }
}

/// Withdrawing consent, and giving it again — each one row, because Art. 7
/// (3) requires taking it back to be as easy as giving it, and neither may
/// require deleting the account.
class const _Consent() extends StatelessWidget {
  @override
  Widget build(BuildContext context) => BlocBuilder<ConsentBloc, ConsentState>(
    builder: (context, state) => switch (state) {
      ConsentBusy() => const ListTile(
        title: Text(MoreView.consentBusyLabel),
        trailing: SizedBox.square(
          dimension: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      // The withdrawal did not land: consent still stands on the server,
      // and the row says so rather than pretending it is gone.
      ConsentWithdrawFailure() => _ConsentRow(
        key: MoreView.withdrawConsentKey,
        title: withdrawConsentLabel,
        subtitle: withdrawFailureMessage,
        failed: true,
        onTap: () =>
            context.read<ConsentBloc>().add(const ConsentEvent.withdrawn()),
      ),
      ConsentKnown(granted: true) => _ConsentRow(
        key: MoreView.withdrawConsentKey,
        title: withdrawConsentLabel,
        subtitle: withdrawConsentExplanation,
        onTap: () =>
            context.read<ConsentBloc>().add(const ConsentEvent.withdrawn()),
      ),
      // Consent is gone. The way back is the consent screen itself, not a
      // row that grants on the spot: Art. 7 (3) requires withdrawal to be
      // as easy as giving; it does not license making *giving* easier the
      // second time. A grant is only ever written from that screen, on its
      // own route with a bloc of its own; should this bloc ever hold a
      // failed write, consent does not stand, and the way back is the same.
      ConsentKnown(granted: false) || ConsentWriteFailure() => _ConsentRow(
        key: MoreView.restoreConsentKey,
        title: giveConsentLabel,
        subtitle: consentMissingExplanation,
        onTap: () => unawaited(_askAgain(context)),
      ),
      // The answer is not in hand. Rendering nothing would leave a user
      // who came here to withdraw with no control and no explanation — the
      // one thing Art. 7 (3) cannot tolerate — so say so and offer to look
      // again.
      ConsentFailure() || ConsentUnknown() => _ConsentRow(
        key: MoreView.consentRetryKey,
        title: MoreView.consentRetryLabel,
        subtitle: consentUnknownMessage,
        failed: true,
        onTap: () =>
            context.read<ConsentBloc>().add(const ConsentEvent.loaded()),
      ),
    },
  );

  /// The consent screen on its own route, which the app shows (ADR 0015);
  /// once it closes, this row asks the server again rather than trusting
  /// what it showed before — the record is what counts.
  static Future<void> _askAgain(BuildContext context) async {
    final consent = context.read<ConsentBloc>();
    await GetIt.I<AccountNavigator>().requestConsent(context);
    consent.add(const ConsentEvent.loaded());
  }
}

/// One consent row: what it does, why, and in the error colour when it is
/// reporting something that did not work.
class const _ConsentRow({
  required final String title,
  required final String subtitle,
  required final VoidCallback onTap,
  final bool failed = false,
  super.key,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => ListTile(
    title: Text(title),
    subtitle: Text(
      subtitle,
      style: failed
          ? TextStyle(color: Theme.of(context).colorScheme.error)
          : null,
    ),
    onTap: onTap,
  );
}
