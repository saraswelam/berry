create extension if not exists pgcrypto;

create table if not exists public.admin_users (
  user_id uuid primary key references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);
create or replace function public.is_admin() returns boolean
language sql stable security definer set search_path = '' as $$
  select exists(select 1 from public.admin_users where user_id = (select auth.uid()));
$$;
revoke all on function public.is_admin() from public;
grant execute on function public.is_admin() to anon, authenticated;

create table if not exists public.categories (
  id uuid primary key default gen_random_uuid(),
  name text not null check (length(trim(name)) between 1 and 100),
  slug text not null unique check (slug ~ '^[a-z0-9]+(-[a-z0-9]+)*$'),
  description text,
  display_order integer not null default 0,
  is_visible boolean not null default true,
  created_at timestamptz not null default now()
);
create table if not exists public.photographs (
  id uuid primary key default gen_random_uuid(),
  title text,
  caption text,
  description text,
  storage_path text not null unique,
  category_id uuid references public.categories(id) on delete restrict,
  display_order integer not null default 0,
  is_published boolean not null default false,
  is_featured boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists photographs_published_category_order on public.photographs(category_id, display_order) where is_published;
create index if not exists photographs_created_at on public.photographs(created_at desc);
create or replace function public.touch_updated_at() returns trigger language plpgsql set search_path = '' as $$
begin new.updated_at = now(); return new; end; $$;
drop trigger if exists photographs_touch_updated_at on public.photographs;
create trigger photographs_touch_updated_at before update on public.photographs for each row execute function public.touch_updated_at();

create table if not exists public.site_settings (
  id integer primary key check (id = 1),
  settings jsonb not null default '{"hero_photo_id":null,"hero_position":"center center","biography":"","email":"","phone":"","location":"","instagram":"","website":"","overlay_strength":0}'::jsonb,
  updated_at timestamptz not null default now()
);
insert into public.site_settings(id) values (1) on conflict do nothing;
insert into public.categories(name,slug,display_order) values
  ('Home','home',0),('Analog','analog',1),('Headshots','headshots',2),('Commercial','commercial',3),('Nature','nature',4),('Around the World','around-the-world',5),('Biography','biography',6),('Contact Information','contact-information',7)
on conflict (slug) do nothing;

alter table public.admin_users enable row level security;
alter table public.categories enable row level security;
alter table public.photographs enable row level security;
alter table public.site_settings enable row level security;
drop policy if exists "Admins can read admin registry" on public.admin_users;
create policy "Admins can read admin registry" on public.admin_users for select to authenticated using (public.is_admin());
drop policy if exists "Public reads visible categories" on public.categories;
create policy "Public reads visible categories" on public.categories for select to anon, authenticated using (is_visible or public.is_admin());
drop policy if exists "Admins manage categories" on public.categories;
create policy "Admins manage categories" on public.categories for all to authenticated using (public.is_admin()) with check (public.is_admin());
drop policy if exists "Public reads published photographs" on public.photographs;
create policy "Public reads published photographs" on public.photographs for select to anon, authenticated using (is_published or public.is_admin());
drop policy if exists "Admins manage photographs" on public.photographs;
create policy "Admins manage photographs" on public.photographs for all to authenticated using (public.is_admin()) with check (public.is_admin());
drop policy if exists "Public reads site settings" on public.site_settings;
create policy "Public reads site settings" on public.site_settings for select to anon, authenticated using (true);
drop policy if exists "Admins manage site settings" on public.site_settings;
create policy "Admins manage site settings" on public.site_settings for all to authenticated using (public.is_admin()) with check (public.is_admin());
grant select on public.categories, public.photographs, public.site_settings to anon, authenticated;
grant insert, update, delete on public.categories, public.photographs, public.site_settings to authenticated;
grant select on public.admin_users to authenticated;

insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types)
values ('portfolio-images','portfolio-images',true,26214400,array['image/jpeg','image/png','image/webp','image/gif','image/avif','image/tiff'])
on conflict (id) do update set public=true, file_size_limit=26214400, allowed_mime_types=excluded.allowed_mime_types;
drop policy if exists "Public can view portfolio images" on storage.objects;
create policy "Public can view portfolio images" on storage.objects for select to anon, authenticated using (bucket_id='portfolio-images');
drop policy if exists "Admins upload portfolio images" on storage.objects;
create policy "Admins upload portfolio images" on storage.objects for insert to authenticated with check (bucket_id='portfolio-images' and public.is_admin());
drop policy if exists "Admins update portfolio images" on storage.objects;
create policy "Admins update portfolio images" on storage.objects for update to authenticated using (bucket_id='portfolio-images' and public.is_admin()) with check (bucket_id='portfolio-images' and public.is_admin());
drop policy if exists "Admins delete portfolio images" on storage.objects;
create policy "Admins delete portfolio images" on storage.objects for delete to authenticated using (bucket_id='portfolio-images' and public.is_admin());
