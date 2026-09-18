import 'package:flutter_test/flutter_test.dart';
import 'package:legal_links/legal_links.dart';
import 'package:testing/testing.dart';

void main() {
  group('legal links', () {
    testWidgets('open the notice and the imprint in the browser', (
      tester,
    ) async {
      final launcher = UrlLauncherSpy.setup();

      await openPrivacyNotice();
      await openImprint();

      expect(launcher.launched, [privacyNoticeUrl, imprintUrl]);
    });

    test('point at getemotely.com', () {
      expect(Uri.parse(privacyNoticeUrl).host, 'getemotely.com');
      expect(Uri.parse(imprintUrl).host, 'getemotely.com');
    });
  });
}
