-- The early-access waitlist behind the public web site. The site talks to
-- this table directly with the publishable key and no user, so the table is
-- built for a hostile caller: exactly one verb (insert), exactly two columns
-- (email, source), nothing readable, and a trigger that owns every other
-- decision — normalisation, silent de-duplication and rate limits.
--
-- Rate limiting follows Supabase's own recipe for the Data API: the caller
-- IP arrives in request.headers (x-forwarded-for) and a PTnnn SQLSTATE maps
-- straight to an HTTP status, so the site sees a plain 429.

create table public.waitlist (
  id uuid primary key default gen_random_uuid(),
  -- Shape only: something@something.something, no whitespace, within the
  -- 254 characters SMTP can deliver to. Real validation is the mail itself.
  email text not null
    check (
      email = lower(btrim(email))
      and length(email) <= 254
      and email ~ '^[^\s@]+@[^\s@]+\.[^\s@]+$'
    ),
  -- Where the address came from, set by the site from the link the visitor
  -- used: `utm_source/utm_medium/utm_campaign` (lowercased, [a-z0-9._-]),
  -- else the referring host, else `landing`. The link format is the
  -- campaign-links skill's business; this column just keeps the tag.
  source text check (source is null or length(source) <= 64),
  -- The caller's IP, kept only while the per-IP window can still need it:
  -- the guard erases it from rows older than a day.
  ip inet,
  created_at timestamptz not null default now(),
  -- Set by the double-opt-in mail once it exists; null means unconfirmed.
  confirmed_at timestamptz
);
comment on table public.waitlist is
  'Early-access sign-ups from the web site; append-only for the world.';

create unique index waitlist_email_key on public.waitlist (email);
create index waitlist_ip_created_at_idx on public.waitlist (ip, created_at desc);
create index waitlist_created_at_idx on public.waitlist (created_at desc);

-- Authorization ---------------------------------------------------------------

alter table public.waitlist enable row level security;

-- anon may insert two columns and nothing else; authenticated gets nothing,
-- a signed-in user already has the app. No select for anyone through the
-- API: the list is not readable, and `returning` fails for lack of select.
revoke all on public.waitlist from anon, authenticated;
grant insert (email, source) on public.waitlist to anon;

create policy "anyone may join the waitlist" on public.waitlist
  for insert to anon
  with check (true);

-- The guard ---------------------------------------------------------------------
--
-- security definer because the guard has to count rows anon may not read;
-- the body only ever reads counts for the caller's own IP and the day.
-- Returning null drops the row silently, so a repeat sign-up is
-- indistinguishable from a first one and the list cannot be probed for
-- membership.
create function public.waitlist_guard()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  per_ip_per_hour constant int := 5;
  per_day constant int := 500;
  recent int;
  today int;
begin
  new.email := lower(btrim(new.email));
  new.ip := nullif(
    btrim(split_part(
      coalesce(current_setting('request.headers', true)::json ->> 'x-forwarded-for', ''),
      ',', 1)),
    ''
  )::inet;

  if exists (select 1 from public.waitlist w where w.email = new.email) then
    return null;
  end if;

  select count(*) into recent from public.waitlist w
    where w.ip is not distinct from new.ip
      and w.created_at > now() - interval '1 hour';
  if recent >= per_ip_per_hour then
    raise sqlstate 'PT429' using
      message = 'too many sign-ups from this address, try again in an hour';
  end if;

  select count(*) into today from public.waitlist w
    where w.created_at > now() - interval '1 day';
  if today >= per_day then
    raise sqlstate 'PT429' using
      message = 'the waitlist is taking a breather, try again tomorrow';
  end if;

  -- Data minimisation, piggybacked on the write path so no scheduler is
  -- needed: an IP older than the windows above serves no purpose.
  update public.waitlist w set ip = null
    where w.ip is not null and w.created_at < now() - interval '1 day';

  return new;
end;
$$;
comment on function public.waitlist_guard() is
  'Normalises, de-duplicates silently, rate-limits waitlist inserts and erases day-old IPs.';

revoke execute on function public.waitlist_guard() from public, anon, authenticated;

create trigger waitlist_guard
  before insert on public.waitlist
  for each row execute function public.waitlist_guard();
