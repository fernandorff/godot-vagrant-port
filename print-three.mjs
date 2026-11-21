// Print do Three para comparar com o Godot. Uso: node print-three.mjs <vista: braseiro|padrao> nome=query [nome=query ...]
// braseiro: câmera na posição padrão olhando (29,1,10), igual ao --olhar=29,1,10 do Godot; padrao: câmera da página sem mexer.
import { abrir, dormir } from '../godot-vagrant/pagina.mjs';
const [vista, ...casos] = process.argv.slice(2);
for (const c of casos) {
  const [nome, q] = c.split(/=(.*)/s);
  const { page, fechar } = await abrir(q);
  await page.addStyleTag({ content: '#faixa,#medidas,#pular{display:none!important}' });
  // a câmera é forçada a cada atualização de matriz: a fumaça (fumaca.js) lê a câmera antes do render da cena
  if (vista === 'braseiro') await page.evaluate(() => { const c = window.sala.cam, o = c.updateMatrixWorld.bind(c);
    c.updateMatrixWorld = (f) => { c.position.set(19, 5.514362685672278, 18.273630769381157); c.lookAt(29, 1, 10); o(f); }; });
  await dormir(2500);
  await page.locator('canvas').screenshot({ path: `three-${nome}.png` });
  await fechar();
}
