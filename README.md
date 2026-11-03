# Wichtelweg-Karte Schoren

Interaktive Karte für den Wichtelweg des Freizeitclubs Schoren (St. Gallen): Besucher sehen die teilnehmenden Häuser, die Verwaltung trägt sie nach dem Anmelden direkt auf der Karte ein. Diese Anleitung führt in vier Schritten zur Karte auf der Website. Rechne mit etwa 45 Minuten.

**Inhalt des Pakets**

| Datei / Ordner | Zweck |
|---|---|
| `public/` | Die fertige Karte. Diesen Ordner veröffentlicht Cloudflare. |
| `public/config.js` | Verbindung zur Datenbank. Hier kommen in Schritt 2 zwei Werte hinein. |
| `supabase/einrichtung.sql` | Richtet die Datenbank samt Zugriffsschutz ein. |
| `jimdo-einbettung.html` | Code-Schnipsel für die Jimdo-Seite. |
| `src/` | Quelle der Karte und Daten. Daraus baut `npm install && npm run build` die Datei `public/index.html`. |

Tipp: Öffne `public/index.html` vorher einmal per Doppelklick. Ohne Datenbank läuft die Karte im Demo-Modus, und du kannst die Verwaltung ausprobieren («Verwaltung», beliebige E-Mail und beliebiges Passwort). Die Demo-Daten bleiben nur in deinem Browser.

---

## Schritt 1: Datenbank bei Supabase einrichten

1. Auf [supabase.com](https://supabase.com) ein kostenloses Konto anlegen. Wenn möglich mit einer Vereinsadresse, damit die Karte nicht an einer Person hängt.
2. **New project** anlegen:
   - Name z. B. `wichtelweg-schoren`
   - Region **Central EU (Frankfurt)**
   - Ein sicheres Datenbank-Passwort wählen und gut aufbewahren. Es wird für die Karte nicht gebraucht.
3. Warten, bis das Projekt bereit ist (1–2 Minuten).
4. Links **SQL Editor** öffnen → **New query** → den ganzen Inhalt von `supabase/einrichtung.sql` einfügen → **Run**. Es muss «Success» erscheinen.
5. **Selbstregistrierung ausschalten:** Unter **Authentication** in den Einstellungen für die Anmeldung (Sign In / Providers) die Option **Allow new users to sign up** deaktivieren und speichern. So kann niemand selbst ein Konto anlegen.
6. **Konten anlegen:** **Authentication → Users → Add user → Create new user**.
   - E-Mail und Passwort eingeben.
   - Die Option zur automatischen Bestätigung (**Auto Confirm User**) anhaken.
   - Für die zweite Person dasselbe wiederholen.

## Schritt 2: Karte mit der Datenbank verbinden

1. In Supabase oben auf **Connect** klicken, oder unter **Project Settings → API Keys** nachsehen. Dort stehen:
   - die **Project URL**, z. B. `https://abcdefgh.supabase.co`
   - der **Publishable key**, beginnt mit `sb_publishable_`. Falls nur ein «anon key» angezeigt wird, geht auch dieser.
2. Auf GitHub die Datei `public/config.js` öffnen, auf das Stift-Symbol (**Edit**) klicken und beide Werte zwischen die Anführungszeichen setzen:

   ```js
   window.WICHTELWEG_CONFIG = {
     supabaseUrl: 'https://abcdefgh.supabase.co',
     supabaseKey: 'sb_publishable_…'
   };
   ```

   Dieser Schlüssel ist öffentlich und darf in der Karte stehen. **Niemals** den «secret» oder «service_role» Key eintragen.
3. **Commit changes** klicken. Alternativ schickst du mir die beiden Werte, und ich trage sie ein.

## Schritt 3: Mit Cloudflare Pages verbinden (automatisch aus GitHub)

1. Auf [cloudflare.com](https://dash.cloudflare.com/sign-up) ein kostenloses Konto anlegen.
2. Im Dashboard **Workers & Pages → Create application → Pages → Import an existing Git repository** wählen und GitHub verbinden. Dabei nur dieses Repository freigeben.
3. Repository `Schoren-Map` auswählen und die Einstellungen so setzen:
   - **Framework preset:** None
   - **Build command:** leer lassen
   - **Build output directory:** `public`
4. **Save and Deploy**. Die Karte ist danach unter `<projektname>.pages.dev` erreichbar.
5. Prüfen:
   - Über «Verwaltung» anmelden, ein Haus antippen und **Aufnehmen**.
   - In einem anderen Browser kontrollieren, dass es rot erscheint.

**Spätere Änderungen an der Karte:** Jede Änderung im Branch `main` wird automatisch veröffentlicht, nach etwa einer Minute ist sie online. Eine fehlerhafte Version lässt sich bei Cloudflare unter **Deployments** mit **Rollback** zurücknehmen.

**Häuser ein- und austragen** geht jederzeit direkt auf der Karte, ohne GitHub.

## Schritt 4: In die Jimdo-Seite einbetten

1. In Jimdo die gewünschte Seite öffnen (z. B. eine neue Unterseite «Wichtelweg» unter «Aktuell 2026»).
2. **Inhalt hinzufügen → Weitere Inhalte & Add-ons → Widget/HTML**.
3. Den Inhalt von `jimdo-einbettung.html` einfügen und darin `wichtelweg-schoren` durch euren tatsächlichen Projektnamen ersetzen.
4. Speichern und die Seite auf Computer und Handy ansehen.

Hinweise zur Einbettung:

- Oben rechts in der eingebetteten Karte erscheint ein Knopf für die **Vollbild-Ansicht**. Unterwegs ist das auf dem Handy angenehmer.
- Für den QR-Code auf dem Flyer entweder die Jimdo-Seite oder direkt die `pages.dev`-Adresse verwenden. Für Leute unterwegs empfehle ich die direkte Adresse.
- **Zum Bearbeiten** besser die direkte `pages.dev`-Adresse öffnen, nicht die Jimdo-Seite. Manche Browser (v. a. Safari) merken sich die Anmeldung in eingebetteten Seiten nicht.
- Falls Jimdo das Element «Widget/HTML» in eurem Abo nicht anbietet: einfach einen normalen Link oder Knopf auf die `pages.dev`-Adresse setzen.

---

## Gut zu wissen

- **Kosten:** Supabase und Cloudflare Pages sind in den Gratis-Tarifen kostenlos. Ein Supabase-Gratisprojekt wird pausiert, wenn es längere Zeit (rund eine Woche) nicht genutzt wird. Vor dem nächsten Wichtelweg im Supabase-Dashboard wieder aktivieren.
- **Was gespeichert wird:** Nur die Adress-Kennung (EGAID) der teilnehmenden Häuser und euer Hinweistext. Keine Namen und keine Besucherdaten. Der Standort im Knopf «Mein Standort» bleibt auf dem Handy der Besucher und wird nirgends übertragen.
- **Sicherheit:** Lesen darf jede und jeder, ändern nur die angelegten Konten. Das regelt die Datenbank selbst, nicht nur die Karte.
- **Datenstand:** Adressen und Strassen sind amtliche Daten von swisstopo, Stand 3. November 2026. Die Hausumrisse sind von 2022. Schorenstrasse 42 hat keinen Umriss und erscheint deshalb als Punkt.
