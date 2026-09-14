import 'package:emotely_web/environment.dart';
import 'package:emotely_web/pages/confirm.dart';
import 'package:emotely_web/pages/delete_account.dart';
import 'package:emotely_web/pages/home.dart';
import 'package:emotely_web/pages/imprint.dart';
import 'package:emotely_web/pages/privacy.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_router/jaspr_router.dart';

/// The site: a header, one page per route, a footer. Built only on the
/// server; the client-side islands are the waitlist form, the waitlist
/// confirmation and the account-deletion form.
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
          path: '/delete-account',
          title: 'Delete your account — emotely',
          builder: (_, _) => const DeleteAccount(),
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
        // Google asks for the deletion route to be easy to find, so it
        // sits in the footer of every page rather than only in privacy.
        a(href: '/delete-account', [.text('Delete your account')]),
        .text(' · '),
        a(href: 'mailto:$contactEmail', [.text(contactEmail)]),
      ]),
    ]),
  ]);
}
