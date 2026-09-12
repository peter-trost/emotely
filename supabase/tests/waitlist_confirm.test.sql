-- Double opt-in for the waitlist (ADR 0011): a sign-up hands a confirmation
-- mail to Resend through pg_net, the mail carries a link with the row's
-- token, and only the token confirms the address. Driven as PostgREST would
-- drive it: inserts as `anon`, the confirm RPC as `anon`, everything else
-- refused. The Resend key comes from Vault; here a throwaway one is created
-- inside the transaction and rolled back with it.
begin;
select plan(14);

create function pg_temp.anon() returns void language plpgsql as $$
begin
  perform set_config('role', 'anon', true);
  perform set_config('request.jwt.claims', '', true);
end $$;
create function pg_temp.logout() returns void language plpgsql as $$
begin
  perform set_config('role', 'postgres', true);
  perform set_config('request.jwt.claims', '', true);
end $$;
create function pg_temp.from_ip(ip text) returns void language plpgsql as $$
begin
  perform set_config(
    'request.headers',
    json_build_object('x-forwarded-for', ip)::text,
    true
  );
end $$;
-- The body pg_net queues, as JSON, for the one request in the queue.
create function pg_temp.queued_mail() returns jsonb language sql as $$
  select convert_from(body, 'utf8')::jsonb from net.http_request_queue
$$;
-- Reads a row's token as postgres and parks it where anon can pick it up,
-- standing in for the mailbox.
create function pg_temp.hand_over(address text) returns void language plpgsql as $$
begin
  perform set_config(
    'test.token',
    (select confirm_token::text from public.waitlist where email = address),
    true
  );
end $$;

select vault.create_secret('re_test_key', 'resend_api_key', 'test only');

-- A sign-up sends the confirmation mail ---------------------------------------

select pg_temp.anon();
select pg_temp.from_ip('203.0.113.9');
insert into public.waitlist (email, source) values ('alice@example.com', 'landing');
select pg_temp.logout();

select results_eq(
  $$select method::text, url, headers->>'Authorization', headers->>'Content-Type'
    from net.http_request_queue$$,
  $$values ('POST', 'https://api.resend.com/emails', 'Bearer re_test_key', 'application/json')$$,
  'the confirmation mail is handed to Resend with the key from Vault'
);
select is(
  pg_temp.queued_mail() - 'text' - 'html',
  jsonb_build_object(
    'from', 'emotely <hello@getemotely.com>',
    'reply_to', 'hello@getemotely.com',
    'to', jsonb_build_array('alice@example.com'),
    'subject', 'Confirm your spot on the emotely waitlist',
    'tags', jsonb_build_array(jsonb_build_object('name', 'kind', 'value', 'waitlist_confirm'))
  ),
  'the mail goes to the address that signed up, from hello@'
);
select ok(
  pg_temp.queued_mail() ->> 'text' like
    '%https://getemotely.com/confirm?t='
    || (select confirm_token from public.waitlist where email = 'alice@example.com')
    || '%',
  'the mail links to /confirm with the token of that row'
);
select ok(
  pg_temp.queued_mail() ->> 'html' like
    '%https://getemotely.com/confirm?t='
    || (select confirm_token from public.waitlist where email = 'alice@example.com')
    || '%',
  'the HTML version carries the same link'
);

-- Only the link confirms -----------------------------------------------------------

select pg_temp.anon();
select throws_ok(
  $$insert into public.waitlist (email, confirm_token)
    values ('mallory@example.com', '00000000-0000-0000-0000-000000000001')$$,
  '42501',
  null,
  'the caller cannot choose a token'
);
select throws_ok(
  $$select confirm_token from public.waitlist$$,
  '42501',
  null,
  'nor read one'
);
select is(
  public.confirm_waitlist('00000000-0000-0000-0000-000000000001'),
  false,
  'a token that matches no row confirms nothing'
);
-- The token travels to anon the way it does in life: out of band.
select pg_temp.logout();
select pg_temp.hand_over('alice@example.com');
select pg_temp.anon();
select is(
  public.confirm_waitlist(current_setting('test.token')::uuid),
  true,
  'the token from the mail confirms the address'
);
select is(
  public.confirm_waitlist(current_setting('test.token')::uuid),
  false,
  'a second click changes nothing and says so'
);
select pg_temp.logout();
select results_eq(
  $$select confirmed_at is not null from public.waitlist where email = 'alice@example.com'$$,
  $$values (true)$$,
  'the row is confirmed'
);

-- Unconfirmed addresses do not linger ---------------------------------------------

select pg_temp.anon();
select pg_temp.from_ip('198.51.100.1');
insert into public.waitlist (email) values ('bob@example.com');
insert into public.waitlist (email) values ('carol@example.com');
select pg_temp.logout();
select pg_temp.hand_over('carol@example.com');
select pg_temp.anon();
select public.confirm_waitlist(current_setting('test.token')::uuid);
select pg_temp.logout();
update public.waitlist set created_at = now() - interval '8 days'
  where email in ('bob@example.com', 'carol@example.com');
select pg_temp.anon();
select pg_temp.from_ip('198.51.100.2');
insert into public.waitlist (email) values ('dave@example.com');
select pg_temp.logout();
select results_eq(
  $$select count(*) from public.waitlist where email = 'bob@example.com'$$,
  $$values (0::bigint)$$,
  'an address that never confirmed is deleted a week later'
);
select results_eq(
  $$select count(*) from public.waitlist where email = 'carol@example.com'$$,
  $$values (1::bigint)$$,
  'a confirmed one stays'
);

-- Without a key (every local stack) the sign-up still works -----------------------

delete from vault.secrets where name = 'resend_api_key';
delete from net.http_request_queue;
select pg_temp.anon();
select pg_temp.from_ip('198.51.100.3');
select lives_ok(
  $$insert into public.waitlist (email) values ('erin@example.com')$$,
  'no key in Vault does not refuse the sign-up'
);
select pg_temp.logout();
select results_eq(
  $$select count(*) from net.http_request_queue$$,
  $$values (0::bigint)$$,
  'it just sends nothing (and warns in the log)'
);

select * from finish();
rollback;
