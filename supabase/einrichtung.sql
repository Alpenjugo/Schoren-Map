-- Wichtelweg Schoren: Datenbank-Einrichtung für Supabase
-- In Supabase öffnen: SQL Editor → New query → alles einfügen → Run.
-- Das Skript kann gefahrlos mehrmals ausgeführt werden.

-- 1) Tabelle: ein Eintrag pro teilnehmender Adresse (EGAID aus dem amtlichen Gebäudeadressverzeichnis)
create table if not exists public.teilnehmer (
  egaid         bigint primary key,
  hinweis       text not null default '' check (char_length(hinweis) <= 200),
  geaendert_am  timestamptz not null default now(),
  geaendert_von uuid default auth.uid()
);

-- 2) Zugriffsschutz einschalten (Row Level Security)
alter table public.teilnehmer enable row level security;

-- 3) Rechte: Besucher (anon) sehen nur Adresse und Hinweis, angemeldete Konten dürfen bearbeiten
revoke all on table public.teilnehmer from anon, authenticated;
grant select (egaid, hinweis) on table public.teilnehmer to anon;
grant select, insert, update, delete on table public.teilnehmer to authenticated;

-- 4) Regeln
drop policy if exists "Alle duerfen lesen" on public.teilnehmer;
drop policy if exists "Angemeldete duerfen einfuegen" on public.teilnehmer;
drop policy if exists "Angemeldete duerfen aendern" on public.teilnehmer;
drop policy if exists "Angemeldete duerfen loeschen" on public.teilnehmer;

create policy "Alle duerfen lesen" on public.teilnehmer
  for select to anon, authenticated using (true);
create policy "Angemeldete duerfen einfuegen" on public.teilnehmer
  for insert to authenticated with check (true);
create policy "Angemeldete duerfen aendern" on public.teilnehmer
  for update to authenticated using (true) with check (true);
create policy "Angemeldete duerfen loeschen" on public.teilnehmer
  for delete to authenticated using (true);

-- 5) Wer hat wann geändert (nur für die Verwaltung sichtbar)
create or replace function public.teilnehmer_geaendert()
returns trigger language plpgsql set search_path = '' as $$
begin
  new.geaendert_am := pg_catalog.now();
  new.geaendert_von := auth.uid();
  return new;
end $$;

drop trigger if exists teilnehmer_geaendert on public.teilnehmer;
create trigger teilnehmer_geaendert
  before insert or update on public.teilnehmer
  for each row execute function public.teilnehmer_geaendert();

-- 5b) Datum und Zeit pro Haus
alter table public.teilnehmer add column if not exists ab_datum date;
alter table public.teilnehmer add column if not exists zeit_von time;
alter table public.teilnehmer add column if not exists zeit_bis time;
alter table public.teilnehmer add column if not exists nur_am boolean not null default false;  -- true = nur an diesem Datum, false = ab diesem Datum

alter table public.teilnehmer drop constraint if exists teilnehmer_zeit_reihenfolge;
alter table public.teilnehmer add constraint teilnehmer_zeit_reihenfolge
  check (zeit_von is null or zeit_bis is null or zeit_bis > zeit_von);

-- Besucher dürfen die neuen Felder lesen (Schreiben bleibt den angemeldeten Konten vorbehalten)
grant select (ab_datum, nur_am, zeit_von, zeit_bis) on table public.teilnehmer to anon;

-- 6) Einstellungen (Text unter dem Titel)
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
  for insert to authenticated with check (schluessel in ('zeitraum', 'titel'));
create policy "Angemeldete duerfen Einstellungen aendern" on public.einstellungen
  for update to authenticated using (true) with check (schluessel in ('zeitraum', 'titel'));

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
values ('zeitraum', '1. bis 24. Dezember, täglich ab 17 Uhr'), ('titel', 'Wichtelweg')
on conflict (schluessel) do nothing;
