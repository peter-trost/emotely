-- Explicit consent to send journal content to a model provider, recorded
-- server-side (#97).
--
-- Journal entries can carry health, emotions and relationships, which makes
-- them special-category data under Art. 9 GDPR, and their transcripts leave
-- the device for a model provider through the Vercel AI Gateway. The lawful
-- basis for that is the user's explicit consent, Art. 9 (2) (a) GDPR — there
-- is no contract exception in Art. 9, so consent is the only route — and a
-- controller must be able to demonstrate it was given (Art. 7 (1)). A flag on
-- the device cannot do that: it does not survive a reinstall and proves
-- nothing. So the record lives here, next to the data it is about.
--
-- **The record is append-only.** Every grant and every withdrawal is its own
-- immutable row, and "consent stands" is derived from the latest one. The
-- obvious cheaper design — one row per user per version, with the withdrawal
-- clearing a column — is wrong, and was wrong in this file before: giving
-- consent again after a withdrawal erased the withdrawal, leaving a record
-- that claimed unbroken consent since the original date and so covered
-- whatever had been written during the window when there was none. What the
-- controller has to be able to show is what was true *when*, so nothing here
-- is ever updated or deleted.
--
-- Three things are recorded and nothing else: who, when, and which wording
-- they were shown. The wording itself is not copied per user — it is one
-- text, published at getemotely.com/app-privacy and in this repository's
-- history, and `version` names it. A changed wording is a new version, which
-- no existing event answers, so the app asks again.

create table public.consent_events (
  -- Identity rather than a uuid, because what this table needs from a key is
  -- an *order*. `recorded_at` cannot provide one: `now()` is transaction
  -- time, so a grant and a withdrawal in the same transaction share a
  -- timestamp and "the latest event" would be decided by a random uuid.
  -- `generated always` also means the user could not supply it even if they
  -- could insert, which they cannot.
  seq bigint primary key generated always as identity,
  user_id uuid not null references auth.users (id) on delete cascade,
  -- Which wording was answered. Dated rather than numbered, so what the user
  -- saw can be found in the repository at that date. The format is pinned so
  -- an invented string cannot be planted for a wording nobody has written
  -- yet, which would walk past the next re-consent silently.
  -- Shaped like a date, because a version *is* the date a wording was
  -- published. The stronger rule — not a date in the future, so an event
  -- cannot be planted for a wording nobody has written yet and walk past the
  -- next re-consent silently — lives in the two functions below, because a
  -- check constraint cannot call `now()`.
  version text not null check (version ~ '^\d{4}-\d{2}-\d{2}$'),
  action text not null check (action in ('granted', 'withdrawn')),
  recorded_at timestamptz not null default now()
);
comment on table public.consent_events is
  'Append-only history of explicit consent (Art. 9 (2) (a) GDPR) per user and notice version.';
comment on column public.consent_events.version is
  'Names the notice wording; the text lives on the site, never per user.';
comment on column public.consent_events.action is
  'granted, or withdrawn (Art. 7 (3)). The latest one is the current state.';

-- The only query the app makes: the latest event per user and version.
create index consent_events_user_version_idx
  on public.consent_events (user_id, version, seq desc);

-- Authorization ---------------------------------------------------------------

alter table public.consent_events enable row level security;

-- Privileges are granted explicitly, never inherited from defaults. The user
-- gets **no write privilege at all**: the three functions below are the only
-- way in, because this table is the controller's evidence and a user who can
-- insert into it can forge it — backdate a grant, choose the primary key, or
-- plant an event for a future wording they were never shown. Reads stay
-- direct and RLS-scoped so the user can always see their own history.
revoke all on public.consent_events from anon, authenticated;
grant select on public.consent_events to authenticated;

create policy "users read their own consent history" on public.consent_events
  for select to authenticated
  using ((select auth.uid()) = user_id);

-- A version the app could actually have shown: shaped like a date (the
-- column enforces that too) and not in the future. Planting an event for a
-- wording nobody has published yet would silently satisfy the next
-- re-consent, so the write path refuses one. Raised as a check violation
-- (23514), the same class the column's own constraint raises.
create function public.assert_publishable_version(version text)
returns void
language plpgsql
stable
set search_path = ''
as $$
begin
  if version !~ '^\d{4}-\d{2}-\d{2}$'
     or version::date > (now() at time zone 'utc')::date then
    raise check_violation using
      message = 'not a notice version this app could have shown';
  end if;
end;
$$;
comment on function public.assert_publishable_version(text) is
  'Refuses a malformed or future-dated notice version on the write path.';

-- Giving consent.
--
-- security definer, unlike the journal's functions: those run as the caller
-- because RLS should decide which row they may touch, whereas here the point
-- is that the caller may touch *none* of them directly. The body is what
-- pins the row to the caller — `auth.uid()` is read once, inside, and a
-- caller without a JWT is refused rather than writing a row owned by nobody.
-- `search_path = ''` and fully-qualified names keep a definer function from
-- being steered by a caller's search path.
--
-- Idempotent in the sense that matters: consenting when consent already
-- stands appends nothing, so a double tap or a retry after a reply that never
-- arrived writes one event. It does **not** mean "make the state true by any
-- means" — a withdrawal is never rewritten, only followed by a new grant.
create function public.record_consent(version text)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  caller uuid := (select auth.uid());
begin
  if caller is null then
    raise insufficient_privilege using message = 'no authenticated caller';
  end if;
  perform public.assert_publishable_version(record_consent.version);
  if public.consent_stands(record_consent.version) then
    return;
  end if;
  insert into public.consent_events (user_id, version, action)
    values (caller, record_consent.version, 'granted');
end;
$$;
comment on function public.record_consent(text) is
  'Appends the caller''s explicit consent to a notice version; idempotent.';

-- Taking it back has to be as easy as giving it (Art. 7 (3)), so it is one
-- call with no precondition: withdrawing something never consented to leaves
-- the same end state and is not an error the screen has to explain.
create function public.withdraw_consent(version text)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  caller uuid := (select auth.uid());
begin
  if caller is null then
    raise insufficient_privilege using message = 'no authenticated caller';
  end if;
  -- Nothing to take back: either never given, or already withdrawn. Both
  -- are the end state the caller asked for, so this appends nothing rather
  -- than recording a withdrawal of a consent that never existed.
  if not public.consent_stands(withdraw_consent.version) then
    return;
  end if;
  insert into public.consent_events (user_id, version, action)
    values (caller, withdraw_consent.version, 'withdrawn');
end;
$$;
comment on function public.withdraw_consent(text) is
  'Appends the caller''s withdrawal of a notice version (Art. 7 (3)); idempotent.';

-- Whether consent to `version` stands for the caller right now: the latest
-- event wins, and no event at all means no. security invoker, so RLS scopes
-- it to the caller's own rows and it can be called by anyone signed in.
create function public.consent_stands(version text)
returns boolean
language sql
security invoker
stable
set search_path = ''
as $$
  select coalesce(
    (select action = 'granted'
       from public.consent_events
      where user_id = (select auth.uid())
        and consent_events.version = consent_stands.version
      order by seq desc
      limit 1),
    false
  );
$$;
comment on function public.consent_stands(text) is
  'Whether the caller''s consent to a notice version stands (latest event wins).';

-- `assert_publishable_version` is an internal detail of the write path and
-- is not granted to anyone: a definer function calls it as its owner.
revoke execute on function public.assert_publishable_version(text)
  from public, anon, authenticated;
revoke execute on function public.record_consent(text) from public, anon;
revoke execute on function public.withdraw_consent(text) from public, anon;
revoke execute on function public.consent_stands(text) from public, anon;
grant execute on function public.record_consent(text) to authenticated;
grant execute on function public.withdraw_consent(text) to authenticated;
grant execute on function public.consent_stands(text) to authenticated;
