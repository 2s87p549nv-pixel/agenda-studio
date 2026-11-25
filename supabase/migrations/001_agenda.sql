-- Agenda do Studio: tabelas, função de dono e regras de acesso.
-- Já executado no projeto xuattbqijnjvqsbzcjgo (agenda-studio).

create table public.admins (
  user_id uuid primary key references auth.users(id) on delete cascade
);

create table public.bookings (
  id text primary key,            -- AAAA-MM-DD_HH: impede reserva dupla
  date date not null,
  hour int not null check (hour between 8 and 19),
  who text not null,
  team text,
  purpose text not null,
  user_id uuid not null default auth.uid(),
  created_at timestamptz not null default now()
);

create table public.blocks (
  id text primary key,            -- AAAA-MM-DD_all (dia) ou AAAA-MM-DD_HH (hora)
  date date not null,
  hour int check (hour between 8 and 19),
  reason text,
  created_at timestamptz not null default now()
);

alter table public.admins enable row level security;
alter table public.bookings enable row level security;
alter table public.blocks enable row level security;

create or replace function public.is_admin() returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.admins where user_id = auth.uid())
$$;

-- qualquer pessoa logada vê a agenda e reserva
create policy "ver reservas" on public.bookings for select to authenticated using (true);
create policy "reservar" on public.bookings for insert to authenticated with check (user_id = auth.uid());
-- só o dono cancela
create policy "cancelar so dono" on public.bookings for delete to authenticated using (public.is_admin());

-- todos veem os bloqueios; só o dono cria, altera e remove
create policy "ver bloqueios" on public.blocks for select to authenticated using (true);
create policy "bloquear so dono" on public.blocks for all to authenticated
  using (public.is_admin()) with check (public.is_admin());
