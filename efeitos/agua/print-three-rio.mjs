// Referência para a nota de semelhança: print 1280x720 do rio na página Three (planta mundo), câmera igual à vista
// "rio" do Godot (centro da caixa do rio + (0, 8, 10), olhando o centro). Usa o abridor da etapa 1 (só leitura).
// Uso: node print-three-rio.mjs [claro]
import { abrir, dormir } from '../../../godot-vagrant/pagina.mjs';
const claro = process.argv[2] === 'claro';
const { page, erros, fechar } = await abrir('overlay=0');
await page.addStyleTag({ content: '#faixa,#medidas,#pular{display:none!important}' });
const info = await page.evaluate((claro) => {
  const s = window.sala; let rio = null;
  s.cena.traverse((o) => { if (o.isMesh && o.material && o.material.uniforms && o.material.uniforms.aneis && !rio) rio = o; });
  rio.geometry.computeBoundingBox(); const b = rio.geometry.boundingBox.clone().applyMatrix4(rio.matrixWorld);
  const c = b.getCenter(new s.cam.position.constructor());
  window.__vista = { p: c.clone().add(new s.cam.position.constructor(0, 8, 10)), c };
  if (claro) { const amb = s.cena.children.find((o) => o.isAmbientLight); amb.color.setRGB(1, 1, 1); amb.intensity = 1; s.poeNevoa('desligada'); }
  return { centro: c.toArray(), caixa: [b.min.toArray(), b.max.toArray()] };
}, claro);
console.log(JSON.stringify(info));
// ganchos de teste da página: mira (alvo fixo) e gira (órbita az, distância, ângulo polar) = posição centro + (0, 8, 10)
await page.evaluate(() => { const s = window.sala, c = window.__vista.c; s.mira(c.x, c.y, c.z); s.gira(0, Math.hypot(8, 10), Math.atan2(10, 8)); });
await dormir(3000);
await page.locator('canvas').screenshot({ path: `imagens/three-rio${claro ? '-claro' : ''}.png` });
console.log(JSON.stringify(await page.evaluate(() => { const c = window.sala.cam; return { pos: c.position.toArray(), quat: c.quaternion.toArray() }; })), erros);
await fechar();
