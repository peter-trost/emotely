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

/// The Supabase project (`--dart-define=EMOTELY_SUPABASE_URL=…`). Public by
/// design; row-level security is what protects the data (ADR 0010).
const supabaseUrl = String.fromEnvironment(
  'EMOTELY_SUPABASE_URL',
  defaultValue: 'https://SUPABASE_PROJECT_REF.supabase.co',
);

/// The project's publishable key
/// (`--dart-define=EMOTELY_SUPABASE_PUBLISHABLE_KEY=sb_publishable_…`).
/// Public like the URL: it only ever acts under the signed-in user's rights.
const supabasePublishableKey = String.fromEnvironment(
  'EMOTELY_SUPABASE_PUBLISHABLE_KEY',
  defaultValue: 'sb_publishable_SUPABASE_PROJECT_KEY',
);
