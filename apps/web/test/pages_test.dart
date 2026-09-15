import 'package:emotely_web/app.dart';
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
      // The h3 subsections appear once; the h2 ones appear twice, because
      // the table of contents names each of them as well.
      expect(find.text('Who else sees any of it'), findsNComponents(2));
      expect(find.text('Deleting your account'), findsNComponents(2));
      expect(find.text('Your rights'), findsNComponents(2));
      expect(find.text('Children'), findsNComponents(2));
      expect(find.text('Changes to this notice'), findsNComponents(2));
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

    testComponents('states the training and retention opt-out as settled', (
      tester,
    ) {
      tester.pumpComponent(const AppPrivacy());

      // Since #96 every round sends disallowPromptTraining and
      // zeroDataRetention, so the page states it rather than hedging.
      expect(find.textContaining('not to train on prompts'), findsComponents);
      expect(find.textContaining('zero-retention'), findsComponents);
      // Both filters fail closed, and the page says so rather than
      // implying a silent fallback.
      expect(find.textContaining('fail closed'), findsComponents);
      // The old hedge, from before the flags were set.
      expect(find.textContaining('not currently switched on'), findsNothing);
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

    testComponents('describes the consent gate and the way to take it back', (
      tester,
    ) {
      tester.pumpComponent(const AppPrivacy());

      // Apple 5.1.1(i) wants the revocation path described, and it must be
      // the one the app actually offers (#97), not "delete your account".
      expect(find.textContaining('account screen'), findsComponents);
      expect(find.textContaining('does not require deleting'), findsComponents);
      expect(find.textContaining('Art. 7 (3)'), findsComponents);
      expect(find.textContaining('consent_granted'), findsComponents);
    });

    testComponents('carries the Art. 13 disclosures that are easy to forget', (
      tester,
    ) {
      tester.pumpComponent(const AppPrivacy());

      // Art. 22 (1): a negative statement satisfies it, silence does not.
      // Twice: the heading, and its entry in the table of contents.
      expect(find.text('Automated decisions'), findsNComponents(2));
      expect(find.textContaining('Art. 22 (1)'), findsComponents);
      // Art. 12 (3) response time, and a privacy contact.
      expect(find.textContaining('within one month'), findsComponents);
      // Art. 13 (2) (e): consequence of not providing the address.
      expect(find.textContaining('not a statutory duty'), findsComponents);
      // Play's secure-handling disclosure.
      expect(find.textContaining('encrypted HTTPS'), findsComponents);
      // ADR 0008's IP-keyed rate limit.
      expect(find.textContaining('thirty a minute'), findsComponents);
    });

    testComponents('discloses what the SDK collects on its own', (tester) {
      tester.pumpComponent(const AppPrivacy());

      // The event list is not exhaustive without these, and the ASC
      // declarations name a Device ID that the page has to account for.
      expect(find.textContaining('device identifier'), findsComponents);
      expect(find.textContaining('sent to the background'), findsComponents);
    });

    testComponents('gives analytics a retention criterion like every other '
        'category', (tester) {
      tester.pumpComponent(const AppPrivacy());

      expect(
        find.textContaining('retention window for the project'),
        findsComponents,
      );
    });

    // The suite above asserts that hedges are PRESENT. These assert that
    // overclaims are ABSENT — the needle pattern from apps/app. Findings 1,
    // 2 and 4 of the red-team review all survived a presence-only suite.
    group('claims nothing the code does not do', () {
      testComponents('does not deny sending the address to our own server', (
        tester,
      ) {
        tester.pumpComponent(const AppPrivacy());

        // Every round carries the sign-in token, whose JWT holds the
        // address (agent_client.dart, request-auth.ts). The narrowed claim
        // is about the gateway payload only, and must stay narrowed.
        expect(
          find.textContaining('the transcript carries no name and no email'),
          findsNothing,
        );
        expect(find.textContaining('sign-in token'), findsComponents);
      });

      testComponents('does not claim the server sends PostHog nothing', (
        tester,
      ) {
        tester.pumpComponent(const AppPrivacy());

        // telemetry.ts ships a PostHogSpanProcessor: tokens, latency, cost
        // and promptId per round, content suppressed at source.
        expect(
          find.textContaining('technical record of each round'),
          findsComponents,
        );
        expect(
          find.textContaining('suppressed at the source'),
          findsComponents,
        );
      });

      testComponents('does not enumerate session columns without the '
          'transcript', (tester) {
        tester.pumpComponent(const AppPrivacy());

        // The migration stores `transcript jsonb not null`; leaving it out
        // of an otherwise exhaustive list understates what is kept.
        expect(
          find.textContaining('full transcript of the conversation'),
          findsComponents,
        );
      });

      testComponents('does not promise deletion leaves only two survivors', (
        tester,
      ) {
        tester.pumpComponent(const AppPrivacy());

        // /delete-account names three, the waitlist among them.
        expect(find.textContaining('waitlist'), findsComponents);
        expect(find.textContaining('Two things outlive'), findsNothing);
      });

      testComponents('does not count the forwarded exception types', (tester) {
        tester.pumpComponent(const AppPrivacy());

        // forwardedTypes has four entries, not three; the page avoids the
        // count rather than restating a number that drifts.
        expect(find.textContaining('Only three kinds'), findsNothing);
      });

      testComponents('does not overstate where the model is recorded', (
        tester,
      ) {
        tester.pumpComponent(const AppPrivacy());

        // EMOTELY_MODEL can override the default at runtime, so the repo
        // records the default, not necessarily the model in use.
        expect(
          find.textContaining('model in use is recorded in the public'),
          findsNothing,
        );
      });

      testComponents('does not call the counting anonymous', (tester) {
        tester.pumpComponent(const AppPrivacy());

        expect(find.textContaining('pseudonymous'), findsComponents);
        expect(find.textContaining('anonymous counting'), findsNothing);
      });
    });
  });

  group('Routing', () {
    // jaspr build generates sitemap.xml from the router's routes, so a page
    // that is not registered is a page the stores cannot fetch — which is
    // how the URL Google rejected came to be dead in the first place. The
    // route itself is proved end to end by the build (the page renders and
    // /app-privacy appears in sitemap.xml); what a component test can add
    // is that the link the stores and readers follow is really emitted.
    testComponents('the footer links to the app notice on every page', (
      tester,
    ) {
      tester.pumpComponent(const App());

      expect(find.text('App privacy'), findsOneComponent);
    });
  });
}
