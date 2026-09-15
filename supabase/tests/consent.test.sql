-- The record of explicit consent (Art. 9 (2) (a) GDPR) for sending journal
-- content to a model provider. Driven as the app drives it: the owner gives
-- consent, withdraws it, gives it again, and can never see or forge anyone
-- else's.
--
-- The record is append-only. Every grant and every withdrawal is its own
-- immutable row, because the controller has to be able to demonstrate what
-- was true *when* (Art. 7 (1)): a record that says "consent stands" while
-- silently having dropped a withdrawal would cover whatever was sent during
-- the withdrawn window. Nothing here is ever updated or deleted, and the
-- text of the notice is never stored per user — only the version naming it.
begin;
select plan(48);

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

select has_table('public', 'consent_events', 'consent_events table exists');
select ok(
  (select relrowsecurity
     from pg_class where oid = 'public.consent_events'::regclass),
  'row-level security is on for consent_events'
);
-- The notice lives on the web site and in the repository; a per-user copy of
-- it would be the one piece of personal data this table has no reason to hold.
select hasnt_column(
  'public', 'consent_events', 'text',
  'the consent text is not stored per user'
);

-- Giving consent --------------------------------------------------------------

select pg_temp.login('00000000-0000-0000-0000-00000000000a');

select lives_ok(
  $$select public.record_consent('2026-09-15')$$,
  'a user records their consent'
);
select results_eq(
  'select user_id from public.consent_events',
  $$values ('00000000-0000-0000-0000-00000000000a'::uuid)$$,
  'the event belongs to the caller'
);
select results_eq(
  $$select action from public.consent_events$$,
  $$values ('granted'::text)$$,
  'the event records that consent was given'
);
select isnt_empty(
  $$select recorded_at from public.consent_events
    where recorded_at is not null$$,
  'the moment is recorded'
);
select results_eq(
  $$select public.consent_stands('2026-09-15')$$,
  $$values (true)$$,
  'consent stands once given'
);

-- Withdrawing (Art. 7 (3): as easy as giving) ----------------------------------

select lives_ok(
  $$select public.withdraw_consent('2026-09-15')$$,
  'a user withdraws their own consent'
);
select results_eq(
  $$select public.consent_stands('2026-09-15')$$,
  $$values (false)$$,
  'consent no longer stands once withdrawn'
);
select results_eq(
  $$select count(*)::int from public.consent_events$$,
  $$values (2)$$,
  'withdrawing appends an event rather than changing the first'
);
select isnt_empty(
  $$select 1 from public.consent_events where action = 'granted'$$,
  'withdrawing keeps the record that consent was once given'
);

-- Re-consenting, the journey that used to erase the withdrawal ----------------

select lives_ok(
  $$select public.record_consent('2026-09-15')$$,
  'a user can consent again after withdrawing'
);
select results_eq(
  $$select public.consent_stands('2026-09-15')$$,
  $$values (true)$$,
  'consent stands again after being given a second time'
);
-- The whole point of the append-only record: the withdrawal is still there
-- to be found, so the row cannot claim unbroken consent since day one and
-- thereby cover whatever was written while it was withdrawn.
select results_eq(
  $$select count(*)::int from public.consent_events where action = 'withdrawn'$$,
  $$values (1)$$,
  'consenting again leaves the withdrawal discoverable'
);
select results_eq(
  $$select count(*)::int from public.consent_events$$,
  $$values (3)$$,
  'every decision is its own row'
);
select results_eq(
  $$select action from public.consent_events order by seq$$,
  $$values ('granted'::text), ('withdrawn'::text), ('granted'::text)$$,
  'the history reads in the order the decisions were made'
);

-- Idempotence is about not writing noise, not about erasing history ----------

select lives_ok(
  $$select public.record_consent('2026-09-15')$$,
  'recording consent that already stands is accepted'
);
select results_eq(
  $$select count(*)::int from public.consent_events$$,
  $$values (3)$$,
  'recording consent that already stands appends nothing'
);
select lives_ok(
  $$select public.withdraw_consent('never-seen')$$,
  'withdrawing a consent that was never given is harmless'
);
select results_eq(
  $$select count(*)::int from public.consent_events$$,
  $$values (3)$$,
  'withdrawing what was never given appends nothing'
);

-- A new wording is a new decision ---------------------------------------------

-- A different wording is a different question, and one consent never
-- answers the other. (Both are past dates: a version names the day its
-- wording was published, and the write path refuses a future one.)
select results_eq(
  $$select public.consent_stands('2026-08-01')$$,
  $$values (false)$$,
  'consent to one wording says nothing about another'
);
select lives_ok(
  $$select public.record_consent('2026-08-01')$$,
  'another version of the notice is consented to separately'
);
select results_eq(
  $$select count(*)::int from public.consent_events where version = '2026-08-01'$$,
  $$values (1)$$,
  'each version keeps its own history'
);
select results_eq(
  $$select public.consent_stands('2026-09-15')$$,
  $$values (true)$$,
  'and consenting to one does not disturb the other'
);

-- The record is the controller's evidence, not the user's to author ----------

-- Every one of these is a forgery the direct-insert grant used to allow.
-- Two independent things refuse them now: no insert privilege, and a policy
-- that permits `select` only, so even a restored grant writes nothing. Both
-- raise 42501, and the suite asserts the second directly below.
select throws_ok(
  $$insert into public.consent_events (version, action) values ('2026-09-15', 'granted')$$,
  '42501',
  null,
  'a user cannot write an event directly'
);
select throws_ok(
  $$insert into public.consent_events (version, action, recorded_at)
    values ('2026-09-15', 'granted', '2019-01-01')$$,
  '42501',
  null,
  'a user cannot backdate when they consented'
);
-- `generated always` refuses the supplied value (428C9) before privileges
-- are even consulted, so this is shut twice over.
select throws_ok(
  $$insert into public.consent_events (seq, version, action)
    values (999999, '2026-09-15', 'granted')$$,
  '428C9',
  null,
  'a user cannot choose where in the history their event lands'
);
select throws_ok(
  $$insert into public.consent_events (user_id, version, action)
    values ('00000000-0000-0000-0000-00000000000b', '2026-09-15', 'granted')$$,
  '42501',
  null,
  'a user cannot record consent for someone else'
);
-- A future version would walk past the next wording change silently, so the
-- write path refuses one. Computed from today, so this stays a future date
-- however long the repository lives.
select throws_ok(
  format(
    $$select public.record_consent(%L)$$,
    to_char(now() + interval '1 year', 'YYYY-MM-DD')
  ),
  '23514',
  null,
  'a version dated after today is refused'
);
select throws_ok(
  $$select public.record_consent('not-a-date')$$,
  '23514',
  null,
  'a junk version is refused'
);
select throws_ok(
  $$update public.consent_events set action = 'granted'$$,
  '42501',
  null,
  'a user cannot rewrite an event'
);
select throws_ok(
  $$delete from public.consent_events$$,
  '42501',
  null,
  'a user cannot delete an event'
);

-- Defence in depth, asserted rather than assumed: the policy permits
-- `select` only, so a restored insert privilege — a careless grant in a
-- later migration — still writes nothing. Granted and revoked inside the
-- transaction, so the suite leaves the schema as it found it.
select pg_temp.logout();
grant insert on public.consent_events to authenticated;
select pg_temp.login('00000000-0000-0000-0000-00000000000a');
select throws_ok(
  $$insert into public.consent_events (user_id, version, action)
    values ((select auth.uid()), '2026-09-15', 'granted')$$,
  '42501',
  null,
  'the policy alone refuses a forged insert, even with the privilege back'
);
select pg_temp.logout();
revoke insert on public.consent_events from authenticated;
select pg_temp.login('00000000-0000-0000-0000-00000000000a');

-- Another user sees and touches nothing ---------------------------------------

select pg_temp.login('00000000-0000-0000-0000-00000000000b');

select is_empty(
  'select * from public.consent_events',
  'another user sees no events'
);
select results_eq(
  $$select public.consent_stands('2026-09-15')$$,
  $$values (false)$$,
  'another user does not inherit a consent'
);
-- Refused outright rather than matching no rows: nobody holds an update
-- privilege on this table, their own history included.
select throws_ok(
  $$update public.consent_events set action = 'withdrawn'$$,
  '42501',
  null,
  'another user cannot rewrite someone else''s history'
);

-- Bob's own consent is his, and does not disturb Alice's.
select lives_ok(
  $$select public.record_consent('2026-09-15')$$,
  'another user records their own consent for the same version'
);
select results_eq(
  $$select count(*)::int from public.consent_events$$,
  $$values (1)$$,
  'each user sees only their own history'
);
select results_eq(
  $$select public.consent_stands('2026-09-15')$$,
  $$values (true)$$,
  'and their own consent stands'
);

-- Alice is untouched by any of it.
select pg_temp.login('00000000-0000-0000-0000-00000000000a');
select results_eq(
  $$select count(*)::int from public.consent_events where version = '2026-09-15'$$,
  $$values (3)$$,
  'the other user''s writes did not reach this one''s history'
);

-- Anonymous callers are locked out entirely -----------------------------------

select pg_temp.anon();

select throws_ok(
  'select * from public.consent_events',
  '42501',
  null,
  'anon cannot read the events'
);
select throws_ok(
  $$select public.record_consent('2026-09-15')$$,
  '42501',
  null,
  'anon cannot record a consent'
);
select throws_ok(
  $$select public.withdraw_consent('2026-09-15')$$,
  '42501',
  null,
  'anon cannot withdraw a consent'
);
select throws_ok(
  $$select public.consent_stands('2026-09-15')$$,
  '42501',
  null,
  'anon cannot ask whether a consent stands'
);

-- A signed-in caller only ever acts for themselves ----------------------------

-- record_consent is security definer so that it, and not the user, owns the
-- columns; the body must therefore pin the row to auth.uid() itself. With no
-- claims there is no caller, and it must write nothing rather than a row
-- owned by nobody.
select pg_temp.logout();
select throws_ok(
  $$select public.record_consent('2026-09-15')$$,
  '42501',
  null,
  'a caller without a JWT records nothing'
);

-- Deleting the account takes the whole history with it ------------------------

delete from auth.users where id = '00000000-0000-0000-0000-00000000000a';
select is_empty(
  $$select * from public.consent_events
    where user_id = '00000000-0000-0000-0000-00000000000a'$$,
  'the consent history cascades away with the account'
);
select isnt_empty(
  $$select 1 from public.consent_events
    where user_id = '00000000-0000-0000-0000-00000000000b'$$,
  'and takes nobody else''s with it'
);

select * from finish();
rollback;
