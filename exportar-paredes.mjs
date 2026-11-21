// Exporta as paredes que somem (window.sala.fadeaveis) com o nome do nó que o exportar.mjs (godot-vagrant) deu a cada uma.
// Refaz a mesma numeração: mesmas raízes, mesmos descartes, travessia em pré-ordem sem ossos. Uso: node exportar-paredes.mjs
import { writeFileSync } from 'node:fs';
import { abrir } from '../godot-vagrant/pagina.mjs';
const { page, fechar } = await abrir('overlay=0');
const r = await page.evaluate(() => {
  const s = window.sala, cena = s.cena, rio = s.mundo.rio, domo = s.mundo.domo;
  const ugs = new Set(s.unidades.map((u) => u.g)), sol = cena.children.find((o) => o.isDirectionalLight);
  const raizes = cena.children.filter((o) => !o.isLight && !ugs.has(o) && o !== sol.target && !o.isSprite && !o.isLineSegments && !o.isPoints && !(o.isMesh && o.material.isShaderMaterial));
  const fora = new Set();
  for (const raiz of raizes) raiz.traverse((o) => { if (o !== raiz && (o.isSprite || o.isLineSegments || o.isPoints || o === domo || (o.isMesh && o.material.isShaderMaterial && o !== rio))) fora.add(o); });
  let cont = 0; const nome = new Map();
  const anda = (o) => { if (fora.has(o)) return; if (!o.isBone) nome.set(o, 'n' + cont++); o.children.forEach(anda); };
  raizes.forEach(anda);
  return { total: cont, paredes: s.fadeaveis.map((f) => ({ no: nome.get(f.obj) || null, a: f.a, b: f.b, n: f.n.toArray(), y0: f.y0, y1: f.y1, nome: f.nome })) };
});
console.log('nós:', r.total, 'paredes:', r.paredes.length, 'sem nome:', r.paredes.filter((p) => !p.no).length);
writeFileSync('export/paredes.json', JSON.stringify(r.paredes));
await fechar();
