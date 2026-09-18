/// The journal feature: home. The entries so far, the way into the next
/// session (behind the consent gate), and each entry read back. The app
/// registers it with `registerJournal` and implements `JournalNavigator` —
/// the session, the consent screen, the account screen and signing out all
/// belong to other features, so the journal only asks for them.
library;

export 'src/navigator.dart';
export 'src/register.dart';
export 'src/view/entry_page.dart';
export 'src/view/journal_page.dart';
