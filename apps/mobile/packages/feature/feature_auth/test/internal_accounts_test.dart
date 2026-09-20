import 'package:feature_auth/src/review_accounts.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group(isInternalAccount, () {
    test('takes every address on the founder-owned domain', () {
      expect(isInternalAccount('test@getemotely.com'), isTrue);
      expect(isInternalAccount('  Test@GetEmotely.com '), isTrue);
    });

    test('covers the review accounts, which are a subset', () {
      for (final address in reviewAccounts) {
        expect(isInternalAccount(address), isTrue);
        expect(isReviewAccount(address), isTrue);
      }
    });

    test('takes nobody outside the domain', () {
      expect(isInternalAccount('someone@gmail.com'), isFalse);
      expect(isInternalAccount('x@getemotely.com.evil.org'), isFalse);
      expect(isInternalAccount(''), isFalse);
    });
  });
}
