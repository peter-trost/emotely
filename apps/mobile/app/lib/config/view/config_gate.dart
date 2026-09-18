import 'dart:async';

import 'package:analytics/analytics.dart';
import 'package:emotely/config/bloc/config_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

/// The startup gate: nothing below it is built until the server has said this
/// build may run (#49).
///
/// It wraps the whole app rather than the session, so a build the server no
/// longer serves never reaches sign-in — the screens underneath may depend on
/// wire shapes that are gone, and asking someone to sign in only to block
/// them afterwards is worse than blocking them first.
class const ConfigGate({required final Widget child, super.key})
    extends StatelessWidget {
  static const checkingKey = Key('config_gate.checking');
  static const updateRequiredKey = Key('config_gate.update_required');
  static const updateKey = Key('config_gate.update');
  static const failureKey = Key('config_gate.failure');
  static const retryKey = Key('config_gate.retry');

  @override
  Widget build(BuildContext context) => BlocBuilder<ConfigBloc, ConfigState>(
    builder: (context, state) => switch (state) {
      ConfigReady() => child,
      ConfigUnknown() => const _Checking(),
      ConfigUpdateRequired(:final minAppVersion, :final storeUrl) =>
        _UpdateRequired(minAppVersion: minAppVersion, storeUrl: storeUrl),
      ConfigFailure(:final message) => _Failure(message: message),
    },
  );
}

/// Everything the gate shows sits on its own scaffold: it renders before the
/// app's own chrome exists, so it cannot borrow one.
class const _GateScaffold({
  required final Key contentKey,
  required final List<Widget> children,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          key: contentKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: 16,
            children: children,
          ),
        ),
      ),
    ),
  );
}

class const _Checking() extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const _GateScaffold(
    contentKey: ConfigGate.checkingKey,
    children: [CircularProgressIndicator()],
  );
}

/// The force-update screen: no retry, no way around it. This is what lets the
/// server delete deprecated wire shapes instead of keeping them (#37).
class const _UpdateRequired({
  required final String minAppVersion,
  required final String storeUrl,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _GateScaffold(
    contentKey: ConfigGate.updateRequiredKey,
    children: [
      Text(
        'This version of emotely is no longer supported. '
        'Please update to $minAppVersion or newer to continue.',
        textAlign: TextAlign.center,
      ),
      FilledButton(
        key: ConfigGate.updateKey,
        // The screen stays blocking whether or not the store opens — there is
        // nothing else it could show. But a failure here strands the user on
        // their only way out, so it is reported rather than swallowed.
        onPressed: () => unawaited(_openStore(context, storeUrl)),
        child: const Text('Update'),
      ),
    ],
  );
}

/// The config could not be read, so the app does not know whether it may run
/// and blocks with a retry. Not "allowed by default": the version gate is the
/// one thing that must fail shut, or a build the server has stopped serving
/// walks straight past it whenever the network is down.
/// Opens [storeUrl], reporting a failure instead of dropping it.
Future<void> _openStore(BuildContext context, String storeUrl) async {
  final errors = context.read<ErrorReporter>();
  try {
    await launchUrl(Uri.parse(storeUrl), mode: LaunchMode.externalApplication);
  } on Exception catch (error, stackTrace) {
    unawaited(errors.storeLaunchFailed(error, stackTrace));
  }
}

class const _Failure({required final String message}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _GateScaffold(
    contentKey: ConfigGate.failureKey,
    children: [
      Text(
        message,
        style: TextStyle(color: Theme.of(context).colorScheme.error),
        textAlign: TextAlign.center,
      ),
      FilledButton(
        key: ConfigGate.retryKey,
        onPressed: () =>
            context.read<ConfigBloc>().add(const ConfigEvent.loaded()),
        child: const Text('Try again'),
      ),
    ],
  );
}
