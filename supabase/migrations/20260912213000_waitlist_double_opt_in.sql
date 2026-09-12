-- Double opt-in for the waitlist (ADR 0011). A sign-up alone proves nothing;
-- German practice (§ 7 UWG, the burden of proving consent is ours) wants the
-- address to answer a mail before it is ever mailed again. So every row gets
-- a token, an after-insert trigger hands a confirmation mail to Resend
-- through pg_net, and the only way to set confirmed_at is the RPC below,
-- called with that token from the link in the mail.
--
-- The Resend key lives in Vault under the name resend_api_key; it is read at
-- send time by a security-definer function, never by a migration. Without
-- it (every local stack) the insert still succeeds and a warning says why no
-- mail went out.

create extension if not exists pg_net with schema extensions;

alter table public.waitlist
  add column confirm_token uuid not null default gen_random_uuid();
comment on column public.waitlist.confirm_token is
  'Proof of the mailbox: the link in the confirmation mail carries it. Never granted to anon.';
create unique index waitlist_confirm_token_key on public.waitlist (confirm_token);

-- The mail ----------------------------------------------------------------------
--
-- After insert, so the row and its token are final; pg_net only sends once
-- the transaction commits, so a refused insert sends nothing. security
-- definer for the Vault read; the body touches nothing but the new row.
create function public.waitlist_confirmation_mail()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  site constant text := 'https://getemotely.com';
  key text;
  link text;
begin
  select decrypted_secret into key
    from vault.decrypted_secrets
    where name = 'resend_api_key';
  if key is null then
    raise warning 'waitlist: no resend_api_key in vault, no confirmation mail for %', new.email;
    return null;
  end if;

  link := site || '/confirm?t=' || new.confirm_token;
  perform net.http_post(
    url := 'https://api.resend.com/emails',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer ' || key
    ),
    body := jsonb_build_object(
      'from', 'emotely <hello@getemotely.com>',
      'reply_to', 'hello@getemotely.com',
      'to', jsonb_build_array(new.email),
      'subject', 'Confirm your spot on the emotely waitlist',
      'text',
        'Hi,' || E'\n\n'
        || 'Someone, hopefully you, asked for early access to emotely with '
        || 'this address. Confirm it and your spot is held:' || E'\n\n'
        || link || E'\n\n'
        || 'If that was not you, ignore this mail: nothing happens, and the '
        || 'address is deleted after a week.' || E'\n\n'
        || 'Peter' || E'\n' || 'emotely · ' || site,
      'html',
        '<p>Hi,</p>'
        || '<p>Someone, hopefully you, asked for early access to emotely with '
        || 'this address. Confirm it and your spot is held:</p>'
        || '<p><a href="' || link || '">Confirm my address</a></p>'
        || '<p>If that was not you, ignore this mail: nothing happens, and the '
        || 'address is deleted after a week.</p>'
        || '<p>Peter<br>emotely · <a href="' || site || '">' || site || '</a></p>',
      'tags', jsonb_build_array(
        jsonb_build_object('name', 'kind', 'value', 'waitlist_confirm')
      )
    ),
    timeout_milliseconds := 5000
  );
  return null;
end;
$$;
comment on function public.waitlist_confirmation_mail() is
  'Hands the double-opt-in mail for a new waitlist row to Resend via pg_net.';

revoke execute on function public.waitlist_confirmation_mail()
  from public, anon, authenticated;

create trigger waitlist_confirmation_mail
  after insert on public.waitlist
  for each row execute function public.waitlist_confirmation_mail();

-- The confirmation ---------------------------------------------------------------
--
-- Callable by anon through PostgREST (`/rest/v1/rpc/confirm_waitlist`). The
-- token is 122 random bits, so telling true from false leaks nothing that
-- could be enumerated, and the page can say "confirmed" or "not this link".
-- security definer: anon has no update on the table, and must not get one.
create function public.confirm_waitlist(token uuid)
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
begin
  update public.waitlist
    set confirmed_at = now()
    where confirm_token = token and confirmed_at is null;
  return found;
end;
$$;
comment on function public.confirm_waitlist(uuid) is
  'Sets confirmed_at for the row whose mail link carried the token; true once.';

revoke execute on function public.confirm_waitlist(uuid) from public, authenticated;
grant execute on function public.confirm_waitlist(uuid) to anon;

-- The guard, one step longer ----------------------------------------------------------
--
-- Same body as in 20260912080000_waitlist.sql plus the last statement: an
-- address that never answered its mail is deleted after a week, so the list
-- holds only mailboxes that exist and consented, and a stranger's address
-- typed in by mistake does not stay on file.
create or replace function public.waitlist_guard()
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
  -- needed: an IP older than the windows above serves no purpose, and an
  -- address that never confirmed is not consent.
  update public.waitlist w set ip = null
    where w.ip is not null and w.created_at < now() - interval '1 day';
  delete from public.waitlist w
    where w.confirmed_at is null and w.created_at < now() - interval '7 days';

  return new;
end;
$$;
comment on function public.waitlist_guard() is
  'Normalises, de-duplicates silently, rate-limits waitlist inserts, erases day-old IPs and drops week-old unconfirmed rows.';
