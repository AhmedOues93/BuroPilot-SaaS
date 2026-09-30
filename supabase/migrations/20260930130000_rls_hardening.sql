-- Harden tenant permissions before exposing authenticated UI.
create or replace function public.has_workspace_role(target_workspace uuid, allowed public.workspace_role[])
returns boolean language sql stable security definer set search_path='' as $$
  select exists(
    select 1 from public.workspace_members wm
    where wm.workspace_id=target_workspace and wm.user_id=auth.uid() and wm.role=any(allowed)
  );
$$;

-- Sensitive execution/audit tables are server-managed. Authenticated users may read their tenant only.
do $$ declare t text; begin
  foreach t in array array['email_accounts','message_threads','messages','workflow_executions','workflow_steps','audit_logs','scheduled_actions']
  loop
    execute format('drop policy if exists tenant_isolation on public.%I',t);
    execute format('create policy tenant_read on public.%I for select using (public.is_workspace_member(workspace_id))',t);
  end loop;
end $$;

drop policy if exists tenant_isolation on public.business_rules;
create policy rules_read on public.business_rules for select using(public.is_workspace_member(workspace_id));
create policy rules_admin_insert on public.business_rules for insert with check(public.has_workspace_role(workspace_id,array['OWNER','ADMIN']::public.workspace_role[]));
create policy rules_admin_update on public.business_rules for update using(public.has_workspace_role(workspace_id,array['OWNER','ADMIN']::public.workspace_role[])) with check(public.has_workspace_role(workspace_id,array['OWNER','ADMIN']::public.workspace_role[]));
create policy rules_admin_delete on public.business_rules for delete using(public.has_workspace_role(workspace_id,array['OWNER','ADMIN']::public.workspace_role[]));

-- Approvals can be read by members, but only owner/admin may decide them from client sessions.
drop policy if exists tenant_isolation on public.approvals;
create policy approvals_read on public.approvals for select using(public.is_workspace_member(workspace_id));
create policy approvals_admin_update on public.approvals for update using(public.has_workspace_role(workspace_id,array['OWNER','ADMIN']::public.workspace_role[])) with check(public.has_workspace_role(workspace_id,array['OWNER','ADMIN']::public.workspace_role[]));

revoke all on function public.has_workspace_role(uuid,public.workspace_role[]) from public;
grant execute on function public.has_workspace_role(uuid,public.workspace_role[]) to authenticated;
