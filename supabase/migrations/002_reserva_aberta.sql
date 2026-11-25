-- Reserva aberta para quem tem o link (sem login).
-- Só o dono (tabela admins, entra com e-mail e senha) bloqueia e cancela.
-- O banco recusa reserva em horário bloqueado, fora dos próximos 14 dias
-- ou com textos grandes demais.

alter table public.bookings alter column user_id drop not null;

drop policy if exists "ver reservas" on public.bookings;
drop policy if exists "reservar" on public.bookings;
drop policy if exists "ver bloqueios" on public.blocks;

create policy "ver reservas" on public.bookings
  for select to anon, authenticated using (true);

create policy "reservar" on public.bookings
  for insert to anon, authenticated with check (
    bookings.date between (now() at time zone 'America/Sao_Paulo')::date
                      and (now() at time zone 'America/Sao_Paulo')::date + 13
    and char_length(bookings.who) between 1 and 60
    and char_length(coalesce(bookings.team, '')) <= 60
    and char_length(bookings.purpose) between 1 and 200
    and bookings.id = to_char(bookings.date, 'YYYY-MM-DD') || '_' || lpad(bookings.hour::text, 2, '0')
    and not exists (
      select 1 from public.blocks b
      where b.id = bookings.id
         or b.id = to_char(bookings.date, 'YYYY-MM-DD') || '_all'
    )
  );

create policy "ver bloqueios" on public.blocks
  for select to anon, authenticated using (true);

-- Permissões da API (caso não tenham sido dadas automaticamente).
grant select, insert on public.bookings to anon;
grant select, insert, delete on public.bookings to authenticated;
grant select on public.blocks to anon;
grant select, insert, update, delete on public.blocks to authenticated;
grant execute on function public.is_admin() to anon, authenticated;
