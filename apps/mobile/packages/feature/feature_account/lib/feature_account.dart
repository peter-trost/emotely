/// The account feature: the account screen (consent, the legal links,
/// deletion) and the explicit consent the app asks for before the first
/// session (ADR 0014) — its bloc, its screen and its wording.
///
/// The app registers it with `registerAccount` and implements
/// `AccountNavigator`, what this feature asks of the outside: to be signed
/// out, and to be shown the consent screen on its own route. The consent
/// bloc, screen and outcome are exported because the app owns that route
/// and the journal gates every session on its answer.
library;

export 'src/account/view/account_page.dart';
export 'src/consent/bloc/consent_bloc.dart';
export 'src/consent/consent_outcome.dart';
export 'src/consent/consent_text.dart';
export 'src/consent/view/consent_page.dart';
export 'src/navigator.dart';
export 'src/register.dart';
