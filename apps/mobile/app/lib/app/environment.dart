/// Build-time configuration, all from `--dart-define`s so nothing
/// environment-specific is committed. This is the only place they are read.
library;

/// Where the agent runs (`--dart-define=EMOTELY_AGENT_URL=…`).
const agentUrl = String.fromEnvironment(
  'EMOTELY_AGENT_URL',
  defaultValue: 'https://api.getemotely.com/api/advance-session',
);

/// The PostHog project token (`--dart-define=POSTHOG_KEY=phc_…`). Empty
/// means analytics off: the SDK skips setup and captures go nowhere.
const posthogKey = String.fromEnvironment('POSTHOG_KEY');

/// EU cloud, like the agent (ADR 0004).
const posthogHost = 'https://eu.i.posthog.com';

/// The startup config (`--dart-define=EMOTELY_CONFIG_URL=…`), read once
/// before anything else: it says whether this build may still run and where
/// to send the user if not (#49).
///
/// The store link used to be a `--dart-define` here. It moved to the server,
/// because the only people who ever see it are the ones who cannot install a
/// build carrying a corrected one.
const configUrl = String.fromEnvironment(
  'EMOTELY_CONFIG_URL',
  defaultValue: 'https://api.getemotely.com/api/config',
);

/// The Supabase project (`--dart-define=EMOTELY_SUPABASE_URL=…`). Public by
/// design; row-level security is what protects the data (ADR 0010).
const supabaseUrl = String.fromEnvironment(
  'EMOTELY_SUPABASE_URL',
  defaultValue: 'https://khfkszlujgkfjgnawdlf.supabase.co',
);

/// The project's publishable key
/// (`--dart-define=EMOTELY_SUPABASE_PUBLISHABLE_KEY=sb_publishable_…`).
/// Public like the URL: it only ever acts under the signed-in user's rights.
const supabasePublishableKey = String.fromEnvironment(
  'EMOTELY_SUPABASE_PUBLISHABLE_KEY',
  defaultValue: 'sb_publishable_di6BB76PPuuoDklt7jtI0w_KlwO_8JF',
);
