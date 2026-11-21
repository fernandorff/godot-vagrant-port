#!/bin/bash
# Roda o Godot do port com a janela fora da tela (esconder-janela.ps1). Uso: ./godot.sh -- --caso=1 --rapido --saida=x.json --png=a.png ...
cd "$(dirname "$0")"
powershell -NoProfile -ExecutionPolicy Bypass -File esconder-janela.ps1 60 >/dev/null 2>&1 &
E=$!
# repassa a saída, sem o ruído de fim de processo do Godot
timeout 90 ../../Godot_v4.7.2-stable_win64_console.exe --path . --resolution 1280x720 "$@" 2>&1 | grep -vE "BUG: Unref|leaked|PagedAllocator|RID alloc|^\s+at: (unref|cleanup|~)" 
kill $E 2>/dev/null; true
