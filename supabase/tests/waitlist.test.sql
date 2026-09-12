-- The waitlist is the one table the public web site writes to, with the
-- publishable key and no user. Everything here is driven the way PostgREST
-- would drive it: as `anon`, with the caller's IP in request.headers.
-- What the world may do is exactly one thing — add an address — and every
-- other verb, column and read is refused before it reaches a row.
begin;
select plan(27);

-- Impersonation helpers, as in rls.test.sql, plus the client IP the way
-- Supabase's gateway hands it to Postgres (x-forwarded-for).
create function pg_temp.anon() returns void language plpgsql as $$
begin
  perform set_config('role', 'anon', true);
  perform set_config('request.jwt.claims', '', true);
end $$;
create function pg_temp.authenticated() returns void language plpgsql as $$
begin
  perform set_config('role', 'authenticated', true);
  perform set_config(
    'request.jwt.claims',
    json_build_object('sub', '00000000-0000-0000-0000-00000000000a', 'role', 'authenticated')::text,
    true
  );
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

-- Structure -----------------------------------------------------------------

select has_table('public', 'waitlist', 'waitlist table exists');
select ok(
  (select relrowsecurity from pg_class where oid = 'public.waitlist'::regclass),
  'row-level security is on for waitlist'
);

-- Joining ---------------------------------------------------------------------

select pg_temp.anon();
select pg_temp.from_ip('203.0.113.9');

select lives_ok(
  $$insert into public.waitlist (email, source)
    values ('  Alice@Example.com ', 'landing')$$,
  'anyone can add an address with the publishable key'
);
select throws_ok(
  $$insert into public.waitlist (email) values ('bob@example.com') returning id$$,
  '42501',
  null,
  'nothing about the row comes back, not even its id'
);

select pg_temp.logout();
select results_eq(
  $$select email, source, host(ip), confirmed_at is null
    from public.waitlist where email like 'alice%'$$,
  $$values ('alice@example.com'::text, 'landing'::text, '203.0.113.9'::text, true)$$,
  'the address is stored lowercased and trimmed, with the caller IP, unconfirmed'
);

select pg_temp.anon();
select lives_ok(
  $$insert into public.waitlist (email) values ('ALICE@example.com')$$,
  'adding an address twice looks exactly like adding it once'
);
select pg_temp.logout();
select results_eq(
  $$select count(*) from public.waitlist where email = 'alice@example.com'$$,
  $$values (1::bigint)$$,
  'the duplicate is dropped, not stored'
);

-- Only an address goes in ---------------------------------------------------------

select pg_temp.anon();
select throws_ok(
  $$insert into public.waitlist (email) values ('not an address')$$,
  '23514',
  null,
  'a malformed address is refused'
);
select lives_ok(
  $$insert into public.waitlist (email) values ('a@b.co')$$,
  'the shortest address a two-letter domain allows is accepted'
);
select throws_ok(
  $$insert into public.waitlist (email) values (repeat('a', 250) || '@x.io')$$,
  '23514',
  null,
  'an oversized address is refused'
);
select throws_ok(
  $$insert into public.waitlist (email, source) values ('c@example.com', repeat('s', 65))$$,
  '23514',
  null,
  'an oversized source tag is refused'
);
select throws_ok(
  $$insert into public.waitlist (email, ip) values ('d@example.com', '10.0.0.1')$$,
  '42501',
  null,
  'the caller cannot claim an IP'
);
select throws_ok(
  $$insert into public.waitlist (email, confirmed_at) values ('e@example.com', now())$$,
  '42501',
  null,
  'the caller cannot confirm an address'
);
select throws_ok(
  $$insert into public.waitlist (email, created_at) values ('f@example.com', '2000-01-01')$$,
  '42501',
  null,
  'the caller cannot backdate a row'
);

-- Nothing comes out, nothing changes -------------------------------------------

select throws_ok('select * from public.waitlist', '42501', null, 'anon cannot read the list');
select throws_ok(
  $$update public.waitlist set source = 'x'$$,
  '42501',
  null,
  'anon cannot change rows'
);
select throws_ok('delete from public.waitlist', '42501', null, 'anon cannot delete rows');

select pg_temp.authenticated();
select throws_ok(
  $$insert into public.waitlist (email) values ('g@example.com')$$,
  '42501',
  null,
  'signed-in users have no business on the waitlist'
);
select throws_ok('select * from public.waitlist', '42501', null, 'signed-in users cannot read it either');

-- One address per hour is plenty; five is the cap per IP ----------------------

select pg_temp.anon();
select pg_temp.from_ip('198.51.100.7');
select lives_ok($$insert into public.waitlist (email) values ('h1@example.com')$$, 'first from an IP');
insert into public.waitlist (email) values ('h2@example.com');
insert into public.waitlist (email) values ('h3@example.com');
insert into public.waitlist (email) values ('h4@example.com');
select lives_ok($$insert into public.waitlist (email) values ('h5@example.com')$$, 'fifth from an IP');
select throws_ok(
  $$insert into public.waitlist (email) values ('h6@example.com')$$,
  'PT429',
  null,
  'the sixth address from one IP inside an hour is refused with 429'
);
select pg_temp.from_ip('198.51.100.8');
select lives_ok(
  $$insert into public.waitlist (email) values ('h6@example.com')$$,
  'another IP is not affected'
);

select pg_temp.logout();
update public.waitlist set created_at = now() - interval '2 hours' where ip = '198.51.100.7';
select pg_temp.anon();
select pg_temp.from_ip('198.51.100.7');
select lives_ok(
  $$insert into public.waitlist (email) values ('h7@example.com')$$,
  'the window closes after an hour'
);

-- The IP outlives its purpose by a day at most --------------------------------

select pg_temp.logout();
update public.waitlist set created_at = now() - interval '2 days' where email = 'h1@example.com';
select pg_temp.anon();
select pg_temp.from_ip('198.51.100.9');
insert into public.waitlist (email) values ('h8@example.com');
select pg_temp.logout();
select results_eq(
  $$select ip is null from public.waitlist where email = 'h1@example.com'$$,
  $$values (true)$$,
  'a day after the sign-up the IP is erased by the next insert'
);
select results_eq(
  $$select count(*) from public.waitlist where ip is null$$,
  $$values (1::bigint)$$,
  'younger rows keep theirs until the window has passed'
);

-- And a global cap, so a distributed flood costs at most a day of rows ------------

select pg_temp.anon();
do $$
begin
  -- Ten rows exist at this point, one of them backdated out of the day;
  -- 491 more make the day's 500.
  for i in 1..491 loop
    perform set_config('request.headers',
      json_build_object('x-forwarded-for', format('10.%s.%s.%s', i / 65536, (i / 256) % 256, i % 256))::text, true);
    insert into public.waitlist (email) values (format('flood%s@example.com', i));
  end loop;
end $$;
select pg_temp.from_ip('203.0.113.200');
select throws_ok(
  $$insert into public.waitlist (email) values ('late@example.com')$$,
  'PT429',
  null,
  'past 500 addresses in a day the list refuses everyone with 429'
);

select * from finish();
rollback;
