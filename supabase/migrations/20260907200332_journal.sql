-- The journal data layer (#7): one open session per user, one immutable
-- entry per completed session, everything owned by the user who wrote it.
-- The app writes here directly with the user's JWT; the agent never does
-- (ADR 0010). Row-level security is therefore the whole authorization model.

create extension if not exists moddatetime with schema extensions;

-- A journaling session: the signed transcript the agent handed back last,
-- so a closed or crashed app can resume where it left off. The signature is
-- what keeps a user's own edits to this row from reaching the model.
create table public.sessions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid()
    references auth.users (id) on delete cascade,
  question_set_id text not null,
  transcript jsonb not null,
  signature text not null,
  status text not null default 'in_progress'
    check (status in ('in_progress', 'completed')),
  app_version text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
comment on table public.sessions is
  'One journaling conversation; the transcript is server-signed (ADR 0008).';

create index sessions_user_updated_idx
  on public.sessions (user_id, updated_at desc);
-- Resume is unambiguous: a user never has two sessions in progress.
create unique index sessions_one_in_progress_idx
  on public.sessions (user_id) where status = 'in_progress';

create trigger sessions_set_updated_at
  before update on public.sessions
  for each row execute function extensions.moddatetime(updated_at);

-- The durable artifact of a completed session: the summary, the recorded
-- answers keyed by question id, and the questions as they were asked so the
-- entry renders without the session.
create table public.entries (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid()
    references auth.users (id) on delete cascade,
  session_id uuid unique
    references public.sessions (id) on delete set null,
  summary text not null,
  answers jsonb not null,
  questions jsonb not null,
  created_at timestamptz not null default now()
);
comment on table public.entries is
  'A finished journal entry. Written once; deleted with the account.';

create index entries_user_created_idx
  on public.entries (user_id, created_at desc);

-- Authorization ---------------------------------------------------------------

alter table public.sessions enable row level security;
alter table public.entries enable row level security;

-- Privileges are granted explicitly, never inherited from defaults: the anon
-- key alone gets nothing, so only a verified user JWT reaches the tables, and
-- RLS scopes it to that user's rows. Entries have no update privilege: they
-- are immutable, and the only way to change one is to delete it.
revoke all on public.sessions, public.entries from anon, authenticated;
grant select, insert, update, delete on public.sessions to authenticated;
grant select, insert, delete on public.entries to authenticated;

create policy "users own their sessions" on public.sessions
  for all to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

create policy "users own their entries" on public.entries
  for all to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

-- Account deletion, in-app (App Store guideline 5.1.1). Deleting the auth
-- user cascades through sessions and entries. security definer because the
-- authenticated role cannot touch auth.users; the body only ever deletes the
-- caller, and a caller without a JWT deletes nothing.
create function public.delete_account()
returns void
language sql
security definer
set search_path = ''
as $$
  delete from auth.users where id = (select auth.uid());
$$;
comment on function public.delete_account() is
  'Deletes the calling user and, by cascade, all their journal data.';

revoke execute on function public.delete_account() from public, anon;
grant execute on function public.delete_account() to authenticated;
