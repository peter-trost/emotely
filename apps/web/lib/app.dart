import 'package:emotely_web/environment.dart';
import 'package:emotely_web/pages/confirm.dart';
import 'package:emotely_web/pages/home.dart';
import 'package:emotely_web/pages/imprint.dart';
import 'package:emotely_web/pages/privacy.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_router/jaspr_router.dart';

/// The site: a header, one page per route, a footer. Built only on the
/// server; the sole client-side island is the waitlist form.
class const App({super.key}) extends StatelessComponent {
  @override
  Component build(BuildContext context) => div(classes: 'site', [
    const header(classes: 'site-header', [
      a(href: '/', classes: 'wordmark', [.text('emotely')]),
      nav([
        a(href: '/#how', [.text('How it works')]),
        a(href: '/#faq', [.text('Questions')]),
        a(href: repositoryUrl, [.text('GitHub')]),
      ]),
    ]),
    Router(
      routes: [
        Route(
          path: '/',
          title: 'emotely — a journal that asks, listens and writes',
          builder: (_, _) => const Home(),
        ),
        Route(
          path: '/confirm',
          title: 'Confirm your address — emotely',
          builder: (_, _) => const Confirm(),
        ),
        Route(
          path: '/privacy',
          title: 'Privacy — emotely',
          builder: (_, _) => const Privacy(),
        ),
        Route(
          path: '/imprint',
          title: 'Imprint — emotely',
          builder: (_, _) => const Imprint(),
        ),
      ],
    ),
    const footer(classes: 'site-footer', [
      p([
        .text('© 2026 Peter Trost · '),
        a(href: '/imprint', [.text('Imprint')]),
        .text(' · '),
        a(href: '/privacy', [.text('Privacy')]),
        .text(' · '),
        a(href: 'mailto:$contactEmail', [.text(contactEmail)]),
      ]),
    ]),
  ]);
}
