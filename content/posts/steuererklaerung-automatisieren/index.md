+++
title = "Die Steuererklärung ein bisschen automatisieren"
date = 2026-10-08
description = "Ein deutscher Beispielartikel: wie ich Belege für die Steuererklärung mit einem kleinen Skript sortiere."
draft = true

[taxonomies]
tags = ["self-hosting"]

[extra]
lang = "de"
+++

Jedes Jahr dasselbe: Die Steuererklärung steht an, und die Belege liegen verteilt in Mails, Downloads und Papierstapeln.

## Belege einsammeln

Ein kleines Skript sammelt alle PDFs aus einem Ordner und benennt sie nach Datum um:

```sh
for f in ~/Belege/*.pdf; do
  d=$(pdfinfo "$f" | awk '/CreationDate/ {print $3, $4, $6}')
  echo "$d  $f"
done
```

## Fazit

Nicht perfekt, aber es spart jedes Jahr ein paar Stunden.
