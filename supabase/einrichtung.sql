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
