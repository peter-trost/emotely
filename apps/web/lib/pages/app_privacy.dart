import 'package:emotely_web/environment.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

/// `/app-privacy`: what the **app** does with data, as Art. 13 GDPR and both
/// stores ask for it. Sibling of the site notice at `/privacy`.
///
/// Google Play rejected the 2026-09-13 update because the privacy URL on the
/// listing did not resolve to a policy covering the app; `/privacy` opens by
/// disclaiming the app, so a reviewer reading it would reject again. Both
/// store listings point here from now on.
///
/// Every claim below is traceable to a migration, an ADR, the app's code or a
/// vendor's published policy — an unknown is written as an unknown rather
/// than smoothed over, because this is a text the controller signs off on.
class const AppPrivacy({super.key}) extends StatelessComponent {
  @override
  Component build(BuildContext context) => const main_(classes: 'page prose', [
    h1([.text('App privacy notice')]),
    // Google asks the policy to name the app as the listing has it; the
    // Play record keeps the legacy title until the first new version
    // ships (ADR 0012), so both names are given.
    p([
      .text(
        'This notice covers the emotely mobile app (listed on Google Play as '
        '"Reflect Therapy AI: emotely") for iOS and Android. The web site at '
        'getemotely.com and its waitlist are covered by a separate notice. '
        'Last updated 15 September 2026.',
      ),
    ]),

    h2([.text('Who is responsible')]),
    p([
      .text('Peter Trost, Yalovastr. 5, 72108 Rottenburg am Neckar, Germany, '),
      a(href: 'mailto:$contactEmail', [.text(contactEmail)]),
      .text(
        '. Sole controller for everything below; there is no company and no '
        'co-controller. Full details in the ',
      ),
      a(href: '/imprint', [.text('imprint')]),
      .text('.'),
    ]),

    h2([.text('What the app collects, and why')]),

    h3([.text('Your email address')]),
    p([
      .text(
        'Signing in needs one thing: an email address. The app sends a '
        'six-digit code to it and you type the code back in — no password, '
        'no link to click. The address and the sign-in records live in '
        'Supabase Auth on servers in Frankfurt, Germany (EU). The app has no '
        'sign-up screen of its own and never asks for a name, a phone '
        'number, a date of birth, contacts, photos, location or any device '
        'identifier for advertising.',
      ),
    ]),
    p([
      .text(
        'Basis: performing the contract you asked for (Art. 6 (1) (b) GDPR) '
        '— there is no journal without an account to keep it in. Kept until '
        'you delete the account.',
      ),
    ]),

    h3([.text('Your journal entries and sessions')]),
    p([
      .text(
        'A session is one guided conversation: the assistant asks a '
        'question, you answer with a widget, and at the end it writes the '
        'entry. Two kinds of row are stored for you, and nothing else:',
      ),
    ]),
    ul([
      li([
        strong([.text('Sessions')]),
        .text(
          ' — the running conversation with the assistant, the question you '
          'are currently on, the questions asked so far, which question set '
          'you picked, whether the session is finished, and the version of '
          'the app that wrote it. This is what lets a closed or crashed app '
          'pick a session back up.',
        ),
      ]),
      li([
        strong([.text('Entries')]),
        .text(
          ' — the finished entry: the summary the assistant wrote, your '
          'answers keyed by question, and the questions as they were asked.',
        ),
      ]),
    ]),
    p([
      .text(
        'Both live in one Postgres database at Supabase in Frankfurt, '
        'Germany (EU), and both are readable only by the account that wrote '
        'them. That is not a promise about how the app behaves, it is a rule '
        'the database enforces on every single query (row-level security): '
        'the app talks to the database with your own sign-in token, and a '
        'query for somebody else’s rows comes back empty no matter who '
        'sends it. The rules are in the open-source ',
      ),
      a(href: '$repositoryUrl/blob/main/supabase/migrations', [
        .text('database migrations'),
      ]),
      .text(
        ', and a test suite in the repository proves them on every change.',
      ),
    ]),
    p([
      strong([.text('This is sensitive data, and it is treated as such.')]),
      .text(
        ' A journal entry can say how you felt, how you slept, what a '
        'diagnosis or a medication is doing to you, how things stand with a '
        'partner, a parent or a colleague, or what you believe. That makes '
        'entries capable of holding health data and other special categories '
        'under Art. 9 GDPR. The app processes them only because you chose to '
        'write them and chose to have the assistant read them: the legal '
        'basis is your explicit consent (Art. 9 (2) (a) GDPR), alongside the '
        'contract itself (Art. 6 (1) (b) GDPR). You give that consent by '
        'writing an entry, you withdraw it by deleting your account, and '
        'nothing about the app works without it.',
      ),
    ]),
    p([
      .text(
        'Entries are kept until you delete them or delete the account. There '
        'is no automatic expiry: a journal that quietly erased last year '
        'would not be a journal.',
      ),
    ]),

    h3([.text('The conversation with the assistant')]),
    p([
      .text(
        'This is the part that leaves your phone, so it is worth being exact '
        'about. While a session runs, the transcript so far — the questions '
        'and the answers you have given — is sent to the emotely agent, a '
        'small server of ours, together with the version of the app and a '
        'signature that proves the transcript is the one the server itself '
        'produced. The agent adds the assistant’s instructions and hands '
        'the whole thing to a language model through the ',
      ),
      strong([.text('Vercel AI Gateway')]),
      .text(
        ', which passes it to whichever provider serves the model. The '
        'model’s reply comes back the same way and becomes the next '
        'question, or your finished entry.',
      ),
    ]),
    ul([
      li([
        strong([.text('The agent keeps no copy.')]),
        .text(
          ' It has no database and holds no journal: each request carries the '
          'whole transcript, is answered, and is forgotten. Nothing that was '
          'said is written to a log — the server never prints a question, an '
          'answer or a summary. Your journal is stored in Supabase and '
          'nowhere else.',
        ),
      ]),
      li([
        strong([.text('Which model.')]),
        .text(
          ' Today it is openai/gpt-oss-120b, an open-weights model, chosen by '
          'a benchmark rather than by brand. It can change — the model in use '
          'is recorded in the public repository and can be switched without a '
          'new app release. Where it runs depends on which provider the '
          'gateway routes to at that moment.',
        ),
      ]),
      li([
        strong([.text('Training: what we can and cannot promise.')]),
        .text(
          ' Vercel states that the AI Gateway itself does not retain prompts '
          'or responses and does not use them for training. The providers '
          'behind it are a separate question: the gateway offers settings '
          'that restrict routing to providers which contractually disallow '
          'training on prompts, and those settings are ',
        ),
        strong([.text('not currently switched on')]),
        .text(
          ' for emotely. So we will not tell you that no provider could ever '
          'train on what you wrote. What is true today is that the gateway '
          'does not retain it, that the transcript carries no name and no '
          'email address — only what you typed — and that turning the '
          'no-training routing on is an open item, tracked publicly. When it '
          'is on, this notice will say so plainly.',
        ),
      ]),
    ]),
    p([
      .text(
        'Basis: performing the contract (Art. 6 (1) (b) GDPR) and, because '
        'the transcript can carry the special-category content described '
        'above, your explicit consent (Art. 9 (2) (a) GDPR). The gateway and '
        'the model provider act as processors under Art. 28 GDPR; where a '
        'provider sits outside the EU the transfer rests on the EU standard '
        'contractual clauses (Art. 46 GDPR). If that is more than you want '
        'to share, the honest answer is that the assistant is the product '
        'and there is no version of it that does not send your answers to a '
        'model.',
      ),
    ]),

    h3([.text('Counting and crash reports')]),
    p([
      .text(
        'The app reports to PostHog on servers in the EU, and what it '
        'reports is deliberately content-free: not "redacted before '
        'sending", but built so the text never reaches the reporting code in '
        'the first place. Events say that something happened and how it '
        'went, never what was said.',
      ),
    ]),
    ul([
      li([
        strong([.text('Sessions')]),
        .text(
          ': session_started, question_asked, answer_submitted, '
          'session_completed, session_resumed, session_retried, '
          'session_failed, session_save_failed, entry_save_failed, '
          'update_required.',
        ),
      ]),
      li([
        strong([.text('Signing in')]),
        .text(
          ': sign_in_code_requested, sign_in_code_request_failed, '
          'sign_in_code_rejected, sign_in_password_failed, signed_in, '
          'signed_out, account_deleted.',
        ),
      ]),
      li([
        strong([.text('The journal')]),
        .text(': journal_viewed, entry_opened, session_discarded.'),
      ]),
    ]),
    p([
      .text(
        'The properties they carry are of the same kind throughout: a '
        'question’s identifier (not its text), which sort of widget it '
        'used, a position in the session, a count of entries or answers, an '
        'HTTP status code, an app version, the name of the step that failed. '
        'Your journal text, your email address and your sign-in codes appear '
        'in none of them, and a test drives a whole session with marker '
        'strings planted in the question, the answer and the summary to '
        'prove none of them escapes.',
      ),
    ]),
    p([
      .text(
        'Crashes reach the same place. Because an error message often quotes '
        'what it choked on — a database error names the row, a sign-in error '
        'names the address — the app strips the message from every crash '
        'report before it is sent, keeping the error’s type, its code and '
        'its stack frames. Only three kinds of message are let through, and '
        'they can only contain our own server’s wording or the name of a '
        'host. No session replay and no screen recording is used at all.',
      ),
    ]),
    p([
      .text(
        'Counting is tied to your account identifier — a random identifier, '
        'not your address — so these records are pseudonymous, not anonymous. '
        'Basis: our legitimate interest in knowing whether the app works and '
        'where it breaks (Art. 6 (1) (f) GDPR). Signing out or deleting the '
        'account makes the app forget who this device belongs to.',
      ),
    ]),

    h3([.text('The store reviewer accounts')]),
    p([
      .text(
        'Two fixed accounts sign in with a password instead of a code, '
        'because Apple’s and Google’s reviewers have no mailbox to '
        'read a code from. They belong to the review process, not to any '
        'user, and nothing in the app can create one.',
      ),
    ]),

    h2([.text('Who else sees any of it')]),
    ul([
      li([
        strong([.text('Supabase')]),
        .text(
          ' — the database and the sign-in system, Frankfurt, Germany (EU). '
          'Holds your address, your sessions and your entries.',
        ),
      ]),
      li([
        strong([.text('Vercel')]),
        .text(
          ' — runs the emotely agent and the AI Gateway the transcript '
          'travels through. Stores no journal of ours.',
        ),
      ]),
      li([
        strong([.text('The model provider')]),
        .text(
          ' — whoever serves the current model through the gateway, for the '
          'moment it takes to answer. See the section above for what is and '
          'is not promised there.',
        ),
      ]),
      li([
        strong([.text('PostHog')]),
        .text(
          ' — the counting and crash reports described above, on EU servers. '
          'Never receives journal content or your email address.',
        ),
      ]),
      li([
        strong([.text('Apple and Google')]),
        .text(
          ' — distribute the app and, independently of us, collect their own '
          'download and crash statistics under their own privacy policies.',
        ),
      ]),
    ]),
    p([
      .text(
        'Nothing is sold, nothing is shared for advertising, and there are '
        'no ad networks, no trackers and no third-party software development '
        'kits in the app beyond the ones named here.',
      ),
    ]),

    h2([.text('Deleting your account')]),
    p([
      .text(
        'In the app: Your journal → the account icon (top right) → Delete '
        'account, then confirm. Without the app: the ',
      ),
      a(href: '/delete-account', [.text('deletion page')]),
      .text(
        ', which mails you a code and deletes the account once you type it '
        'back in.',
      ),
    ]),
    p([
      .text(
        'Either way the account, every entry and every session go from the '
        'live database immediately. There is no grace period and no archive '
        'to ask for afterwards. Two things outlive it, and neither holds '
        'your journal or your address: the pseudonymous counting described '
        'above, where deleting breaks the link to you but the counts remain; '
        'and routine encrypted backups of the database as a whole, which may '
        'still hold a copy until they age out of the provider’s retention '
        'window and are only ever used to recover from a failure, never to '
        'bring a deleted account back.',
      ),
    ]),

    h2([.text('Your rights')]),
    p([
      .text(
        'You can ask what is stored about you, have it corrected or deleted, '
        'have its processing restricted, receive it in a portable form, '
        'object to processing based on legitimate interest, and withdraw '
        'consent at any time — which does not affect what happened before. '
        'Deleting the account does all of this at once; for anything else, '
        'write to ',
      ),
      a(href: 'mailto:$contactEmail', [.text(contactEmail)]),
      .text(
        '. You may also complain to a data protection authority. The one '
        'responsible for us is Der Landesbeauftragte für den Datenschutz und '
        'die Informationsfreiheit Baden-Württemberg, Lautenschlagerstraße 20, '
        '70173 Stuttgart, poststelle@lfdi.bwl.de.',
      ),
    ]),

    h2([.text('Children')]),
    p([
      .text(
        'emotely is not made for children, and the app is not directed at '
        'them: it collects nothing for advertising and shows no ads. We do '
        'not currently verify age, and the store age ratings are still being '
        'set as part of the release — once they are, this section will name '
        'them. Until then, please do not use emotely if you are under 16, '
        'the age at which German law lets you consent to this processing on '
        'your own (Art. 8 GDPR, § 1 TDDDG). If you believe a child has '
        'written entries here, write to ',
      ),
      a(href: 'mailto:$contactEmail', [.text(contactEmail)]),
      .text(' and the account will be deleted.'),
    ]),

    h2([.text('Not a medical service')]),
    p([
      .text(
        'emotely is a journaling tool. It is not therapy, not a medical '
        'device and not a substitute for professional care, and the '
        'assistant does not diagnose or treat anything. If you are in '
        'crisis, please contact a professional or your local emergency '
        'number.',
      ),
    ]),

    h2([.text('The web site')]),
    p([
      .text('getemotely.com and the early-access waitlist are covered by the '),
      a(href: '/privacy', [.text('site privacy notice')]),
      .text(', which is a separate text about separate data.'),
    ]),

    h2([.text('Changes to this notice')]),
    p([
      .text(
        'Changes are published on this page with a new date at the top, and '
        'every version of it is in the public repository, so what changed and '
        'when is a matter of record. Anything that materially changes what '
        'happens to your journal will be told to you in the app or by email '
        'before it takes effect. emotely is open source under the MIT '
        'licence: you never have to take our word for any of this — ',
      ),
      a(href: repositoryUrl, [.text('read the code')]),
      .text('.'),
    ]),
  ]);
}
