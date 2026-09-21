import 'package:feature_account/src/account/view/account_page.dart';
import 'package:feature_account/src/consent/bloc/consent_bloc.dart';
import 'package:feature_account/src/consent/view/consent_page.dart';
import 'package:feature_account/src/more/view/more_page.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

part 'routes.g.dart';

/// The account feature's own screens as routes (ADR 0016): the More tab
/// with the account screen under it, and the consent screen on its own at
/// the root, so that pushing it covers whatever tab bar the app shows.
/// The feature moves between its own screens itself; the app mounts the
/// trees and reaches the consent screen through the feature's navigator.

/// The More tab, with a consent bloc of its own for the rows that take
/// consent back and give it again; the journal asks the server again
/// before every session, so nothing has to be shared between the two tabs.
@TypedGoRoute<MoreRoute>(
  path: '/more',
  name: 'more',
  routes: [TypedGoRoute<AccountRoute>(path: 'account', name: 'account')],
)
@immutable
class const MoreRoute() extends GoRouteData with $MoreRoute {
  @override
  Widget build(BuildContext context, GoRouterState state) => BlocProvider(
    create: (_) => GetIt.I<ConsentBloc>()..add(const ConsentEvent.loaded()),
    child: const MorePage(),
  );
}

/// The account screen, under More.
@immutable
class const AccountRoute() extends GoRouteData with $AccountRoute {
  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const AccountPage();
}

/// The consent screen, pushed for its `ConsentOutcome`. The route owns the
/// bloc, which is the authority on the answer: `granted` only after the
/// server recorded it. The provider closes the bloc with the route.
@TypedGoRoute<ConsentRoute>(path: '/consent', name: 'consent')
@immutable
class const ConsentRoute() extends GoRouteData with $ConsentRoute {
  @override
  Widget build(BuildContext context, GoRouterState state) => BlocProvider(
    create: (_) => GetIt.I<ConsentBloc>()..add(const ConsentEvent.loaded()),
    child: const ConsentPage(),
  );
}
