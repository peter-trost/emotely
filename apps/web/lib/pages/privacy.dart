import 'package:emotely_web/environment.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

/// What this site does with data. The site itself stores one thing: an
/// address someone typed into the waitlist form.
class const Privacy({super.key}) extends StatelessComponent {
  @override
  Component build(BuildContext context) => const main_(classes: 'page prose', [
    h1([.text('Privacy')]),
    p([
      .text(
        'This page covers getemotely.com, the web site. The app has its own '
        'notice inside it.',
      ),
    ]),

    h2([.text('What the site stores')]),
    p([
      .text(
        'Nothing, unless you join the waitlist. Then it stores the email '
        'address you typed, the moment you sent it, a "source" tag (the '
        'campaign tags in the link you used, or the site that linked here), '
        'and the IP address of the request. The IP is kept only to limit '
        'abuse of the form and is not linked to anything else.',
      ),
    ]),

    h2([.text('Who handles it')]),
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
          ' hosts the site and keeps ordinary server logs for a short time.',
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
        'No cookies, no tracking pixels and nothing stored in your browser '
        'are used on this site.',
      ),
    ]),

    h2([.text('Why, and for how long')]),
    p([
      .text(
        'The address is used for exactly one purpose: to tell you when '
        'early access opens for you. That is the agreement you enter by '
        'submitting the form (Art. 6 (1) (a) GDPR). It stays on the list '
        'until you ask for it to be removed or until early access is over, '
        'whichever comes first.',
      ),
    ]),

    h2([.text('Your rights')]),
    p([
      .text(
        'You can ask what is stored about you, have it corrected or '
        'deleted, or withdraw your consent at any time by writing to ',
      ),
      a(href: 'mailto:$contactEmail', [.text(contactEmail)]),
      .text(
        '. You also have the right to complain to a data protection '
        'authority.',
      ),
    ]),

    h2([.text('Responsible')]),
    p([
      .text(
        'Peter Trost, Yalovastr. 5, 72108 Rottenburg am Neckar, Germany. '
        'See the imprint.',
      ),
    ]),
  ]);
}
