import 'package:emotely/app/router.dart';
import 'package:emotely/app/routes.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('authRedirect', () {
    final signIn = const SignInRoute().location;
    final journal = const JournalRoute().location;
    final account = const AccountRoute().location;

    test('sends a signed-out user anywhere to sign-in', () {
      expect(authRedirect(signedIn: false, location: journal), signIn);
      expect(authRedirect(signedIn: false, location: account), signIn);
    });

    test('leaves a signed-out user on sign-in', () {
      expect(authRedirect(signedIn: false, location: signIn), isNull);
    });

    test('sends a signed-in user on sign-in to the journal', () {
      expect(authRedirect(signedIn: true, location: signIn), journal);
    });

    test('leaves a signed-in user wherever they are', () {
      expect(authRedirect(signedIn: true, location: journal), isNull);
      expect(authRedirect(signedIn: true, location: account), isNull);
    });
  });
}
