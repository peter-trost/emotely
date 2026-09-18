import 'package:feature_account/feature_account.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:testing/testing.dart';

/// The bloc's own guarantees that no screen can show: one write at a time,
/// a refresh that waits for the answer, and a withdrawal that cannot land.
void main() {
  group(ConsentBloc, () {
    late SupabaseStub supabase;
    late AnalyticsSpy analytics;
    late ConsentBloc bloc;

    setUp(() {
      supabase = SupabaseStub();
      analytics = AnalyticsSpy();
      final getIt = GetIt.asNewInstance();
      registerUtilitiesUnderTest(
        getIt,
        agent: AgentStub(),
        supabase: supabase,
        analytics: analytics,
      );
      registerAccount(getIt);
      bloc = getIt<ConsentBloc>();
    });

    tearDown(() => bloc.close());

    test('refresh reads again and waits for the answer', () async {
      supabase.rest(consentRead, [
        consentStands(),
        consentStands(granted: false),
      ]);

      await bloc.refresh();
      expect(bloc.state, const ConsentState.known(granted: true));

      await bloc.refresh();
      expect(bloc.state, const ConsentState.known(granted: false));
      expect(supabase.to(consentRead), hasLength(2));
    });

    test('writes one grant at a time', () async {
      supabase.rest(consentGrant, [delayedAuth(rpcReturned(null))]);

      bloc
        ..add(const ConsentEvent.granted())
        ..add(const ConsentEvent.granted());
      await bloc.stream.firstWhere((state) => state is ConsentKnown);

      expect(supabase.to(consentGrant), hasLength(1));
      expect(analytics.events, [
        event('consent_granted', {'version': testConsentVersion}),
      ]);
    });

    test('writes one withdrawal at a time', () async {
      supabase.rest(consentWithdraw, [delayedAuth(rpcReturned(null))]);

      bloc
        ..add(const ConsentEvent.withdrawn())
        ..add(const ConsentEvent.withdrawn());
      await bloc.stream.firstWhere((state) => state is ConsentKnown);

      expect(supabase.to(consentWithdraw), hasLength(1));
      expect(bloc.state, const ConsentState.known(granted: false));
    });

    test('a withdrawal that cannot land leaves consent standing', () async {
      supabase.rest(consentWithdraw, [restRefused()]);

      bloc.add(const ConsentEvent.withdrawn());
      await bloc.stream.firstWhere((state) => state is! ConsentBusy);

      expect(bloc.state, const ConsentState.withdrawFailure());
      expect(bloc.state.allowsSession, isFalse);
      expect(analytics.exceptions, hasLength(1));
    });

    test('declining is known, just declined, and not a session', () async {
      bloc.add(const ConsentEvent.declined());
      await bloc.stream.first;

      expect(
        bloc.state,
        const ConsentState.known(granted: false, justDeclined: true),
      );
      expect(bloc.state.allowsSession, isFalse);
    });
  });
}
