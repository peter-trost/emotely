-- `delete_account()` returns whether it actually deleted something.
--
-- The web deletion page (/delete-account) shows an irreversible "your
-- account is gone" screen on the strength of this call. The void version
-- could only answer "the statement ran without raising", which is also
-- what a caller whose row was already gone gets, so the page would have
-- claimed more than it knew. Returning a boolean makes the confirmation
-- honest: true only when a row in auth.users really went.
--
-- The return type is part of the signature, so this is a drop and recreate.
-- The body, the `security definer` and the grants are unchanged; the app
-- calls this through `rpc<Object?>` and ignores the result, so the extra
-- value costs it nothing (ADR 0010).

drop function public.delete_account();

create function public.delete_account()
returns boolean
language sql
security definer
set search_path = ''
as $$
  with deleted as (
    delete from auth.users where id = (select auth.uid()) returning 1
  )
  select exists (select 1 from deleted);
$$;

comment on function public.delete_account() is
  'Deletes the calling user and, by cascade, all their journal data. '
  'Returns true when a row was deleted, false when there was none.';

revoke execute on function public.delete_account() from public, anon;
grant execute on function public.delete_account() to authenticated;
