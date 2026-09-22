import 'package:feature_auth/feature_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:testing/testing.dart';

void main() {
  group(SignInRoute, () {
    testWidgets('shows the sign-in screen at its location', (tester) async {
      registerUtilitiesUnderTest(
        GetIt.I,
        agent: AgentStub(),
        supabase: SupabaseStub(),
        analytics: AnalyticsSpy(),
      );
      registerAuth(GetIt.I);

      await tester.pumpWidget(
        featureUnderTest(
          routes: [$signInRoute],
          initialLocation: const SignInRoute().location,
          // The auth bloc sits above every screen in the app.
          above: (_, child) =>
              BlocProvider(create: (_) => GetIt.I<AuthBloc>(), child: child),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(SignInPage), findsOneWidget);
    });
  });
}
