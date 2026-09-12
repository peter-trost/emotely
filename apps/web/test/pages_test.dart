import 'package:emotely_web/components/waitlist_form.dart';
import 'package:emotely_web/pages/home.dart';
import 'package:emotely_web/pages/imprint.dart';
import 'package:emotely_web/pages/privacy.dart';
import 'package:jaspr_test/jaspr_test.dart';

void main() {
  group('Home', () {
    testComponents('leads with the promise and asks for an address', (tester) {
      tester.pumpComponent(const Home());

      expect(
        find.textContaining('without staring at a blank page'),
        findsOneComponent,
      );
      expect(find.byType(WaitlistForm), findsOneComponent);
    });

    testComponents('shows how it works, what you get and the risk reversal', (
      tester,
    ) {
      tester.pumpComponent(const Home());

      expect(find.text('How it works'), findsOneComponent);
      expect(find.text('What you get'), findsOneComponent);
      expect(
        find.textContaining('Free during early access'),
        findsOneComponent,
      );
      expect(find.textContaining('delete'), findsComponents);
    });

    testComponents('answers the questions people ask before they sign up', (
      tester,
    ) {
      tester.pumpComponent(const Home());

      expect(find.text('Questions'), findsOneComponent);
      expect(find.textContaining('therapy'), findsComponents);
      expect(find.textContaining('train'), findsComponents);
    });

    testComponents('links to the code', (tester) {
      tester.pumpComponent(const Home());

      expect(find.textContaining('Read the code'), findsComponents);
    });
  });

  group('Legal pages', () {
    testComponents('the imprint names the operator and a contact address', (
      tester,
    ) {
      tester.pumpComponent(const Imprint());

      expect(find.textContaining('Peter Trost'), findsComponents);
      expect(find.textContaining('hello@getemotely.com'), findsComponents);
    });

    testComponents(
      'the privacy page names every party that touches an address',
      (tester) {
        tester.pumpComponent(const Privacy());

        expect(find.textContaining('Supabase'), findsComponents);
        expect(find.textContaining('Resend'), findsComponents);
        expect(find.textContaining('Vercel'), findsComponents);
        expect(find.textContaining('hello@getemotely.com'), findsComponents);
      },
    );
  });
}
