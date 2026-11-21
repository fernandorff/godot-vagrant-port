#!/bin/bash
# Etapa 2: fps Godot (4 modos de sombra) e Three (mesmos modos), respeitando a trava de medição de godot-candidatos.
cd "$(dirname "$0")"
LOCK=../godot-candidatos/LOCK-MEDICAO.txt
while [ -f "$LOCK" ]; do sleep 10; done
echo "port-etapa2 $(date -Iseconds)" > "$LOCK"
powershell -NoProfile -ExecutionPolicy Bypass -File esconder-janela.ps1 900 &
ESC=$!
trap 'rm -f "$LOCK"; kill $ESC 2>/dev/null' EXIT
G=../../Godot_v4.7.2-stable_win64_console.exe
for r in 1 2 3; do
  for m in nao dura suave pcss; do
    x=""; s=$m; [ $m = pcss ] && { x="--pcss=1"; s=suave; }
    echo "gpu antes: $(nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader)" > medicoes/gpu-$m-$r.txt
    timeout 90 $G --path . --resolution 1280x720 --position -5000,0 -- --caso=1 --saida=medicoes/godot-$m-$r.json --sombras=$s $x >/dev/null 2>&1
  done
done
node ../medir-sala-fechada.mjs --so 0,1,4,5 > medicoes/three.log 2>&1
cp ../fps-sala-fechada-chrome.json medicoes/three-etapa2.json 2>/dev/null
echo FIM
