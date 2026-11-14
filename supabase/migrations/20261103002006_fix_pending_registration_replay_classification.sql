-- Make the replay classification repair safe after the preceding migration.
-- 20261103001942 may already have moved the pending-request branch ahead of the
-- linked-account branch. In that case this migration must verify and no-op,
-- rather than fail while replaying a clean database.
do $migration$
declare
  v_definition text;
  v_old text := $old$
  if exists (select 1 from public.metra_account_states s where s.user_id = p_auth_user_id)
     or exists (select 1 from public.metra_user_profiles p where p.user_id = p_auth_user_id) then
    return query select 'auth_user_already_linked'::text, null::uuid, null::uuid;
    return;
  end if;

  if exists (
    select 1 from public.registration_requests r
     where r.user_id = p_auth_user_id
       and r.status in ('pending_station_approval','pending_system_approval')
  ) then
    return query select 'existing_pending'::text, null::uuid, null::uuid;
    return;
  end if;
$old$;
  v_new text := $new$
  if exists (
    select 1 from public.registration_requests r
     where r.user_id = p_auth_user_id
       and r.status in ('pending_station_approval','pending_system_approval')
  ) then
    return query select 'existing_pending'::text, null::uuid, null::uuid;
    return;
  end if;

  if exists (select 1 from public.metra_account_states s where s.user_id = p_auth_user_id)
     or exists (select 1 from public.metra_user_profiles p where p.user_id = p_auth_user_id) then
    return query select 'auth_user_already_linked'::text, null::uuid, null::uuid;
    return;
  end if;
$new$;
  v_pending_position integer;
  v_linked_position integer;
begin
  select pg_get_functiondef(
    'private.submit_metra_registration(uuid,text,text,text,text,text,uuid,text,timestamptz,text)'::regprocedure
  ) into v_definition;

  v_pending_position := position('existing_pending' in v_definition);
  v_linked_position := position('auth_user_already_linked' in v_definition);

  if v_pending_position = 0 or v_linked_position = 0 then
    raise exception 'registration replay branches not found; no function change applied';
  end if;

  if v_pending_position > v_linked_position then
    if position(v_old in v_definition) = 0 then
      raise exception 'expected registration replay block not found; no function change applied';
    end if;
    v_definition := replace(v_definition, v_old, v_new);
  end if;

  if position('existing_pending' in v_definition) = 0
     or position('auth_user_already_linked' in v_definition) = 0
     or position('existing_pending' in v_definition) > position('auth_user_already_linked' in v_definition) then
    raise exception 'registration replay block ordering verification failed';
  end if;

  execute v_definition;
end
$migration$;
