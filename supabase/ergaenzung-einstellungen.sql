-- Wichtelweg Schoren: Ergänzung «Einstellungen» (Text unter dem Titel)
-- Einmal ausführen in Supabase: SQL Editor → New query → alles einfügen → Run.
-- Kann gefahrlos mehrmals ausgeführt werden. Ist bereits in einrichtung.sql enthalten.

create table if not exists public.einstellungen (
  schluessel    text primary key,
  wert          text not null default '' check (char_length(wert) <= 300),
  geaendert_am  timestamptz not null default now(),
  geaendert_von uuid default auth.uid()
);

alter table public.einstellungen enable row level security;

revoke all on table public.einstellungen from anon, authenticated;
grant select (schluessel, wert) on table public.einstellungen to anon;
grant select, insert, update on table public.einstellungen to authenticated;

drop policy if exists "Alle duerfen Einstellungen lesen" on public.einstellungen;
drop policy if exists "Angemeldete duerfen Einstellungen anlegen" on public.einstellungen;
drop policy if exists "Angemeldete duerfen Einstellungen aendern" on public.einstellungen;

create policy "Alle duerfen Einstellungen lesen" on public.einstellungen
  for select to anon, authenticated using (true);
-- Nur bekannte Einstellungen sind erlaubt
create policy "Angemeldete duerfen Einstellungen anlegen" on public.einstellungen
  for insert to authenticated with check (schluessel in ('zeitraum'));
create policy "Angemeldete duerfen Einstellungen aendern" on public.einstellungen
  for update to authenticated using (true) with check (schluessel in ('zeitraum'));

create or replace function public.einstellungen_geaendert()
returns trigger language plpgsql set search_path = '' as $$
begin
  new.geaendert_am := pg_catalog.now();
  new.geaendert_von := auth.uid();
  return new;
end $$;

drop trigger if exists einstellungen_geaendert on public.einstellungen;
create trigger einstellungen_geaendert
  before insert or update on public.einstellungen
  for each row execute function public.einstellungen_geaendert();

insert into public.einstellungen (schluessel, wert)
values ('zeitraum', '1. bis 24. Dezember, täglich ab 17 Uhr')
on conflict (schluessel) do nothing;
