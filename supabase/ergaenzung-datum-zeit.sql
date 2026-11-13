-- Wichtelweg Schoren: Ergänzung «Datum und Zeit» pro Haus
-- Einmal ausführen in Supabase: SQL Editor → New query → alles einfügen → Run.
-- Kann gefahrlos mehrmals ausgeführt werden. Ist bereits in einrichtung.sql enthalten.

alter table public.teilnehmer add column if not exists ab_datum date;
alter table public.teilnehmer add column if not exists zeit_von time;
alter table public.teilnehmer add column if not exists zeit_bis time;

alter table public.teilnehmer drop constraint if exists teilnehmer_zeit_reihenfolge;
alter table public.teilnehmer add constraint teilnehmer_zeit_reihenfolge
  check (zeit_von is null or zeit_bis is null or zeit_bis > zeit_von);

-- Besucher dürfen die neuen Felder lesen (Schreiben bleibt den angemeldeten Konten vorbehalten)
grant select (ab_datum, zeit_von, zeit_bis) on table public.teilnehmer to anon;
