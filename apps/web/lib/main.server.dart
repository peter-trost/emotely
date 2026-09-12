/// The server entrypoint: runs once per route at build time (static mode)
/// and writes plain HTML. Nothing here runs in the browser.
library;

import 'package:emotely_web/app.dart';
import 'package:emotely_web/main.server.options.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/server.dart';

const _description =
    'emotely asks you a few good questions every evening and writes the '
    'journal entry for you. Five minutes, no blank page, open source, your '
    'words stay yours.';

void main() {
  Jaspr.initializeApp(options: defaultServerOptions);

  runApp(
    const Document(
      title: 'emotely — a journal that asks, listens and writes',
      lang: 'en',
      meta: {'description': _description, 'theme-color': '#f6f1e9'},
      head: [
        // Open Graph wants `property`, which Document.meta cannot emit.
        meta(attributes: {'property': 'og:title', 'content': 'emotely'}),
        meta(
          attributes: {'property': 'og:description', 'content': _description},
        ),
        meta(attributes: {'property': 'og:type', 'content': 'website'}),
        meta(
          attributes: {
            'property': 'og:url',
            'content': 'https://getemotely.com/',
          },
        ),
        link(rel: 'stylesheet', href: '/styles.css'),
        link(rel: 'icon', href: '/favicon.ico'),
        link(rel: 'preconnect', href: 'https://fonts.googleapis.com'),
        link(
          rel: 'preconnect',
          href: 'https://fonts.gstatic.com',
          attributes: {'crossorigin': ''},
        ),
        link(
          rel: 'stylesheet',
          href: 'https://fonts.googleapis.com/css2?family=Fraunces:opsz,wght@9..144,500;9..144,700&family=Inter:wght@400;600&display=swap',
        ),
      ],
      body: App(),
    ),
  );
}
