/// The account feature: the account screen (consent, the legal links,
/// deletion) and the explicit consent the app asks for before the first
/// session (ADR 0014) — its bloc, its screen and its wording.
///
/// The app registers it with `registerAccount` and implements
/// `AccountNavigator`, the one thing this feature asks of the outside: to
/// be signed out. The consent bloc and screen are exported because the
/// journal gates every session on them; that seam moves behind the
/// journal's navigator when the journal becomes a package.
library;

export 'src/account/view/account_page.dart';
export 'src/consent/bloc/consent_bloc.dart';
export 'src/consent/consent_text.dart';
export 'src/consent/view/consent_page.dart';
export 'src/navigator.dart';
export 'src/register.dart';
