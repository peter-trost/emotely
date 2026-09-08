-- Row-level security for the journal tables, driven as the app would: every
-- statement runs as the `authenticated` role with a real user's JWT claims,
-- or as `anon` with none. What a user can see or touch is exactly their own
-- rows; anything else fails before it reaches a row.
begin;
select plan(27);

-- Impersonation helpers. auth.uid() reads `sub` from request.jwt.claims,
-- which is how PostgREST hands the verified JWT to Postgres.
create function pg_temp.login(uid uuid) returns void language plpgsql as $$
begin
  perform set_config('role', 'authenticated', true);
  perform set_config(
    'request.jwt.claims',
    json_build_object('sub', uid, 'role', 'authenticated')::text,
    true
  );
end $$;
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

insert into auth.users (id, email)
values
  ('00000000-0000-0000-0000-00000000000a', 'alice@example.com'),
  ('00000000-0000-0000-0000-00000000000b', 'bob@example.com');

-- Structure -----------------------------------------------------------------

select has_table('public', 'sessions', 'sessions table exists');
select has_table('public', 'entries', 'entries table exists');
select ok(
  (select relrowsecurity from pg_class where oid = 'public.sessions'::regclass),
  'row-level security is on for sessions'
);
select ok(
  (select relrowsecurity from pg_class where oid = 'public.entries'::regclass),
  'row-level security is on for entries'
);

-- Owner writes and reads ------------------------------------------------------

select pg_temp.login('00000000-0000-0000-0000-00000000000a');

select lives_ok(
  $$insert into public.sessions (id, question_set_id, transcript, signature)
    values ('10000000-0000-0000-0000-000000000001', 'default', '[]', 'sig-1')$$,
  'a user can start a session; user_id defaults to the caller'
);
select results_eq(
  'select user_id from public.sessions',
  $$values ('00000000-0000-0000-0000-00000000000a'::uuid)$$,
  'the session belongs to the caller'
);
select lives_ok(
  $$update public.sessions set transcript = '[{"role":"user"}]', signature = 'sig-2'
    where id = '10000000-0000-0000-0000-000000000001'$$,
  'a user can advance their own session'
);
select throws_ok(
  $$insert into public.sessions (question_set_id, transcript, signature)
    values ('default', '[]', 'sig-3')$$,
  '23505',
  null,
  'a user has at most one session in progress'
);
select lives_ok(
  $$insert into public.entries (session_id, summary, answers, questions)
    values ('10000000-0000-0000-0000-000000000001', 'A good day.', '{}', '{}')$$,
  'a user can save the entry of their session'
);
select throws_ok(
  $$update public.entries set summary = 'rewritten'$$,
  '42501',
  null,
  'entries are immutable once written'
);
select throws_ok(
  $$insert into public.sessions (user_id, question_set_id, transcript, signature)
    values ('00000000-0000-0000-0000-00000000000b', 'default', '[]', 'forged')$$,
  '42501',
  null,
  'a user cannot write a session for someone else'
);

-- Another user sees and touches nothing -----------------------------------------

select pg_temp.login('00000000-0000-0000-0000-00000000000b');

select is_empty('select * from public.sessions', 'another user sees no sessions');
select is_empty('select * from public.entries', 'another user sees no entries');
select results_eq(
  $$with touched as (
      update public.sessions set signature = 'tampered' returning 1
    ) select count(*) from touched$$,
  $$values (0::bigint)$$,
  'another user cannot update a session'
);
select results_eq(
  $$with touched as (delete from public.entries returning 1)
    select count(*) from touched$$,
  $$values (0::bigint)$$,
  'another user cannot delete an entry'
);

-- Anonymous callers are locked out entirely ---------------------------------------

select pg_temp.anon();

select throws_ok(
  'select * from public.sessions',
  '42501',
  null,
  'anon cannot read sessions'
);
select throws_ok(
  'select * from public.entries',
  '42501',
  null,
  'anon cannot read entries'
);
select throws_ok(
  'select public.delete_account()',
  '42501',
  null,
  'anon cannot call delete_account'
);

-- Completing a session is one atomic, owner-only step ---------------------------

select pg_temp.login('00000000-0000-0000-0000-00000000000a');
-- Only one session may be in progress, so the first one is closed by hand.
update public.sessions set status = 'completed'
  where id = '10000000-0000-0000-0000-000000000001';
select lives_ok(
  $$insert into public.sessions (id, question_set_id, transcript, signature, pending, questions)
    values ('10000000-0000-0000-0000-000000000002', 'default', '[]', 'sig-4',
            '{"tool_call_id": "c1"}', '[{"question_id": "q1"}]')$$,
  'a session carries its pending question and the questions asked so far'
);

select pg_temp.login('00000000-0000-0000-0000-00000000000b');
select throws_ok(
  $$select public.complete_session(
      '10000000-0000-0000-0000-000000000002', 'Not mine.', '{}', '[]')$$,
  'P0002',
  null,
  'another user cannot complete a session that is not theirs'
);

select pg_temp.login('00000000-0000-0000-0000-00000000000a');
select lives_ok(
  $$select public.complete_session(
      '10000000-0000-0000-0000-000000000002', 'A fine day.', '{"q1": 7}', '[{"question_id": "q1"}]')$$,
  'the owner completes their session'
);
select results_eq(
  $$select status from public.sessions where id = '10000000-0000-0000-0000-000000000002'$$,
  $$values ('completed'::text)$$,
  'completing marks the session completed'
);
select results_eq(
  $$select summary from public.entries where session_id = '10000000-0000-0000-0000-000000000002'$$,
  $$values ('A fine day.'::text)$$,
  'completing writes the entry for the session'
);
select throws_ok(
  $$select public.complete_session(
      '10000000-0000-0000-0000-000000000002', 'Again.', '{}', '[]')$$,
  'P0002',
  null,
  'a completed session cannot be completed again'
);

-- Account deletion takes everything with it -------------------------------------

select pg_temp.login('00000000-0000-0000-0000-00000000000a');
select lives_ok('select public.delete_account()', 'a user can delete their account');

select pg_temp.logout();
select is_empty(
  $$select * from auth.users where id = '00000000-0000-0000-0000-00000000000a'$$,
  'the auth user is gone'
);
select is_empty(
  $$select * from public.sessions
    where user_id = '00000000-0000-0000-0000-00000000000a'$$,
  'their sessions and entries cascade away'
);

select * from finish();
rollback;
