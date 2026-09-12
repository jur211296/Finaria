---
id: es-ar-storage-groups-block-is-in-tuteo-not-voseo
status: backlog
priority: low
area: "l10n"
created: 2026-09-11
source: "review adversarial de `detach-failure-looks-like-success` (lente de producto y copy)"
---

# El bloque `storage.groups.*` de es-AR está en tuteo y el resto del idioma está en voseo

## El problema, en lenguaje de usuario

Quien tiene la app en español de Argentina lee «vos» en toda la app y de pronto «tú» en la pantalla de
«¿Dónde viven tus datos?». No rompe nada; suena a traducción de otro sitio.

## Lo medido (2026-09-11)

`Yala/Resources/es-AR.lproj/Localizable.strings` usa voseo en **124 sitios** (por ejemplo
`groups.errors.actionFailed` → «Volvé a intentarlo»), y **todo** el bloque `storage.groups.*` está en
tuteo: lo copió `add-l10n-key.sh`, que para `es-AR` copia el valor real de `es-419` en vez de dejar un
placeholder. BRAND-VOICE §9.4 manda voseo para es-AR.

## Lo que hay que hacer

Pasar el bloque entero a voseo, no una línea suelta: arreglar solo la última key añadida deja el bloque
más incoherente que antes. Y revisar si otros bloques nuevos heredaron lo mismo — el mecanismo del
script los produce a todos igual, así que probablemente no es el único.

## Cómo se prueba

`LocalizationParityTests` no lo ve (mide presencia de keys, no registro). Un escáner que busque formas
de tuteo (`tú `, `Vuelve`, `Inténtalo`, `tienes`) en `es-AR.lproj` daría la lista.
