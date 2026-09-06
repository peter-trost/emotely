/// Build-time configuration, all from `--dart-define`s so nothing
/// environment-specific is committed. This is the only place they are read.
library;

/// Where the agent runs (`--dart-define=EMOTELY_AGENT_URL=…`).
const agentUrl = String.fromEnvironment(
  'EMOTELY_AGENT_URL',
  defaultValue: 'https://emotely-agent.vercel.app/api/advance-session',
);

/// The PostHog project token (`--dart-define=POSTHOG_KEY=phc_…`). Empty
/// means analytics off: the SDK skips setup and captures go nowhere.
const posthogKey = String.fromEnvironment('POSTHOG_KEY');

/// EU cloud, like the agent (ADR 0004).
const posthogHost = 'https://eu.i.posthog.com';

/// Where the force-update screen sends the user
/// (`--dart-define=EMOTELY_STORE_URL=…`). Until the store listings exist
/// (#9) it points at the releases page.
const storeUrl = String.fromEnvironment(
  'EMOTELY_STORE_URL',
  defaultValue: 'https://github.com/peter-trost/emotely/releases',
);
