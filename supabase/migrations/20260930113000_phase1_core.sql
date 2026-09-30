-- BuroPilot Phase 1 core schema
create extension if not exists pgcrypto;

create type public.workspace_role as enum ('OWNER','ADMIN','MEMBER');
create type public.case_status as enum ('NEW','REVIEW','WAITING_CUSTOMER','PROCESSING','OFFER','FOLLOW_UP','WON','LOST','DONE');
create type public.execution_mode as enum ('AUTO','APPROVAL_REQUIRED','MANUAL');
create type public.approval_status as enum ('PENDING','APPROVED','REJECTED','CANCELLED');
create type public.workflow_status as enum ('PENDING','RUNNING','WAITING','SUCCEEDED','FAILED','CANCELLED');

create table public.workspaces (
  id uuid primary key default gen_random_uuid(),
  name text not null check (char_length(name) between 1 and 160),
  industry text,
  created_at timestamptz not null default now()
);

create table public.workspace_members (
  workspace_id uuid not null references public.workspaces(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  role public.workspace_role not null default 'MEMBER',
  created_at timestamptz not null default now(),
  primary key (workspace_id,user_id)
);

create table public.companies (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references public.workspaces(id) on delete cascade,
  name text not null,
  normalized_name text not null,
  created_at timestamptz not null default now(),
  unique(workspace_id, normalized_name)
);

create table public.contacts (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references public.workspaces(id) on delete cascade,
  company_id uuid references public.companies(id) on delete set null,
  name text,
  email text,
  normalized_email text,
  phone text,
  created_at timestamptz not null default now()
);
create unique index contacts_workspace_email_uq on public.contacts(workspace_id,normalized_email) where normalized_email is not null;

create table public.email_accounts (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references public.workspaces(id) on delete cascade,
  provider text not null check(provider in ('gmail','microsoft','development')),
  provider_account_id text not null,
  email_address text not null,
  token_ciphertext text,
  status text not null default 'connected' check(status in ('connected','reauth_required','disabled')),
  created_at timestamptz not null default now(),
  unique(workspace_id,provider,provider_account_id)
);

create table public.message_threads (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references public.workspaces(id) on delete cascade,
  email_account_id uuid not null references public.email_accounts(id) on delete cascade,
  provider_thread_id text not null,
  subject text,
  created_at timestamptz not null default now(),
  unique(email_account_id,provider_thread_id)
);

create table public.cases (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references public.workspaces(id) on delete cascade,
  company_id uuid references public.companies(id) on delete set null,
  contact_id uuid references public.contacts(id) on delete set null,
  thread_id uuid references public.message_threads(id) on delete set null,
  title text not null,
  status public.case_status not null default 'NEW',
  summary text,
  extracted_data jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index cases_workspace_status_idx on public.cases(workspace_id,status,updated_at desc);

create table public.messages (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references public.workspaces(id) on delete cascade,
  email_account_id uuid not null references public.email_accounts(id) on delete cascade,
  thread_id uuid not null references public.message_threads(id) on delete cascade,
  case_id uuid references public.cases(id) on delete set null,
  provider_message_id text not null,
  internet_message_id text,
  direction text not null check(direction in ('INBOUND','OUTBOUND')),
  sender text not null,
  recipients jsonb not null default '[]'::jsonb,
  subject text,
  body_text text,
  received_at timestamptz not null,
  classification jsonb,
  ai_summary text,
  created_at timestamptz not null default now(),
  unique(email_account_id,provider_message_id)
);
create index messages_thread_time_idx on public.messages(thread_id,received_at);

create table public.tasks (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references public.workspaces(id) on delete cascade,
  case_id uuid references public.cases(id) on delete cascade,
  assignee_id uuid references auth.users(id) on delete set null,
  title text not null,
  description text,
  due_at timestamptz,
  priority text not null default 'NORMAL' check(priority in ('LOW','NORMAL','HIGH')),
  status text not null default 'OPEN' check(status in ('OPEN','IN_PROGRESS','DONE','CANCELLED')),
  created_at timestamptz not null default now()
);

create table public.business_rules (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references public.workspaces(id) on delete cascade,
  rule_key text not null,
  enabled boolean not null default true,
  config jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  unique(workspace_id,rule_key)
);

create table public.workflow_executions (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references public.workspaces(id) on delete cascade,
  workflow_key text not null,
  workflow_version integer not null default 1 check(workflow_version > 0),
  trigger_key text not null,
  status public.workflow_status not null default 'PENDING',
  available_at timestamptz not null default now(),
  attempt_count integer not null default 0,
  last_error_code text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(workspace_id,workflow_key,trigger_key)
);
create index workflow_due_idx on public.workflow_executions(status,available_at);

create table public.workflow_steps (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references public.workspaces(id) on delete cascade,
  execution_id uuid not null references public.workflow_executions(id) on delete cascade,
  step_key text not null,
  status public.workflow_status not null default 'PENDING',
  idempotency_key text not null,
  output jsonb,
  error_code text,
  created_at timestamptz not null default now(),
  unique(workspace_id,idempotency_key),
  unique(execution_id,step_key)
);

create table public.approvals (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references public.workspaces(id) on delete cascade,
  case_id uuid references public.cases(id) on delete cascade,
  requested_by text not null check(requested_by in ('AI','SYSTEM','USER')),
  action_type text not null,
  action_payload jsonb not null,
  reason_code text not null,
  reason_summary text not null,
  status public.approval_status not null default 'PENDING',
  decided_by uuid references auth.users(id) on delete set null,
  decided_at timestamptz,
  created_at timestamptz not null default now()
);

create table public.audit_logs (
  id bigint generated always as identity primary key,
  workspace_id uuid not null references public.workspaces(id) on delete cascade,
  actor_type text not null check(actor_type in ('AI','SYSTEM','USER')),
  actor_user_id uuid references auth.users(id) on delete set null,
  action text not null,
  entity_type text not null,
  entity_id uuid,
  reason_code text,
  reason_summary text,
  result text not null,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);
create index audit_workspace_time_idx on public.audit_logs(workspace_id,created_at desc);

create table public.scheduled_actions (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references public.workspaces(id) on delete cascade,
  case_id uuid references public.cases(id) on delete cascade,
  action_type text not null,
  idempotency_key text not null,
  run_at timestamptz not null,
  cancelled_at timestamptz,
  completed_at timestamptz,
  payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  unique(workspace_id,idempotency_key)
);
create index scheduled_actions_due_idx on public.scheduled_actions(run_at) where cancelled_at is null and completed_at is null;

create or replace function public.is_workspace_member(target_workspace uuid)
returns boolean language sql stable security definer set search_path='' as $$
  select exists(select 1 from public.workspace_members wm where wm.workspace_id=target_workspace and wm.user_id=auth.uid());
$$;

alter table public.workspaces enable row level security;
alter table public.workspace_members enable row level security;
alter table public.companies enable row level security;
alter table public.contacts enable row level security;
alter table public.email_accounts enable row level security;
alter table public.message_threads enable row level security;
alter table public.cases enable row level security;
alter table public.messages enable row level security;
alter table public.tasks enable row level security;
alter table public.business_rules enable row level security;
alter table public.workflow_executions enable row level security;
alter table public.workflow_steps enable row level security;
alter table public.approvals enable row level security;
alter table public.audit_logs enable row level security;
alter table public.scheduled_actions enable row level security;

create policy workspace_member_read on public.workspaces for select using(public.is_workspace_member(id));
create policy members_read on public.workspace_members for select using(public.is_workspace_member(workspace_id));

do $$ declare t text; begin
  foreach t in array array['companies','contacts','email_accounts','message_threads','cases','messages','tasks','business_rules','workflow_executions','workflow_steps','approvals','audit_logs','scheduled_actions']
  loop execute format('create policy tenant_isolation on public.%I for all using (public.is_workspace_member(workspace_id)) with check (public.is_workspace_member(workspace_id))',t); end loop;
end $$;

revoke all on public.email_accounts from anon;
revoke all on public.workflow_executions from anon;
revoke all on public.workflow_steps from anon;
revoke all on public.audit_logs from anon;
