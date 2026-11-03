"""Baut public/index.html aus src/app.html und den Daten in src/data.
Voraussetzung: npm install (Leaflet, leaflet-rotate, Schrift). Aufruf im Projektordner: python3 src/build.py"""
import pathlib, re, base64
R = pathlib.Path(__file__).resolve().parent.parent
nm, d = R / 'node_modules', R / 'src' / 'data'
t = (R / 'src' / 'app.html').read_text(encoding='utf-8')
strip = lambda s: re.sub(r'//# sourceMappingURL=.*', '', s)
rot = (nm / 'leaflet-rotate/dist/leaflet-rotate-src.js').read_text()
# Korrektur leaflet-rotate 0.5.3: Beim Zoomen mit zwei Fingern muss der Fingermittelpunkt auf der
# neuen Zoomstufe umgerechnet werden (wie im Original-Leaflet), sonst springt die Karte.
bug = 'this._center = map.unproject(map.project(this._pinchStartLatLng).subtract(mapDelta));'
assert bug in rot, 'leaflet-rotate hat sich geändert: Korrektur prüfen'
rot = rot.replace(bug, 'this._center = map.unproject(map.project(this._pinchStartLatLng, this._zoom).subtract(mapDelta), this._zoom);')
js = strip((nm / 'leaflet/dist/leaflet.js').read_text()) + '\n' + strip(rot)
css = (nm / 'leaflet/dist/leaflet.css').read_text()
for img in ['layers.png', 'layers-2x.png']:
    css = css.replace('images/' + img, 'data:image/png;base64,' + base64.b64encode((nm / 'leaflet/dist/images' / img).read_bytes()).decode())
font = base64.b64encode((nm / '@fontsource-variable/bricolage-grotesque/files/bricolage-grotesque-latin-wght-normal.woff2').read_bytes()).decode()
for k, v in [('/*LEAFLET_CSS*/', css), ('/*FONT*/', font), ('/*LEAFLET_JS*/', js),
             ('/*ADDR*/', (d / 'addr.min.json').read_text()), ('/*GRENZE*/', (d / 'grenze.min.json').read_text()),
             ('/*STREETS*/', (d / 'streets.min.json').read_text()), ('/*BUILDINGS*/', (d / 'buildings.min.json').read_text())]:
    assert k in t, k
    t = t.replace(k, v, 1)
(R / 'public' / 'index.html').write_text(t, encoding='utf-8')
print('public/index.html gebaut,', len(t), 'Zeichen')
