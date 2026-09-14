import 'package:emotely_web/components/delete_account_form.dart';
import 'package:emotely_web/environment.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

/// `/delete-account`: how to delete an emotely account, both ways.
///
/// Google Play's account-deletion policy asks for a web page that works for
/// people who have already uninstalled the app, which the in-app path
/// cannot serve. The in-app route comes first because it is the shorter one
/// for anyone still holding the app; the form below is for everyone else.
class const DeleteAccount({super.key}) extends StatelessComponent {
  @override
  Component build(BuildContext context) => const main_(classes: 'page prose', [
    h1([.text('Delete your account')]),
    p([
      .text(
        'Deleting is immediate and total: the account, every journal entry '
        'and session in it, and the email address itself are removed from '
        'the database. There is no grace period, no archive and no backup '
        'copy to ask for afterwards.',
      ),
    ]),

    h2([.text('If you still have the app')]),
    p([
      .text(
        'This is the quickest way, and it needs no code: open emotely and '
        'go to ',
      ),
      strong([
        .text(
          'Your journal → the account icon (top right) → Delete '
          'account',
        ),
      ]),
      .text(', then confirm. The app signs you out as it finishes.'),
    ]),

    h2([.text('If you no longer have the app')]),
    p([
      .text(
        'Use the form below. It sends a six-digit code to your address to '
        'be sure the request comes from you — the same check the app makes '
        'when you sign in — and deletes the account once you type the code '
        'back in. It creates nothing: an address without an emotely '
        'account stays without one.',
      ),
    ]),
    DeleteAccountForm(),

    h2([.text('What gets deleted')]),
    ul([
      li([.text('Your sign-in account and the email address on it.')]),
      li([
        .text(
          'Every journal entry: the summaries, your answers and the '
          'questions as they were asked.',
        ),
      ]),
      li([
        .text(
          'Every session, finished or half-finished, and the transcript in '
          'it.',
        ),
      ]),
    ]),
    p([
      .text(
        'Journal content lives in one database and nowhere else — it is '
        'never sent to an analytics provider — so deleting the account '
        'deletes it everywhere. What remains afterwards is anonymous '
        'counting that was never tied to you: how many people opened a '
        'page or finished a session, with no address and no identifier in '
        'it. If you also joined the waitlist with the same address, that '
        'is a separate list; write to ',
      ),
      a(href: 'mailto:$contactEmail', [.text(contactEmail)]),
      .text(' and it is removed too.'),
    ]),

    h2([.text('If something goes wrong')]),
    p([
      .text('Write to '),
      a(href: 'mailto:$contactEmail', [.text(contactEmail)]),
      .text(
        ' from the address on the account and we will delete it by hand. '
        'You can also read exactly what the deletion does in the ',
      ),
      a(href: '$repositoryUrl/blob/main/supabase/migrations', [
        .text('database migrations'),
      ]),
      .text(' — the site and the app are open source.'),
    ]),
  ]);
}
