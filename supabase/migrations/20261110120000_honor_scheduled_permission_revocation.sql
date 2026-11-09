-- Align the shared station permission predicate with the scheduled-revocation
-- semantics already enforced by the registration decision transaction.
-- A future revoked_at remains effective until that timestamp; at and after it,
-- the individual permission is no longer valid. This migration changes source
-- only until explicitly reviewed and applied to the NEW METRA staging project.
do $migration$
declare
  v_definition text;
  v_needle constant text := 'AND permission.revoked_at IS NULL';
  v_replacement constant text :=
    'AND (permission.revoked_at IS NULL OR permission.revoked_at > statement_timestamp())';
  v_occurrences integer;
begin
  select pg_get_functiondef(
    'public.metra_user_has_station_permission(uuid,uuid,text)'::regprocedure
  ) into v_definition;

  v_occurrences :=
    (length(v_definition) - length(replace(v_definition, v_needle, '')))
    / length(v_needle);

  if v_occurrences <> 1 then
    raise exception
      'Expected exactly one permission revocation predicate; found %; no function change applied',
      v_occurrences;
  end if;

  v_definition := replace(v_definition, v_needle, v_replacement);

  if position(v_replacement in v_definition) = 0 then
    raise exception 'Scheduled permission revocation replacement verification failed';
  end if;

  execute v_definition;
end
$migration$;

comment on function public.metra_user_has_station_permission(uuid,uuid,text) is
  'Fail-closed station permission predicate. Individual grants with a future revoked_at remain valid strictly before that timestamp; grants are invalid at or after it.';
