import 'package:emotely_web/environment.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

/// What this site does with data: the notice Art. 13 GDPR asks for, in the
/// order a reader asks the questions. The site stores one thing, an
/// address someone typed into the waitlist form; everything else here is
/// the machinery around that.
class const Privacy({super.key}) extends StatelessComponent {
  @override
  Component build(BuildContext context) => const main_(classes: 'page prose', [
    h1([.text('Privacy')]),
    p([
      .text(
        'This page covers getemotely.com, the web site. The app has its own '
        'notice inside it. Last updated 12 September 2026.',
      ),
    ]),

    h2([.text('What the site stores')]),
    p([
      .text(
        'Nothing, unless you join the waitlist. Then it stores the email '
        'address you typed, the moment you sent it, a "source" tag (the '
        'campaign tags in the link you used, or the site that linked here) '
        'and the IP address of the request. The IP address exists only to '
        'limit abuse of the form: it is erased after one day, before it '
        'could be linked to anything.',
      ),
    ]),

    h2([.text('Why, and on what basis')]),
    ul([
      li([
        strong([.text('Your address')]),
        .text(
          ' is kept so we can tell you when early access opens for you. '
          'Basis: your consent (Art. 6 (1) (a) GDPR), given by submitting '
          'the form. Giving the address is voluntary; without it there is '
          'simply no spot to hold. You can withdraw the consent at any '
          'time, which does not affect what happened before.',
        ),
      ]),
      li([
        strong([.text('Abuse limits and server logs')]),
        .text(
          ": the IP check on the form and the hosting provider's "
          'short-lived request logs. Basis: our legitimate interest in '
          'keeping the site and the list working (Art. 6 (1) (f) GDPR).',
        ),
      ]),
      li([
        strong([.text('Visit counts')]),
        .text(
          ': how many people visit and sign up, per page and per link. '
          'Basis: our legitimate interest in knowing whether the site works '
          '(Art. 6 (1) (f) GDPR). The counting stores nothing on your '
          'device and reads nothing from it, so no consent under § 25 '
          'TDDDG is needed and there is no cookie banner.',
        ),
      ]),
      li([
        strong([.text('Email you send us')]),
        .text(
          ': if you write to us, your message and address are kept for as '
          'long as it takes to answer, and afterwards only where the law '
          'requires it (Art. 6 (1) (b) and (f) GDPR).',
        ),
      ]),
    ]),

    h2([.text('Who handles it')]),
    p([
      .text(
        'Four providers process data for us under data processing '
        "agreements (Art. 28 GDPR). Where a provider's parent company sits "
        'outside the EU, the transfer rests on the EU standard contractual '
        'clauses (Art. 46 GDPR).',
      ),
    ]),
    ul([
      li([
        strong([.text('Supabase')]),
        .text(
          ' stores the waitlist in a Postgres database in Frankfurt, '
          'Germany (EU).',
        ),
      ]),
      li([
        strong([.text('Resend')]),
        .text(
          ' sends the email that tells you your spot is open, from servers '
          'in the EU.',
        ),
      ]),
      li([
        strong([.text('Vercel')]),
        .text(
          ' serves the site from its edge network and keeps ordinary '
          'request logs for a short time.',
        ),
      ]),
      li([
        strong([.text('PostHog')]),
        .text(
          ' counts visits and waitlist sign-ups on servers in the EU, '
          'without cookies or any identifier stored in your browser: visits '
          'are grouped by a hash that changes daily, and your IP address is '
          'discarded before anything is kept. It sees which page you '
          'viewed and where the link came from, never your email address.',
        ),
      ]),
    ]),
    p([
      .text(
        'The fonts, icons and images are served from this site itself, not '
        'from Google or any other third party; the only outside script is '
        "PostHog's, loaded from its EU servers. No cookies, no tracking "
        'pixels and nothing stored in your browser are used on this site.',
      ),
    ]),

    h2([.text('For how long')]),
    p([
      .text(
        'Your address stays on the list until early access is over or you '
        'ask for it to be removed, whichever comes first. The IP address is '
        'gone after a day. Request logs are gone after a short time. Visit '
        'counts are aggregated and cannot be traced back to you.',
      ),
    ]),

    h2([.text('Your rights')]),
    p([
      .text(
        'You can ask what is stored about you, have it corrected or '
        'deleted, have its processing restricted, receive it in a portable '
        'form, object to processing based on legitimate interest, or '
        'withdraw your consent at any time by writing to ',
      ),
      a(href: 'mailto:$contactEmail', [.text(contactEmail)]),
      .text(
        '. You also have the right to complain to a data protection '
        'authority. The one responsible for us is Der Landesbeauftragte für '
        'den Datenschutz und die Informationsfreiheit Baden-Württemberg, '
        'Lautenschlagerstraße 20, 70173 Stuttgart, poststelle@lfdi.bwl.de.',
      ),
    ]),

    h2([.text('Responsible')]),
    p([
      .text('Peter Trost, Yalovastr. 5, 72108 Rottenburg am Neckar, Germany, '),
      a(href: 'mailto:$contactEmail', [.text(contactEmail)]),
      .text('. See the imprint.'),
    ]),
  ]);
}
