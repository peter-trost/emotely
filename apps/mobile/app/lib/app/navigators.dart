import 'package:emotely/auth/bloc/auth_bloc.dart';
import 'package:feature_account/feature_account.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The app's side of every feature's navigator (ADR 0015): a feature says
/// what it needs from the outside, the app says how — with the real pages
/// and the real blocs, which only the app may know together.

/// Signing out is the auth feature's act: the root swaps to sign-in once
/// the auth bloc has ended the session.
class const AppAccountNavigator() implements AccountNavigator {
  @override
  void signOut(BuildContext context) =>
      context.read<AuthBloc>().add(const AuthEvent.signOutRequested());
}
