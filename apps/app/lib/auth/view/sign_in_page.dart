import 'package:emotely/auth/bloc/auth_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

/// Email code sign-in in two steps: the email, then the six-digit code
/// Supabase sent to it. Nothing to remember, nothing to leave the app for.
class const SignInPage({super.key}) extends StatelessWidget {
  static const emailKey = Key('sign_in_page.email');
  static const sendCodeKey = Key('sign_in_page.send_code');
  static const codeKey = Key('sign_in_page.code');
  static const signInKey = Key('sign_in_page.sign_in');
  static const changeEmailKey = Key('sign_in_page.change_email');
  static const errorKey = Key('sign_in_page.error');

  static const tooManyCodesMessage = AuthBloc.tooManyCodesMessage;
  static const couldNotSendMessage = AuthBloc.couldNotSendMessage;
  static const wrongCodeMessage = AuthBloc.wrongCodeMessage;
  static const unreachableMessage = AuthBloc.unreachableMessage;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Sign in')),
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) => switch (state) {
            AuthSignedOut(:final error) => _EmailStep(error: error),
            AuthRequestingCode() => const _EmailStep(busy: true),
            AuthCodeSent(:final email, :final error) => _CodeStep(
              email: email,
              error: error,
            ),
            AuthVerifying(:final email) => _CodeStep(email: email, busy: true),
            AuthSignedIn() => const SizedBox.shrink(),
          },
        ),
      ),
    ),
  );
}

class const _EmailStep({final String? error, final bool busy = false})
    extends StatefulWidget {
  @override
  State<_EmailStep> createState() => _EmailStepState();
}

class _EmailStepState() extends State<_EmailStep> {
  final _controller = TextEditingController();

  String get _email => _controller.text.trim();

  // Good enough to stop typos before a round trip; Supabase validates the
  // address for real.
  bool get _plausible => _email.contains('@') && _email.contains('.');

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: 16,
    children: [
      Text(
        'Enter your email and we send you a six-digit code.',
        style: Theme.of(context).textTheme.bodyLarge,
      ),
      TextField(
        key: SignInPage.emailKey,
        controller: _controller,
        enabled: !widget.busy,
        autofillHints: const [AutofillHints.email],
        keyboardType: TextInputType.emailAddress,
        autocorrect: false,
        decoration: const InputDecoration(labelText: 'Email'),
        onChanged: (_) => setState(() {}),
      ),
      _ErrorText(widget.error),
      if (widget.busy)
        const _Busy()
      else
        FilledButton(
          key: SignInPage.sendCodeKey,
          onPressed: _plausible
              ? () => context.read<AuthBloc>().add(
                  AuthEvent.codeRequested(_email),
                )
              : null,
          child: const Text('Send code'),
        ),
    ],
  );
}

class const _CodeStep({
  required final String email,
  final String? error,
  final bool busy = false,
}) extends StatefulWidget {
  static const codeLength = 6;

  @override
  State<_CodeStep> createState() => _CodeStepState();
}

class _CodeStepState() extends State<_CodeStep> {
  final _controller = TextEditingController();

  String get _code => _controller.text.trim();

  bool get _complete =>
      _code.length == _CodeStep.codeLength &&
      _code.codeUnits.every((unit) => unit >= 0x30 && unit <= 0x39);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: 16,
    children: [
      Text(
        'We sent a code to ${widget.email}.',
        style: Theme.of(context).textTheme.bodyLarge,
      ),
      TextField(
        key: SignInPage.codeKey,
        controller: _controller,
        enabled: !widget.busy,
        autofillHints: const [AutofillHints.oneTimeCode],
        keyboardType: TextInputType.number,
        maxLength: _CodeStep.codeLength,
        decoration: const InputDecoration(labelText: 'Code'),
        onChanged: (_) => setState(() {}),
      ),
      _ErrorText(widget.error),
      if (widget.busy)
        const _Busy()
      else
        _CodeActions(
          onSignIn: _complete
              ? () =>
                    context.read<AuthBloc>().add(AuthEvent.codeSubmitted(_code))
              : null,
        ),
    ],
  );
}

/// Verify the code, or go back for a different email.
class const _CodeActions({required final VoidCallback? onSignIn})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: 8,
    children: [
      FilledButton(
        key: SignInPage.signInKey,
        onPressed: onSignIn,
        child: const Text('Sign in'),
      ),
      TextButton(
        key: SignInPage.changeEmailKey,
        onPressed: () => context.read<AuthBloc>().add(
          const AuthEvent.emailChangeRequested(),
        ),
        child: const Text('Use a different email'),
      ),
    ],
  );
}

class const _ErrorText(final String? message) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => switch (message) {
    null => const SizedBox.shrink(),
    final message => Text(
      message,
      key: SignInPage.errorKey,
      style: TextStyle(color: Theme.of(context).colorScheme.error),
    ),
  };
}

class const _Busy() extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      const Center(child: CircularProgressIndicator());
}
