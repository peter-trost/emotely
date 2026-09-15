-- Explicit consent to send journal content to a model provider, recorded
-- server-side (#96).
--
-- Journal entries can carry health, emotions and relationships, which makes
-- them special-category data under Art. 9 GDPR, and their transcripts leave
-- the device for a model provider through the Vercel AI Gateway. The lawful
-- basis for that is the user's explicit consent, Art. 9 (2) (a) GDPR, and a
-- controller must be able to demonstrate it was given (Art. 7 (1)). A flag on
-- the device cannot do that: it does not survive a reinstall and proves
-- nothing. So the record lives here, next to the data it is about.
--
-- Three things are recorded and nothing else: who, when, and which wording
-- they were shown. The wording itself is not copied per user — it is one
-- text, published at getemotely.com/app-privacy and in this repository's
-- history, and `version` names it. A changed wording is a new version, which
-- no existing row answers, so the app asks again.

create table public.consents (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid()
    references auth.users (id) on delete cascade,
  -- Which wording was agreed to. Dated rather than numbered, so what the user
  -- saw can be found in the repository at that date.
  version text not null,
  granted_at timestamptz not null default now(),
  -- Set when the user takes their consent back (Art. 7 (3)); the row stays,
  -- because "consented on the 15th, withdrew on the 20th" is the record, and
  -- deleting it would erase the half that was lawful at the time.
  withdrawn_at timestamptz
);
comment on table public.consents is
  'Record of explicit consent (Art. 9 (2) (a) GDPR) per user and notice version.';
comment on column public.consents.version is
  'Names the notice wording; the text lives on the site, never per user.';
comment on column public.consents.withdrawn_at is
  'When consent was withdrawn (Art. 7 (3)); null while it stands.';

-- One decision per user per version: a double tap, or a retry after a reply
-- that never arrived, updates that decision rather than recording a second.
create unique index consents_user_version_idx
  on public.consents (user_id, version);

-- Authorization ---------------------------------------------------------------

alter table public.consents enable row level security;

-- Privileges are granted explicitly, never inherited from defaults. The
-- update grant is column-scoped on purpose: this row is the controller's
-- evidence, so the user may take consent back (and give it again) but may
-- not rewrite when they consented or relabel which notice they answered.
-- Insert is the app's own path for a first consent; both writes normally go
-- through the two functions below, which own the timestamps.
revoke all on public.consents from anon, authenticated;
grant select, insert on public.consents to authenticated;
grant update (withdrawn_at) on public.consents to authenticated;

create policy "users own their consents" on public.consents
  for all to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

-- Giving consent. security invoker, so RLS still decides whose row this is;
-- the function exists to own `granted_at` and to make the write idempotent,
-- not to gain rights. Consenting again after a withdrawal is the same
-- decision being revisited, so it clears `withdrawn_at` rather than adding a
-- row: the record still shows a consent that stands, and when it was first
-- given.
create function public.record_consent(version text)
returns void
language sql
security invoker
set search_path = ''
as $$
  insert into public.consents (version) values (record_consent.version)
  on conflict (user_id, version) do update set withdrawn_at = null;
$$;
comment on function public.record_consent(text) is
  'Records the caller''s explicit consent to a notice version; idempotent.';

revoke execute on function public.record_consent(text) from public, anon;
grant execute on function public.record_consent(text) to authenticated;

-- Taking it back has to be as easy as giving it (Art. 7 (3)), so it is one
-- call with no precondition: withdrawing something never consented to leaves
-- the same end state and is not an error the screen has to explain.
create function public.withdraw_consent(version text)
returns void
language sql
security invoker
set search_path = ''
as $$
  update public.consents set withdrawn_at = now()
  where version = withdraw_consent.version
    and user_id = (select auth.uid())
    and withdrawn_at is null;
$$;
comment on function public.withdraw_consent(text) is
  'Withdraws the caller''s consent to a notice version (Art. 7 (3)); idempotent.';

revoke execute on function public.withdraw_consent(text) from public, anon;
grant execute on function public.withdraw_consent(text) to authenticated;
