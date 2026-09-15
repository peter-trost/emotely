import 'package:emotely_web/components/confirm_waitlist.dart';
import 'package:emotely_web/components/delete_account_form.dart';
import 'package:emotely_web/components/waitlist_form.dart';
import 'package:emotely_web/pages/app_privacy.dart';
import 'package:emotely_web/pages/confirm.dart';
import 'package:emotely_web/pages/delete_account.dart';
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

    testComponents('names the platforms, not one phone brand', (tester) {
      tester.pumpComponent(const Home());

      expect(find.textContaining('iOS and Android'), findsComponents);
      expect(find.textContaining('iPhone'), findsNothing);
    });
  });

  group('Confirm', () {
    testComponents('pre-renders the checking state for the island', (tester) {
      tester.pumpComponent(const Confirm());

      expect(find.byType(ConfirmWaitlist), findsOneComponent);
      expect(find.textContaining('Checking your link'), findsOneComponent);
    });
  });

  group('DeleteAccount', () {
    testComponents('gives the in-app path first, then the form', (tester) {
      tester.pumpComponent(const DeleteAccount());

      expect(find.textContaining('If you still have the app'), findsComponents);
      expect(find.textContaining('account icon'), findsComponents);
      expect(
        find.textContaining('If you no longer have the app'),
        findsComponents,
      );
      expect(find.byType(DeleteAccountForm), findsOneComponent);
    });

    testComponents('says what is deleted and that it does not come back', (
      tester,
    ) {
      tester.pumpComponent(const DeleteAccount());

      expect(find.textContaining('journal entry'), findsComponents);
      expect(find.textContaining('hello@getemotely.com'), findsComponents);
    });

    testComponents('promises nothing the form does not do', (tester) {
      tester.pumpComponent(const DeleteAccount());

      // Deleting is immediate; no "we will get back to you within 30 days".
      expect(find.textContaining('immediate'), findsComponents);
    });

    testComponents('names the app and developer as the Play listing has them', (
      tester,
    ) {
      tester.pumpComponent(const DeleteAccount());

      // The Play record keeps the legacy title until the first new
      // version (ADR 0012); when it is renamed, this test says so.
      expect(
        find.textContaining('Reflect Therapy AI: emotely'),
        findsOneComponent,
      );
      expect(find.textContaining('Peter Trost'), findsComponents);
    });

    testComponents('is honest about backups rather than claiming none', (
      tester,
    ) {
      tester.pumpComponent(const DeleteAccount());

      expect(find.textContaining('live database'), findsComponents);
      expect(find.textContaining('retention window'), findsComponents);
      // The old copy claimed there was no backup copy at all.
      expect(find.textContaining('no backup'), findsNothing);
    });

    testComponents('says what survives the deletion, and calls it that', (
      tester,
    ) {
      tester.pumpComponent(const DeleteAccount());

      expect(find.text('What is not deleted'), findsOneComponent);
      // "anonymous" would overstate what the counting actually is.
      expect(find.textContaining('pseudonymous'), findsComponents);
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

    testComponents('the imprint carries the VAT ID (§ 27a UStG)', (tester) {
      tester.pumpComponent(const Imprint());

      expect(find.textContaining('DE369514299'), findsOneComponent);
    });

    testComponents(
      'the privacy page names every party that touches an address',
      (tester) {
        tester.pumpComponent(const Privacy());

        expect(find.textContaining('Supabase'), findsComponents);
        expect(find.textContaining('Resend'), findsComponents);
        expect(find.textContaining('Vercel'), findsComponents);
        expect(find.textContaining('PostHog'), findsComponents);
        expect(find.textContaining('hello@getemotely.com'), findsComponents);
      },
    );

    testComponents(
      'the privacy page gives a legal basis, a retention and a regulator',
      (tester) {
        tester.pumpComponent(const Privacy());

        expect(find.textContaining('Art. 6 (1) (a)'), findsComponents);
        expect(find.textContaining('Art. 6 (1) (f)'), findsComponents);
        expect(find.textContaining('erased after one day'), findsOneComponent);
        expect(find.textContaining('deleted after a week'), findsOneComponent);
        expect(find.textContaining('Landesbeauftragte'), findsOneComponent);
        expect(find.textContaining('served from this site'), findsOneComponent);
      },
    );

    testComponents('the privacy page points at the deletion page', (tester) {
      tester.pumpComponent(const Privacy());

      expect(find.textContaining('the deletion page'), findsOneComponent);
      expect(find.textContaining('Delete account'), findsComponents);
      // Truthful about backups, rather than promising none exist.
      expect(find.textContaining('retention window'), findsComponents);
    });

    testComponents('the privacy page hands the app off to its own notice', (
      tester,
    ) {
      tester.pumpComponent(const Privacy());

      // What Google read and rejected: the site notice used to say the app
      // carried its notice inside itself, which it never did.
      expect(find.textContaining('notice inside it'), findsNothing);
      expect(find.textContaining('own privacy notice'), findsOneComponent);
    });
  });

  group('AppPrivacy', () {
    testComponents('names the controller and how to reach them', (tester) {
      tester.pumpComponent(const AppPrivacy());

      expect(find.textContaining('Peter Trost'), findsComponents);
      expect(find.textContaining('Rottenburg am Neckar'), findsComponents);
      expect(find.textContaining('hello@getemotely.com'), findsComponents);
    });

    testComponents('names the app as the Play listing still has it', (tester) {
      tester.pumpComponent(const AppPrivacy());

      // The Play record keeps the legacy title until the first new version
      // (ADR 0012); when it is renamed, this test says so.
      expect(
        find.textContaining('Reflect Therapy AI: emotely'),
        findsOneComponent,
      );
    });

    testComponents('covers every category the stores ask about', (tester) {
      tester.pumpComponent(const AppPrivacy());

      expect(find.text('Your email address'), findsOneComponent);
      expect(find.text('Your journal entries and sessions'), findsOneComponent);
      expect(
        find.text('The conversation with the assistant'),
        findsOneComponent,
      );
      expect(find.text('Counting and crash reports'), findsOneComponent);
      expect(find.text('Who else sees any of it'), findsOneComponent);
      expect(find.text('Deleting your account'), findsOneComponent);
      expect(find.text('Your rights'), findsOneComponent);
      expect(find.text('Children'), findsOneComponent);
      expect(find.text('Changes to this notice'), findsOneComponent);
    });

    testComponents('gives a legal basis, including Art. 9 for entries', (
      tester,
    ) {
      tester.pumpComponent(const AppPrivacy());

      expect(find.textContaining('Art. 6 (1) (b)'), findsComponents);
      expect(find.textContaining('Art. 6 (1) (f)'), findsComponents);
      // Journal entries are special-category data, and the page says so.
      expect(find.textContaining('Art. 9 (2) (a)'), findsComponents);
      expect(find.textContaining('health'), findsComponents);
    });

    testComponents('names every processor and where the data sits', (tester) {
      tester.pumpComponent(const AppPrivacy());

      expect(find.textContaining('Supabase'), findsComponents);
      expect(find.textContaining('Vercel AI Gateway'), findsComponents);
      expect(find.textContaining('PostHog'), findsComponents);
      expect(find.textContaining('Frankfurt'), findsComponents);
    });

    testComponents('claims no training guarantee it cannot back', (tester) {
      tester.pumpComponent(const AppPrivacy());

      // The gateway's no-prompt-training routing is opt-in and is not
      // enabled for emotely, so the page says exactly that instead of
      // promising what the code does not do.
      expect(
        find.textContaining('not currently switched on'),
        findsOneComponent,
      );
    });

    testComponents('describes analytics by their real event names', (tester) {
      tester.pumpComponent(const AppPrivacy());

      expect(find.textContaining('session_started'), findsComponents);
      expect(find.textContaining('sign_in_code_requested'), findsComponents);
      expect(find.textContaining('journal_viewed'), findsComponents);
    });

    testComponents('gives both deletion paths and links the web one', (tester) {
      tester.pumpComponent(const AppPrivacy());

      expect(find.textContaining('account icon'), findsComponents);
      expect(find.textContaining('deletion page'), findsComponents);
    });

    testComponents('is honest about backups rather than claiming none', (
      tester,
    ) {
      tester.pumpComponent(const AppPrivacy());

      expect(find.textContaining('retention window'), findsComponents);
      expect(find.textContaining('no backup'), findsNothing);
      // "anonymous" would overstate what the counting actually is.
      expect(find.textContaining('pseudonymous'), findsComponents);
    });

    testComponents('points at the site notice for the site', (tester) {
      tester.pumpComponent(const AppPrivacy());

      expect(find.textContaining('site privacy notice'), findsOneComponent);
    });
  });
}
