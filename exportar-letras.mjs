// Grava export/letras.json: a letra de cada casa da planta (s.letra da página), para saber o que é ar livre (FORA de
// planta-mundo.js:13), o lado de dentro da casa ('h') e a caverna. Também a luz da hora (HORA) já está em cena.json.
// Uso: node exportar-letras.mjs   (a partir de lab-engine/godot-vagrant, que tem pagina.mjs)
import { writeFileSync } from 'node:fs';
import { abrir } from '../godot-vagrant/pagina.mjs';
const { page, fechar } = await abrir('overlay=0');
const r = await page.evaluate(() => { const s = window.sala, t = s.P.texto, H = t.length, W = t[0].length, l = [];
  for (let z = 0; z < H; z++) { let linha = ''; for (let x = 0; x < W; x++) linha += s.letra(x, z); l.push(linha); }
  return { W, H, FORA: ',:TRrbhH', linhas: l }; });
writeFileSync(new URL('./export/letras.json', import.meta.url), JSON.stringify(r));
console.log(r.W, r.H, [...new Set(r.linhas.join(''))].join(''));
await fechar();
