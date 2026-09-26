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
    // A store reviewer arrives here cold, from a link in the listing, with
    // no idea what emotely is; the site-wide description sells the product
    // instead of saying what this page is.
    Document.head(
      meta: {
        'description':
            'How the emotely app collects, uses and shares data: the '
            'account, journal entries, the AI conversation, analytics, '
            'deletion and your GDPR rights.',
      },
    ),
    h1([.text('App privacy notice')]),
    // Google asks the policy to name the app as the listing has it; the
    // Play record keeps the legacy title until the first new version
    // ships (ADR 0012), so both names are given.
    p([
      .text(
        'This notice covers the emotely mobile app (listed on Google Play as '
        '"Reflect Therapy AI: emotely") for iOS and Android. The web site at '
        'getemotely.com and its waitlist are covered by a separate notice. '
        'Last updated 25 September 2026.',
      ),
    ]),

    // Ten sections is more than a reader should have to scroll blind, and a
    // store reviewer is looking for one specific thing.
    nav(classes: 'toc', [
      h2([.text('On this page')]),
      ul([
        li([
          a(href: '#responsible', [.text('Who is responsible')]),
        ]),
        li([
          a(href: '#collects', [.text('What the app collects, and why')]),
        ]),
        li([
          a(href: '#recipients', [.text('Who else sees any of it')]),
        ]),
        li([
          a(href: '#deletion', [.text('Deleting your account')]),
        ]),
        li([
          a(href: '#breach', [.text('If something goes wrong')]),
        ]),
        li([
          a(href: '#rights', [.text('Your rights')]),
        ]),
        li([
          a(href: '#automated', [.text('Automated decisions')]),
        ]),
        li([
          a(href: '#children', [.text('Children')]),
        ]),
        li([
          a(href: '#not-medical', [.text('Not a medical service')]),
        ]),
        li([
          a(href: '#web-site', [.text('The web site')]),
        ]),
        li([
          a(href: '#changes', [.text('Changes to this notice')]),
        ]),
      ]),
    ]),

    h2(id: 'responsible', [.text('Who is responsible')]),
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

    h2(id: 'collects', [.text('What the app collects, and why')]),

    h3([.text('Your email address')]),
    p([
      .text(
        'Signing in needs one thing: an email address. There are three ways '
        'to give it. The app can send a six-digit code to it that you type '
        'back in — no password, no link to click. Or you tap Sign in with '
        'Google (iOS and Android) or Sign in with Apple (iPhone), and that '
        'provider confirms who you are and tells us your address itself. '
        'Either way, the address and the sign-in records live in Supabase '
        'Auth on servers in Frankfurt, Germany (EU). The app has no sign-up '
        'screen of its own and never asks for a name, a phone number, a date '
        'of birth, contacts, photos, location or any device identifier for '
        'advertising.',
      ),
    ]),
    // #51. What each provider's token carries is what Supabase keeps, so
    // the notice names it — including the name Google sends unasked.
    p([
      .text(
        'If you sign in with Google or Apple, the provider also passes on an '
        'identifier for your account with them, which is how the next '
        'sign-in finds the same account. Google adds the name and profile '
        'picture link of your Google account, and Supabase keeps them with '
        'the sign-in records; the app does not show or use them. Apple can '
        'pass on a name too, but the app does not ask it to. Apple also lets '
        'you choose Hide My Email: we then receive a relay address that '
        'forwards to yours. If the address a provider passes on matches an '
        'account you already have, you land in that same account; a relay '
        'address never matches, so it starts a new one. We never see your '
        'Google or Apple password. The provider learns that you signed in '
        'to emotely — as a controller in its own right, under its own '
        'privacy policy — and nothing about your journal.',
      ),
    ]),
    p([
      .text(
        'While you are signed in, every request the app makes to our own '
        'server carries your sign-in token, which proves a signed-in user is '
        'asking and carries your account identifier and your address. It '
        'goes to our server and no further — it is never passed on to the '
        'gateway or the model provider.',
      ),
    ]),
    p([
      .text(
        'Basis: performing the contract you asked for (Art. 6 (1) (b) GDPR) '
        '— there is no journal without an account to keep it in. Giving the '
        'address is not a statutory duty, but it is required to use emotely '
        'at all: without one there is no account, and without an account '
        'there is nothing to journal into. Kept until you delete the '
        'account.',
      ),
    ]),

    h3([.text('Your journal entries and sessions')]),
    p([
      .text(
        'A session is one guided conversation: the assistant asks a '
        'question, you answer with a widget, and at the end it writes the '
        'entry. Three kinds of row are stored for you, and nothing else:',
      ),
    ]),
    ul([
      li([
        strong([.text('Sessions')]),
        .text(
          ' — the full transcript of the conversation, every question and '
          'every answer as the model saw them, plus the question you are '
          'currently on, the questions asked so far, which question set you '
          'picked, whether the session is finished, and the version of the '
          'app that wrote it. This is what lets a closed or crashed app pick '
          'a session back up.',
        ),
      ]),
      li([
        strong([.text('Entries')]),
        .text(
          ' — the finished entry: the summary the assistant wrote, your '
          'answers keyed by question, and the questions as they were asked.',
        ),
      ]),
      li([
        strong([.text('Consent')]),
        .text(
          ' — that you agreed to the conversation being sent to a model '
          'provider, when, and which version of this notice you were shown; '
          'and, if you take that consent back, when you did. The wording '
          'itself is not copied for each person: it is this page, and the '
          'record only names the version of it.',
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
        'under Art. 9 GDPR. The legal basis is your explicit consent '
        '(Art. 9 (2) (a) GDPR), alongside the contract itself '
        '(Art. 6 (1) (b) GDPR).',
      ),
    ]),
    p([
      .text(
        'Before your first session the app asks for that consent outright: it '
        'says what is sent, to whom, and what it can contain, and nothing is '
        'sent until you tick the box and start. Declining is a real choice — '
        'nothing is sent, and the entries you already have stay readable. You '
        'can take the consent back at any time on the More tab of the app. '
        'It is one tap, it does not require deleting anything, and it does not '
        'affect what happened while the consent stood. Taking it back is as '
        'easy as giving it, which is what Art. 7 (3) GDPR requires. Because '
        'the assistant is what writes your entry, no new session can run '
        'while the consent is withdrawn — you can give it again from the same '
        'screen whenever you want to.',
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
        'about. While a session runs, each round sends the emotely agent — a '
        'small server of ours — four things: the transcript so far (the '
        'questions and the answers you have given), the version of the app, '
        'your sign-in token, and a signature proving the transcript is the '
        'one the server itself produced. The agent then adds the '
        'assistant’s instructions and hands the conversation to a language '
        'model through the ',
      ),
      strong([.text('Vercel AI Gateway')]),
      .text(
        ', which passes it to whichever provider serves the model. What the '
        'gateway and the provider receive is the conversation and the '
        'instructions — no name, no email address and no sign-in token; your '
        'token stops at our server. The model’s reply comes back the same '
        'way and becomes the next question, or your finished entry.',
      ),
    ]),
    ul([
      li([
        strong([.text('The agent keeps no copy.')]),
        .text(
          ' It has no database and holds no journal: each request carries the '
          'whole transcript, is answered, and is forgotten. Nothing that was '
          'said is written to a log — the server never prints a question, an '
          'answer or a summary. It does send our analytics provider a '
          'technical record of each round — how long it took, how many tokens '
          'it used, what it cost, which version of the assistant’s '
          'instructions ran — with the content suppressed at the source, so '
          'the questions, your answers and the summary are never part of it. '
          'Your journal is stored in Supabase and nowhere else.',
        ),
      ]),
      li([
        strong([.text('Which model.')]),
        .text(
          ' Today it is openai/gpt-oss-120b, an open-weights model, chosen by '
          'a benchmark rather than by brand. It can change without a new app '
          'release; the default is in the public repository, and this notice '
          'names the model in use. Where it runs depends on which provider '
          'the gateway routes to at that moment.',
        ),
      ]),
      li([
        strong([.text('It is not training data, and it is not kept.')]),
        .text(
          ' Vercel states that the AI Gateway itself does not retain prompts '
          'or responses and does not use them for training. The providers '
          'behind it are a separate question, and the answer is not left to '
          'chance: every single round is sent with two instructions to the '
          'gateway — route only to providers contractually bound not to train '
          'on prompts, and route only to providers with a zero-retention '
          'agreement, meaning the transcript is not kept on their side '
          'either. Both are enforced by the gateway per request, not by us '
          'asking nicely, and both fail closed: if no qualifying provider '
          'were available the round would fail outright rather than quietly '
          'fall back to one that does not qualify. Checked against the live '
          'gateway on 15 September 2026, all eight providers that serve the '
          'current model satisfy both.',
        ),
      ]),
    ]),
    p([
      .text(
        'Basis: performing the contract (Art. 6 (1) (b) GDPR) and, because '
        'the transcript can carry the special-category content described '
        'above, your explicit consent (Art. 9 (2) (a) GDPR). The gateway and '
        'the model provider act as processors under Art. 28 GDPR. Providers '
        'may sit outside the EU; for those transfers the safeguard under '
        'Art. 46 GDPR is the EU standard contractual clauses, and on top of '
        'them sit the two routing guarantees above — no training on the '
        'transcript, and no retention of it at the provider. If that is more '
        'than you want to share, the honest answer is that the assistant is '
        'the product and there is no version of it that does not send your '
        'answers to a model — which is why the app asks before the first '
        'session rather than after.',
      ),
    ]),
    // EU AI Act Art. 50, in force since 2 August 2026: a person must be told
    // they are interacting with an AI system. The exemption is for cases
    // where it is obvious, and it arguably is here — but "arguably obvious"
    // is not a thing to rest a disclosure obligation on.
    p([
      .text(
        'Said plainly rather than left to be inferred: the questions you are '
        'asked and the entry that gets written are produced by an AI system, '
        'not by a person. Nobody reads along, there is no human on the other '
        'end of a session, and the summary of your day was written by a '
        'machine.',
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
    p([
      .text(
        'There is one exception: the app occasionally asks you for feedback '
        'in a short survey. Answering is optional, and if you do answer, '
        'what you write is sent to PostHog.',
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
          'sign_in_code_rejected, sign_in_password_failed, '
          'sign_in_provider_canceled, sign_in_provider_failed, signed_in, '
          'signed_out, account_deleted. The provider events and signed_in '
          'say which way you signed in (code, password, Google or Apple) '
          'and nothing more.',
        ),
      ]),
      li([
        strong([.text('The journal')]),
        .text(': journal_viewed, entry_opened, session_discarded.'),
      ]),
      li([
        strong([.text('Consent')]),
        .text(
          ': consent_granted, consent_withdrawn, consent_declined — each with '
          'the version of this notice it answered, and nothing else.',
        ),
      ]),
      li([
        strong([.text('From the analytics library itself')]),
        .text(
          ': it also records, without us writing the code, that the app was '
          'opened, sent to the background, installed or updated.',
        ),
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
        'its stack frames. Only a short list of message types is let through, '
        'and they can only contain our own server’s wording or the name of '
        'a host. No session replay and no screen recording is used at all.',
      ),
    ]),
    p([
      .text(
        'These records are tied to two identifiers: your account identifier '
        '— a random identifier, not your address — and a device identifier '
        'the analytics library keeps on the phone so events from one device '
        'hang together. Both are pseudonymous, not anonymous. Signing out or '
        'deleting the account resets the link between the device identifier '
        'and you. Basis: our legitimate interest in knowing whether the app '
        'works and where it breaks (Art. 6 (1) (f) GDPR). Kept for as long as '
        'the numbers are useful for that and no longer than our analytics '
        'provider’s retention window for the project, after which they are '
        'deleted or aggregated past the point of tracing back to a person.',
      ),
    ]),
    p([
      .text(
        'Everything the app sends — to our server, to the database and to the '
        'analytics provider — travels over an encrypted HTTPS connection, and '
        'the app makes no unencrypted connection at all.',
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

    h2(id: 'recipients', [.text('Who else sees any of it')]),
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
          'travels through. Stores no journal of ours. Its firewall also '
          'counts requests per internet address and refuses more than thirty '
          'a minute to the session endpoint, which is what keeps a public '
          'endpoint from being abused; that check uses the address and '
          'nothing else, on our legitimate interest in keeping the service '
          'working (Art. 6 (1) (f) GDPR).',
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
          'Never receives journal content or your email address. The one '
          'free text it does receive is what you type into an in-app '
          'survey, if you choose to answer one.',
        ),
      ]),
      li([
        strong([.text('Apple and Google')]),
        .text(
          ' — distribute the app and, independently of us, collect their own '
          'download and crash statistics under their own privacy policies. If '
          'you sign in with one of them, it confirms who you are, as described '
          'under your email address above.',
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
    // Apple Guideline 5.1.1(i) asks the policy to confirm that third
    // parties receiving user data provide equal protection of it — a
    // separate statement from naming them, and one a reviewer looks for.
    p([
      .text(
        'Every one of them except Apple and Google handles this data only on '
        'our instructions, as a processor under a data processing agreement '
        '(Art. 28 GDPR) that binds them to protect it to the same standard '
        'described here and forbids them using it for their own purposes. '
        'Apple and Google are not our processors: what they collect when '
        'they distribute the app, they collect as controllers in their own '
        'right, under their own policies and outside our reach.',
      ),
    ]),

    h2(id: 'deletion', [.text('Deleting your account')]),
    p([
      .text(
        'In the app: More → Your account → Delete account, then confirm. '
        'Without the app: the ',
      ),
      a(href: '/delete-account', [.text('deletion page')]),
      .text(
        ', which mails you a code and deletes the account once you type it '
        'back in.',
      ),
    ]),
    p([
      .text(
        'Either way the account, every entry, every session and the consent '
        'record are removed from the live database as soon as the deletion '
        'goes through. There is no grace period and no archive to ask for '
        'afterwards. Three things outlive it:',
      ),
    ]),
    ul([
      li([
        strong([.text('Counting.')]),
        .text(
          ' The pseudonymous records described above. Deleting the account '
          'breaks the link between those identifiers and you, but the counts '
          'themselves remain. They hold no journal text and no address.',
        ),
      ]),
      li([
        strong([.text('Backups.')]),
        .text(
          ' Routine encrypted backups of the database as a whole may still '
          'hold a copy until they age out of the provider’s retention '
          'window. They are only ever used to recover the database after a '
          'failure, never to bring a deleted account back.',
        ),
      ]),
      li([
        strong([.text('The waitlist, if you joined it.')]),
        .text(
          ' That is a separate list behind the web site, and deleting your '
          'app account does not touch it. Write to ',
        ),
        a(href: 'mailto:$contactEmail', [.text(contactEmail)]),
        .text(' and it is removed too.'),
      ]),
    ]),

    // Art. 33/34 GDPR. The legacy lawyer-drafted policy said this and the
    // rewrite dropped it; for a journal that can carry Art. 9 data, what
    // happens when the measures fail is not an optional paragraph.
    h2(id: 'breach', [.text('If something goes wrong')]),
    p([
      .text(
        'The measures above are meant to stop a breach, not to promise one '
        'is impossible. If personal data here is ever exposed, lost or '
        'reached by someone who should not have it, the supervisory '
        'authority named below is told without undue delay and within 72 '
        'hours of us becoming aware of it, as Art. 33 GDPR requires. Where '
        'the breach is likely to put you at high risk — and for journal '
        'entries it would be — you are told directly, in plain language, '
        'without waiting to be asked (Art. 34 GDPR).',
      ),
    ]),

    h2(id: 'rights', [.text('Your rights')]),
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
        ' — the same address for any privacy question, answered by Peter '
        'Trost personally. You will have an answer within one month of '
        'asking, as Art. 12 (3) GDPR requires; if a request is genuinely '
        'complicated we will say so within that month and why. You may also '
        'complain to a data protection authority. The one responsible for us '
        'is Der Landesbeauftragte für den Datenschutz und die '
        'Informationsfreiheit Baden-Württemberg, Lautenschlagerstraße 20, '
        '70173 Stuttgart, poststelle@lfdi.bwl.de.',
      ),
    ]),

    h2(id: 'automated', [.text('Automated decisions')]),
    p([
      .text(
        'The assistant works automatically: it picks which question to ask '
        'next and writes the summary of your entry without anyone reading '
        'along. That is the whole product, and it is the only automated '
        'processing here. No decision is made about you that has legal '
        'effects or similarly significantly affects you — nothing is scored, '
        'profiled, ranked, or passed to anyone who decides something about '
        'you — so the rule on automated individual decision-making, '
        'Art. 22 (1) GDPR, does not apply.',
      ),
    ]),

    h2(id: 'children', [.text('Children')]),
    p([
      .text(
        'emotely is for users aged 16 and over. It is not made for children '
        'and is not directed at them: it collects nothing for advertising '
        'and shows no ads. Sixteen is the age at which German law lets you '
        'consent to this processing on your own (Art. 8 GDPR, § 1 TDDDG), '
        'and because the whole product runs on your consent, that is the '
        'minimum the app assumes. We do not verify age, and the store age '
        'ratings are still being set as part of the release — once they '
        'are, this section will name them too. If you believe a child has '
        'written entries here, write to ',
      ),
      a(href: 'mailto:$contactEmail', [.text(contactEmail)]),
      .text(' and the account will be deleted.'),
    ]),

    h2(id: 'not-medical', [.text('Not a medical service')]),
    p([
      .text(
        'emotely is a journaling tool. It is not therapy, not a medical '
        'device and not a substitute for professional care, and the '
        'assistant does not diagnose or treat anything. If you are in '
        'crisis, please contact a professional or your local emergency '
        'number.',
      ),
    ]),

    h2(id: 'web-site', [.text('The web site')]),
    p([
      .text('getemotely.com and the early-access waitlist are covered by the '),
      a(href: '/privacy', [.text('site privacy notice')]),
      .text(', which is a separate text about separate data.'),
    ]),

    h2(id: 'changes', [.text('Changes to this notice')]),
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
