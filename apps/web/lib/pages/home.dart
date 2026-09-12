import 'package:emotely_web/components/waitlist_form.dart';
import 'package:emotely_web/environment.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

/// The landing page. One promise, the reason to believe it, the offer, the
/// risk reversal, the questions people actually have, one call to action.
class const Home({super.key}) extends StatelessComponent {
  @override
  Component build(BuildContext context) => main_(classes: 'page', [
    _hero(),
    _problem(),
    _howItWorks(),
    _whatYouGet(),
    _guarantee(),
    _builtInPublic(),
    _questions(),
    _finalCall(),
  ]);

  Component _hero() => const section(id: 'top', classes: 'hero', [
    p(classes: 'eyebrow', [.text('Early access · iOS and Android')]),
    h1([
      .text(
        'Know what you actually felt today. '
        'In five minutes, without staring at a blank page.',
      ),
    ]),
    p(classes: 'lede', [
      .text(
        'emotely asks you a handful of good questions every evening, '
        'listens, and writes the journal entry for you. '
        'Open source. Your words stay yours.',
      ),
    ]),
    WaitlistForm(),
  ]);

  Component _problem() => const section(classes: 'band', [
    h2([.text("Journaling works. Blank pages don't.")]),
    p([
      .text(
        'Everyone who sticks with a journal says the same thing: they '
        'understand themselves better, they sleep better, the bad days get '
        'smaller. Everyone who quits says the same thing too: the empty '
        'page, the "what do I even write", the third missed evening that '
        'turns into a missed month.',
      ),
    ]),
    p([
      .text(
        'emotely removes the part that makes people quit. You never write '
        'from nothing. You answer, and the entry writes itself.',
      ),
    ]),
  ]);

  Component _howItWorks() => section(id: 'how', [
    const h2([.text('How it works')]),
    ol(classes: 'steps', [
      _step(
        'Pick a question set',
        'Tonight: gratitude, a hard day, a decision, or the plain evening '
            'review.',
      ),
      _step(
        'Answer by tapping, not by writing essays',
        'A rating here, three words there, one honest sentence when it '
            'matters. Each answer gets a small native widget, not a chat box.',
      ),
      _step(
        'Read your entry back',
        'The assistant turns your answers into a real journal entry, in '
            'your words, filed in a journal you can scroll through.',
      ),
    ]),
  ]);

  Component _step(String title, String body) => li([
    h3([.text(title)]),
    p([.text(body)]),
  ]);

  Component _whatYouGet() => section(id: 'offer', classes: 'band', [
    const h2([.text('What you get')]),
    ul(classes: 'stack', [
      _item(
        'Guided evening sessions',
        'A structured reflection every night, five minutes, no blank page.',
      ),
      _item(
        'Entries written for you',
        'Answer the questions; the entry is drafted from exactly what you '
            'said.',
      ),
      _item(
        "A journal you'll actually read back",
        'Every entry, in order, on your phone, with the questions that '
            'shaped it.',
      ),
      _item(
        'Private by design',
        'Your journal lives in a database that only your account can read, '
            'on servers in the EU. Delete your account and everything goes '
            'with it, in one tap.',
      ),
      _item(
        'Open source, MIT',
        'The app, the assistant and the database rules are public. You '
            'never have to take our word for any of this.',
      ),
    ]),
  ]);

  Component _item(String title, String body) => li([
    strong([.text(title)]),
    span([.text(' — $body')]),
  ]);

  Component _guarantee() => const section(id: 'guarantee', [
    h2([.text('No catch')]),
    p(classes: 'lede', [
      .text(
        'Free during early access. Export or delete everything you wrote, '
        'any time. No ads, no selling your data, no "insights" shared with '
        'anyone. If emotely is not worth five minutes of your evening, you '
        'lose nothing but the five minutes.',
      ),
    ]),
  ]);

  Component _builtInPublic() => const section(classes: 'band', [
    h2([.text('Built in public')]),
    p([
      .text(
        'emotely is made by one person who journals with it every night '
        'and publishes every line of it. Read the code before you trust '
        'it: ',
      ),
      a(href: repositoryUrl, [.text('Read the code on GitHub')]),
      .text('.'),
    ]),
  ]);

  Component _questions() => section(id: 'faq', [
    const h2([.text('Questions')]),
    dl(classes: 'faq', [
      _qa(
        'Is this therapy?',
        'No. emotely is a journaling tool, not a substitute for therapy or '
            'medical care. If you are in crisis, please contact a '
            'professional or your local emergency number.',
      ),
      _qa(
        'Is my journal used to train AI?',
        'No. Your entries are never used to train anything, and the '
            'assistant sees your answers only while it writes your entry. '
            'Product analytics record that a session happened, never what '
            'was said.',
      ),
      _qa(
        'Which devices?',
        'iOS and Android. Phones first; tablets and foldables follow. Early '
            'access opens in small batches so every person gets a reply '
            'from a human.',
      ),
      _qa(
        'What does it cost?',
        'Nothing during early access. You will hear about any change by '
            'email first, with time to export.',
      ),
      _qa(
        'Who is behind it?',
        'Peter Trost, a Flutter developer in Germany, building emotely as '
            'a product and as a public AI engineering showcase.',
      ),
    ]),
  ]);

  Component _qa(String question, String answer) => div(classes: 'qa', [
    dt([.text(question)]),
    dd([.text(answer)]),
  ]);

  Component _finalCall() => const section(id: 'join', classes: 'final-call', [
    h2([.text('Your first entry is five minutes away')]),
    p([.text('Leave your address and get your spot in the next batch.')]),
    a(href: '#top', classes: 'cta', [.text('Get early access')]),
  ]);
}
