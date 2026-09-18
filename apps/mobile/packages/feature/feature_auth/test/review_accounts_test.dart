import 'package:feature_auth/src/review_accounts.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group(isReviewAccount, () {
    test('names exactly the two accounts the store reviewers use', () {
      expect(reviewAccounts, {
        'google-play-review@getemotely.com',
        'app-store-review@getemotely.com',
      });
      for (final address in reviewAccounts) {
        expect(isReviewAccount(address), isTrue);
      }
    });

    test('ignores surrounding whitespace and letter case', () {
      expect(isReviewAccount('  App-Store-Review@GetEmotely.com\n'), isTrue);
      expect(isReviewAccount('GOOGLE-PLAY-REVIEW@GETEMOTELY.COM'), isTrue);
    });

    test('takes nobody else for a reviewer', () {
      expect(isReviewAccount('alice@example.com'), isFalse);
      expect(isReviewAccount('google-play-review@getemotely.co'), isFalse);
      expect(isReviewAccount('app-store-review@getemotely.com.evil'), isFalse);
      expect(isReviewAccount('xapp-store-review@getemotely.com'), isFalse);
      expect(isReviewAccount(''), isFalse);
    });
  });
}
