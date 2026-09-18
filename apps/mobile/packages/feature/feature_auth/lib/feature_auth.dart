/// The auth feature: who is signed in, and the two-step email-code sign-in
/// that gets there (a password instead for the stores' review accounts).
/// The app registers it with `registerAuth`, holds the one `AuthBloc`
/// above every screen and shows `SignInPage` while nobody is signed in.
library;

export 'src/bloc/auth_bloc.dart';
export 'src/register.dart';
export 'src/review_accounts.dart';
export 'src/view/sign_in_page.dart';
