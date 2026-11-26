-- VIVIDEIA database foundation. Apply in Supabase SQL Editor.
create extension if not exists pgcrypto;

create table if not exists public.profiles (
 id uuid primary key references auth.users(id) on delete cascade,
 display_name text,
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now()
);
create table if not exists public.projects (
 id uuid primary key default gen_random_uuid(),
 user_id uuid not null references auth.users(id) on delete cascade,
 title text not null default 'Nouveau projet',
 prompt text,
 status text not null default 'draft' check (status in ('draft','queued','processing','completed','failed')),
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now()
);
create table if not exists public.generations (
 id uuid primary key default gen_random_uuid(),
 user_id uuid not null references auth.users(id) on delete cascade,
 project_id uuid references public.projects(id) on delete set null,
 provider text not null,
 model text,
 prompt text not null,
 status text not null default 'queued' check (status in ('queued','processing','completed','failed','cancelled')),
 output_path text,
 error_message text,
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now()
);
create table if not exists public.credit_ledger (
 id uuid primary key default gen_random_uuid(),
 user_id uuid not null references auth.users(id) on delete cascade,
 amount integer not null check (amount <> 0),
 reason text not null,
 reference_id text,
 created_at timestamptz not null default now()
);

create index if not exists projects_user_created_idx on public.projects(user_id, created_at desc);
create index if not exists generations_user_created_idx on public.generations(user_id, created_at desc);
create index if not exists generations_project_idx on public.generations(project_id);
create index if not exists credit_ledger_user_created_idx on public.credit_ledger(user_id, created_at desc);

create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = ''
as $$
begin
 insert into public.profiles(id, display_name)
 values(new.id, coalesce(new.raw_user_meta_data ->> 'full_name', new.raw_user_meta_data ->> 'name'))
 on conflict(id) do nothing;
 return new;
end;
$$;
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users
 for each row execute procedure public.handle_new_user();

alter table public.profiles enable row level security;
alter table public.projects enable row level security;
alter table public.generations enable row level security;
alter table public.credit_ledger enable row level security;

create policy "profiles_select_own" on public.profiles for select to authenticated using (id = (select auth.uid()));
create policy "profiles_update_own" on public.profiles for update to authenticated using (id = (select auth.uid())) with check (id = (select auth.uid()));
create policy "projects_select_own" on public.projects for select to authenticated using (user_id = (select auth.uid()));
create policy "projects_insert_own" on public.projects for insert to authenticated with check (user_id = (select auth.uid()));
create policy "projects_update_own" on public.projects for update to authenticated using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));
create policy "projects_delete_own" on public.projects for delete to authenticated using (user_id = (select auth.uid()));
create policy "generations_select_own" on public.generations for select to authenticated using (user_id = (select auth.uid()));
create policy "credit_ledger_select_own" on public.credit_ledger for select to authenticated using (user_id = (select auth.uid()));

insert into storage.buckets(id,name,public)
values('generated-videos','generated-videos',false)
on conflict(id) do nothing;
create policy "generated_videos_read_own" on storage.objects for select to authenticated
using (bucket_id = 'generated-videos' and (storage.foldername(name))[1] = (select auth.uid())::text);
