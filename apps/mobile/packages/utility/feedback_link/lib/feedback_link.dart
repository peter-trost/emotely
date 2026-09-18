/// The way feedback leaves the app during the beta: a prefilled mail to
/// hello@getemotely.com, carrying a blank line for the user to write in and
/// a footer naming the build they are running.
///
/// It has its own package rather than sitting with the legal links: those
/// two documents are there because the stores and § 5 DDG require them to
/// be reachable, and this is a support channel we chose. Sharing a
/// `url_launcher` dependency is not a shared concern.
library;

export 'src/feedback_link.dart';
export 'src/register.dart';
