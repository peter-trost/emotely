import 'dart:async';

import 'package:emotely/analytics/auth_analytics.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'account_bloc.freezed.dart';
part 'account_event.dart';
part 'account_state.dart';

/// The one thing the account screen does: delete the account (App Store
/// guideline 5.1.1). `delete_account` removes the auth user on the server
/// and, by cascade, every session and entry; what is left is to forget the
/// user on this device, which ends the signed-in state through Supabase's
/// own auth stream.
class AccountBloc({
  required final SupabaseClient _supabase,
  required final AuthAnalytics _analytics,
}) extends Bloc<AccountEvent, AccountState> {
  this : super(const AccountState.idle()) {
    on<AccountDeletionRequested>(_onDeletionRequested);
  }

  Future<void> _onDeletionRequested(
    AccountDeletionRequested event,
    Emitter<AccountState> emit,
  ) async {
    emit(const AccountState.deleting());
    try {
      await _supabase.rpc<Object?>('delete_account');
    } on Exception {
      emit(const AccountState.failure());
      return;
    }
    unawaited(_analytics.accountDeleted());
    // The user no longer exists, so only the local session can be ended;
    // the SDK still tells the server and shrugs off its refusal.
    try {
      await _supabase.auth.signOut();
    } on Exception {
      // Already signed out locally, which is all that matters here.
    }
    emit(const AccountState.deleted());
  }

  static const failureMessage =
      'Could not delete your account. Check your connection and try again.';
}
