/// The journal as the app stores it: the session still in progress and every
/// filed entry, written and read straight from Supabase under the signed-in
/// user's own rights (ADR 0010). Nothing here goes through the agent, and
/// nothing here can reach another user's rows.
library;

export 'src/journal_models.dart';
export 'src/journal_repository.dart';
