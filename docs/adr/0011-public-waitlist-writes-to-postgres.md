# The public waitlist writes straight to Postgres

The web site (`apps/web`) is static and has one interactive thing on it: a form
that adds an email address to the early-access waitlist. That form talks to the
Supabase Data API directly, with the publishable key and no user, and inserts
into `public.waitlist`. There is no server in between.

The alternative we rejected was a serverless route in front of the table. It
would let us verify a captcha with a secret and keep the table private, but it
adds a runtime to a site that otherwise has none, needs a secret in Vercel, and
still leaves the table reachable with the publishable key unless the table is
locked down anyway. Locking the table down is the actual work, so we do only that.

## What the world may do

Exactly one thing: insert an `email` and an optional `source` tag as `anon`.
Everything else is refused before a row is touched:

- **No reads.** `anon` has no select privilege, so the list cannot be scraped,
  and `returning` fails too — a successful insert answers with an empty 201.
- **No probing.** A repeat sign-up is dropped silently by the trigger and looks
  identical to a first one; there is no 409 to test an address against.
- **No other columns.** Privileges are granted per column: `ip`, `created_at`
  and `confirmed_at` are the server's.
- **No signed-in path.** `authenticated` gets nothing; a user with an account
  has the app.

## Rate limits live in the database

Supabase has no per-table rate limit, and its own guidance for the Data API is
to read the caller IP from `request.headers` (`x-forwarded-for`) in SQL and
refuse from there. The insert trigger does that: five sign-ups per IP per hour,
five hundred per day overall, each refused with SQLSTATE `PT429`, which
PostgREST turns into a plain HTTP 429 for the form. The daily cap is the cost
backstop in the spirit of [ADR 0008](0008-public-endpoint-abuse-controls.md): a
distributed flood costs at most a day of rows, never a bill.

The trigger is `security definer` because the counts it needs are on a table
`anon` may not read; its body reads nothing but those counts and it cannot be
called directly.

## What follows from it

- **Consent is double opt-in.** The form says what the address is for, and
  the row proves nothing until the mailbox answers: every insert gets a
  `confirm_token`, an after-insert trigger hands a confirmation mail to
  Resend through `pg_net` (key from Vault, `resend_api_key`), and the link
  in that mail calls `confirm_waitlist(token)`, the only path to
  `confirmed_at`. A row that never confirms is deleted after a week by the
  guard. GDPR does not spell this out; German practice (§ 7 UWG, the burden
  of proof for consent is ours) does, and it is the only way the list may
  ever be mailed.
- **The mail is sent from the database, not from a function or the site.**
  `pg_net` queues the HTTP call inside the transaction and fires it only on
  commit, so a refused insert sends nothing and nothing outside Postgres
  ever holds the Resend key. The cost is a mail template in SQL; the gain
  is one fewer runtime to deploy and secure.
- **The IP is evidence for a day, not a record.** It exists for the per-IP
  window; the guard erases it from any row older than a day on the next
  insert, so the list never accumulates addresses-to-people links.
- **The form is the only client.** A change to the table's contract is a change
  to `apps/web`, in the same PR, like the app and the agent share
  `packages/contract`.
- **pgTAP is the gate.** `supabase/tests/waitlist.test.sql` drives the table as
  PostgREST would, IP header included, and is mutation-checked against the
  trigger, RLS and the grants.
