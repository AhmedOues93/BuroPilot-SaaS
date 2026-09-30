create or replace function public.create_workspace(workspace_name text, workspace_industry text default null)
returns uuid language plpgsql security definer set search_path='' as $$
declare new_id uuid;
begin
  if auth.uid() is null then raise exception 'authentication required'; end if;
  if char_length(trim(workspace_name)) < 1 or char_length(workspace_name) > 160 then raise exception 'invalid workspace name'; end if;
  insert into public.workspaces(name,industry) values(trim(workspace_name),nullif(trim(workspace_industry),'')) returning id into new_id;
  insert into public.workspace_members(workspace_id,user_id,role) values(new_id,auth.uid(),'OWNER');
  insert into public.business_rules(workspace_id,rule_key,enabled,config) values
    (new_id,'automatic_reply',false,'{}'::jsonb),
    (new_id,'send_prices_automatically',false,'{}'::jsonb),
    (new_id,'complaints_require_approval',true,'{}'::jsonb),
    (new_id,'follow_up',true,'{"businessDays":3}'::jsonb);
  return new_id;
end $$;
revoke all on function public.create_workspace(text,text) from public;
grant execute on function public.create_workspace(text,text) to authenticated;
