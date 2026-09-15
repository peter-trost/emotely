-- The record of explicit consent (Art. 9 (2) (a) GDPR) for sending journal
-- content to a model provider. Driven as the app drives it: the owner writes
-- and reads their own row, withdraws it, consents again after a wording
-- change, and can never see or forge anyone else's. The row is the proof the
-- controller has to be able to produce (Art. 7 (1)), so withdrawal marks it
-- rather than erasing it, and the text itself is never stored per user —
-- only the version identifier that names it.
begin;
select plan(34);

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

select has_table('public', 'consents', 'consents table exists');
select ok(
  (select relrowsecurity from pg_class where oid = 'public.consents'::regclass),
  'row-level security is on for consents'
);
-- The notice lives on the web site and in the repository; a per-user copy of
-- it would be the one piece of personal data this table has no reason to hold.
select hasnt_column('public', 'consents', 'text', 'the consent text is not stored per user');

-- Giving consent --------------------------------------------------------------

select pg_temp.login('00000000-0000-0000-0000-00000000000a');

select lives_ok(
  $$insert into public.consents (version) values ('2026-09-15')$$,
  'a user records their consent; user_id defaults to the caller'
);
select results_eq(
  'select user_id from public.consents',
  $$values ('00000000-0000-0000-0000-00000000000a'::uuid)$$,
  'the consent belongs to the caller'
);
select isnt_empty(
  $$select granted_at from public.consents where granted_at is not null$$,
  'the moment consent was given is recorded'
);
select results_eq(
  'select withdrawn_at from public.consents',
  $$values (null::timestamptz)$$,
  'a fresh consent is not withdrawn'
);

-- One row per user per version: a double-tapped button, or a retry after a
-- reply that never arrived, must not write a second record of the same act.
select throws_ok(
  $$insert into public.consents (version) values ('2026-09-15')$$,
  '23505',
  null,
  'consenting twice to the same version writes one row'
);

-- Withdrawing (Art. 7 (3): as easy as giving) ----------------------------------

select lives_ok(
  $$update public.consents set withdrawn_at = now() where version = '2026-09-15'$$,
  'a user withdraws their own consent'
);
select isnt_empty(
  $$select 1 from public.consents where withdrawn_at is not null$$,
  'the withdrawal is recorded'
);
select isnt_empty(
  $$select 1 from public.consents where granted_at is not null$$,
  'withdrawing keeps the record that consent was once given'
);

-- Consenting again after withdrawing is the same row coming back, not a
-- second one: the user is answering the same question a second time.
select lives_ok(
  $$update public.consents set withdrawn_at = null where version = '2026-09-15'$$,
  'a user can consent again after withdrawing'
);

-- A new wording is a new version, and a new decision --------------------------

select lives_ok(
  $$insert into public.consents (version) values ('2027-01-01')$$,
  'a later version of the notice is consented to separately'
);
select results_eq(
  $$select count(*)::int from public.consents$$,
  $$values (2)$$,
  'each version keeps its own record'
);

-- The user owns the row, not its history --------------------------------------

select throws_ok(
  $$insert into public.consents (user_id, version)
    values ('00000000-0000-0000-0000-00000000000b', '2026-09-15')$$,
  '42501',
  null,
  'a user cannot record consent for someone else'
);

-- Another user sees and touches nothing ---------------------------------------

select pg_temp.login('00000000-0000-0000-0000-00000000000b');

select is_empty(
  'select * from public.consents',
  'another user sees no consents'
);
select results_eq(
  $$with touched as (
      update public.consents set withdrawn_at = now() returning 1
    ) select count(*) from touched$$,
  $$values (0::bigint)$$,
  'another user cannot withdraw someone else''s consent'
);
-- Nobody deletes a consent record, their own included: it is the evidence
-- the controller has to be able to produce, and it goes only when the
-- account it belongs to goes.
select throws_ok(
  'delete from public.consents',
  '42501',
  null,
  'a consent record cannot be deleted by anyone'
);

-- Bob's own consent is his, and does not disturb Alice's.
select lives_ok(
  $$insert into public.consents (version) values ('2026-09-15')$$,
  'another user records their own consent for the same version'
);
select results_eq(
  $$select count(*)::int from public.consents$$,
  $$values (1)$$,
  'each user sees only their own record of the same version'
);

-- Anonymous callers are locked out entirely -----------------------------------

select pg_temp.anon();

select throws_ok(
  'select * from public.consents',
  '42501',
  null,
  'anon cannot read consents'
);
select throws_ok(
  $$insert into public.consents (version) values ('2026-09-15')$$,
  '42501',
  null,
  'anon cannot record a consent'
);

-- The record is the controller's proof, so it is not the user's to rewrite ------

select pg_temp.login('00000000-0000-0000-0000-00000000000a');

select throws_ok(
  $$update public.consents set granted_at = '2020-01-01' where version = '2026-09-15'$$,
  '42501',
  null,
  'a user cannot backdate when they consented'
);
select throws_ok(
  $$update public.consents set version = 'something-else' where version = '2026-09-15'$$,
  '42501',
  null,
  'a user cannot relabel which notice they consented to'
);

-- What the app actually calls -------------------------------------------------

-- Giving and withdrawing go through one function each, so the app never
-- writes the timestamps itself and a replayed tap is harmless.
select lives_ok(
  $$select public.record_consent('2026-09-15')$$,
  'recording consent again on an existing row is accepted'
);
select results_eq(
  $$select withdrawn_at from public.consents where version = '2026-09-15'$$,
  $$values (null::timestamptz)$$,
  'recording consent clears an earlier withdrawal'
);
select results_eq(
  $$select count(*)::int from public.consents where version = '2026-09-15'$$,
  $$values (1)$$,
  'recording consent twice still leaves one row'
);
select lives_ok(
  $$select public.withdraw_consent('2026-09-15')$$,
  'withdrawing consent is a call of its own'
);
select isnt_empty(
  $$select 1 from public.consents
    where version = '2026-09-15' and withdrawn_at is not null$$,
  'withdrawing marks the row withdrawn'
);
select lives_ok(
  $$select public.withdraw_consent('2026-09-15')$$,
  'withdrawing twice is harmless'
);
-- Withdrawing something never consented to is not an error the UI should have
-- to handle: the end state is what matters, and it is already true.
select lives_ok(
  $$select public.withdraw_consent('never-seen')$$,
  'withdrawing a consent that was never given is harmless'
);

select pg_temp.anon();
select throws_ok(
  $$select public.record_consent('2026-09-15')$$,
  '42501',
  null,
  'anon cannot record a consent through the function'
);
select throws_ok(
  $$select public.withdraw_consent('2026-09-15')$$,
  '42501',
  null,
  'anon cannot withdraw a consent through the function'
);

-- Deleting the account takes the consent record with it ------------------------

select pg_temp.logout();
delete from auth.users where id = '00000000-0000-0000-0000-00000000000a';
select is_empty(
  $$select * from public.consents
    where user_id = '00000000-0000-0000-0000-00000000000a'$$,
  'the consent record cascades away with the account'
);

select * from finish();
rollback;
