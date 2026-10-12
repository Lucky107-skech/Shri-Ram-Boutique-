-- Shri Ram Boutique production schema for Supabase.
-- Run this entire file in Supabase Dashboard > SQL Editor.
create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text,
  role text not null default 'customer' check (role in ('customer','admin')),
  created_at timestamptz not null default now()
);

create table if not exists public.products (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  description text not null default '',
  category text not null default 'Ethnic Wear',
  price numeric(10,2) not null check (price >= 0),
  image_url text not null default '',
  stock integer not null default 0 check (stock >= 0),
  active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.orders (
  id uuid primary key default gen_random_uuid(),
  customer_id uuid not null references auth.users(id) on delete restrict,
  customer_name text not null,
  phone text not null,
  address text not null,
  notes text not null default '',
  items jsonb not null,
  total numeric(10,2) not null check (total >= 0),
  status text not null default 'pending' check (status in ('pending','confirmed','packed','shipped','completed','cancelled')),
  payment_status text not null default 'pay_on_confirmation' check (payment_status in ('pay_on_confirmation','pending','paid','failed','refunded')),
  created_at timestamptz not null default now()
);

create index if not exists products_active_category_idx on public.products(active, category);
create index if not exists orders_created_at_idx on public.orders(created_at desc);
create index if not exists orders_customer_idx on public.orders(customer_id);

alter table public.profiles enable row level security;
alter table public.products enable row level security;
alter table public.orders enable row level security;

-- Profiles: signed-in users can read/update their own profile. Role changes are not allowed via client policy.
drop policy if exists "profiles select own" on public.profiles;
create policy "profiles select own" on public.profiles for select to authenticated using (auth.uid() = id);
drop policy if exists "profiles insert own customer" on public.profiles;
create policy "profiles insert own customer" on public.profiles for insert to authenticated with check (auth.uid() = id and role = 'customer');
drop policy if exists "profiles update own name" on public.profiles;
create policy "profiles update own name" on public.profiles for update to authenticated using (auth.uid() = id) with check (auth.uid() = id and role = 'customer');

-- Products: visitors can view active products; admins manage products.
drop policy if exists "public view active products" on public.products;
create policy "public view active products" on public.products for select using (active = true or exists (select 1 from public.profiles p where p.id = auth.uid() and p.role = 'admin'));
drop policy if exists "admins insert products" on public.products;
create policy "admins insert products" on public.products for insert to authenticated with check (exists (select 1 from public.profiles p where p.id = auth.uid() and p.role = 'admin'));
drop policy if exists "admins update products" on public.products;
create policy "admins update products" on public.products for update to authenticated using (exists (select 1 from public.profiles p where p.id = auth.uid() and p.role = 'admin')) with check (exists (select 1 from public.profiles p where p.id = auth.uid() and p.role = 'admin'));
drop policy if exists "admins delete products" on public.products;
create policy "admins delete products" on public.products for delete to authenticated using (exists (select 1 from public.profiles p where p.id = auth.uid() and p.role = 'admin'));

-- Customers create orders only for themselves and can read their own orders. Admin can read/update all orders.
drop policy if exists "customers create own orders" on public.orders;
create policy "customers create own orders" on public.orders for insert to authenticated with check (auth.uid() = customer_id and status = 'pending' and payment_status = 'pay_on_confirmation');
drop policy if exists "customers read own orders" on public.orders;
create policy "customers read own orders" on public.orders for select to authenticated using (auth.uid() = customer_id or exists (select 1 from public.profiles p where p.id = auth.uid() and p.role = 'admin'));
drop policy if exists "admins update orders" on public.orders;
create policy "admins update orders" on public.orders for update to authenticated using (exists (select 1 from public.profiles p where p.id = auth.uid() and p.role = 'admin')) with check (exists (select 1 from public.profiles p where p.id = auth.uid() and p.role = 'admin'));

-- Create a profile automatically when a customer signs up.
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public
as $$
begin
  insert into public.profiles (id, full_name, role)
  values (new.id, coalesce(new.raw_user_meta_data->>'full_name',''), 'customer')
  on conflict (id) do nothing;
  return new;
end;
$$;
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users
for each row execute procedure public.handle_new_user();

-- IMPORTANT: after creating your account, make yourself admin by running the
-- UPDATE command in README.md using your exact account email.
