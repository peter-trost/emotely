/// The app's side of the agent's HTTP API: one call per session round
/// (`POST /api/advance-session`) and the startup config read once at launch
/// (`GET /api/config`), with the wire shapes both answer with. Every request
/// is pinned against the agent's JSON Schema by the app's contract test.
library;

export 'src/advance_response.dart';
export 'src/agent_client.dart';
export 'src/config_client.dart';
export 'src/register.dart';
export 'src/startup_config.dart';
