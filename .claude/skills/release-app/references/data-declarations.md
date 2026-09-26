# Store data declarations

App Store Connect (App Privacy) and Play Console (Data safety) each ask which
data types the app collects, and a reviewer compares the answers with the
notice at `https://getemotely.com/app-privacy`. Both consoles are human-facing
forms; an agent edits them in Chrome.

## What is declared

As corrected on 2026-09-15: seven types, everything **Linked** to the user,
and **no tracking** — contact info (email), user content (the journal),
identifiers (user id and the analytics library's device id), usage data,
diagnostics.

Google sign-in (#51) adds a **name**: Google's ID token carries the account's
name and a profile picture link, and Supabase stores both with the sign-in
record. So both consoles declare it:

- ASC **Contact Info → Name**: Linked, App Functionality, no tracking.
- Play **Data safety → Personal info → Name**: collected, not shared,
  optional, account management.

The picture link is a URL on Google's servers, not a photo the app holds, and
needs no category of its own.
