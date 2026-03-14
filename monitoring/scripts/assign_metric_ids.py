#!/usr/bin/env python3
"""
Asigna IDs enteros secuenciales a las filas de la tabla principal de métricas
en c:\Devs\raspi-docs\monitoring\métricas.md

Uso: ejecutar desde la raíz del repo:
  python monitoring/scripts/assign_metric_ids.py

El script realiza un backup c:\Devs\raspi-docs\monitoring\métricas.md.bak antes de sobrescribir.
"""
import re
from pathlib import Path
p = Path(r"c:\Devs\raspi-docs\monitoring\métricas.md")
bak = p.with_suffix(p.suffix + ".bak")
text = p.read_text(encoding="utf-8")
bak.write_text(text, encoding="utf-8")

lines = text.splitlines()
out = []
i = 0
# buscar el header exacto de la tabla principal
header_re = re.compile(r'^\|\s*Metric\s*\|\s*Help\s*\|\s*Type\s*\|\s*Uso\s*\|', re.IGNORECASE)
while i < len(lines):
    line = lines[i]
    if header_re.match(line):
        # reemplazar header y separator
        out.append("| ID | Metric | Help | Type | Uso |")
        i += 1
        # reemplazar separator (la siguiente línea)
        if i < len(lines):
            sep = lines[i]
            # contar columnas basadas en pipes
            out.append("|----:|--------|------|------|-----|")
            i += 1
        # procesar filas de la tabla hasta línea que no empiece por '|'
        id_counter = 1
        while i < len(lines) and lines[i].strip().startswith("|"):
            row = lines[i]
            # si ya tiene ID (p. ej. | 1 | ...), saltar
            if re.match(r'^\|\s*\d+\s*\|', row):
                out.append(row)
            else:
                # insertar ID tras el primer pipe
                out.append("| {:d} |{}".format(id_counter, row.lstrip("|").rstrip()))
                id_counter += 1
            i += 1
        continue
    out.append(line)
    i += 1

new_text = "\n".join(out)
p.write_text(new_text, encoding="utf-8")
print(f"IDs insertados (backup en {bak})")
