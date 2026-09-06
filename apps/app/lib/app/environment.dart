/// Build-time configuration, all from `--dart-define`s so nothing
/// environment-specific is committed. This is the only place they are read.
library;

/// Where the agent runs (`--dart-define=EMOTELY_AGENT_URL=…`).
const agentUrl = String.fromEnvironment(
  'EMOTELY_AGENT_URL',
  defaultValue: 'https://emotely-agent.vercel.app/api/advance-session',
);
