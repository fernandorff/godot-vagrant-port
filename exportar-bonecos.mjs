// Etapa 9: reexporta os bonecos de sala-fechada.html com TODOS os clipes dos gestos (parado, andar, correr, golpe,
// magia), e grava a grade de andar da planta (export/grade.json). Mesmo processo da parte 5 de ../godot-vagrant/exportar.mjs;
// a sala não é tocada. A pasta de origem só é lida.
// Uso: node exportar-bonecos.mjs  -> export/bonecos.glb, export/grade.json, e cena.json ganha "gestos" em cada unidade
import { writeFileSync, readFileSync } from 'node:fs';
import { abrir } from '../godot-vagrant/pagina.mjs';

const { page, erros, fechar } = await abrir('overlay=0');
const r = await page.evaluate(async () => {
  const T = await import('https://unpkg.com/three@0.117.1/build/three.module.js');
  const { GLTFExporter } = await import('https://unpkg.com/three@0.117.1/examples/jsm/exporters/GLTFExporter.js');
  const s = window.sala, P = s.P;
  const exportar = (entrada, opcoes) => new Promise((ok, erro) => new GLTFExporter().parse(entrada, ok, { binary: true, onlyVisible: false, trs: true, embedImages: true, ...opcoes }));
  const b64 = (ab) => { let s2 = ''; const u8 = new Uint8Array(ab); for (let i = 0; i < u8.length; i += 0x8000) s2 += String.fromCharCode.apply(null, u8.subarray(i, i + 0x8000)); return btoa(s2); };

  // ---- grade: as regras de caminho() da página (sala-fechada.html:1342), com a água desligada --------------------
  const CEL = 2, ANDA = '.->^v<~', VIZ = [[1, 0], [-1, 0], [0, 1], [0, -1]];
  const texto = P.texto; if (!Array.isArray(texto)) throw new Error('planta sem texto: ' + typeof texto);
  const W = texto[0].length, H = texto.length;
  const pisa = (cx, cz) => { const L = s.letra(cx, cz), p = P.pisa?.(L); if (p !== undefined) return p; return ANDA.includes(L); };
  const celulas = [];
  for (let cz = 0; cz < H; cz++) for (let cx = 0; cx < W; cx++) {
    const vizinhos = VIZ.map(([dx, dz]) => {
      const n = [cx + dx, cz + dz];
      if (!pisa(cx, cz) || !pisa(...n) || P.corta?.([cx, cz], n) || Math.abs(s.borda(cx, cz, dx, dz) - s.borda(n[0], n[1], -dx, -dz)) > 0.6) return 0;
      return P.molha?.(n[0] * CEL + 1, n[1] * CEL + 1) ? 3.5 : 1;
    });
    celulas.push({ p: pisa(cx, cz) ? 1 : 0, v: vizinhos });
  }
  const PASSO = 0.25, NX = W * CEL / PASSO + 1, NZ = H * CEL / PASSO + 1, alt = [], bloq = [];
  for (let iz = 0; iz < NZ; iz++) for (let ix = 0; ix < NX; ix++) { const x = ix * PASSO, z = iz * PASSO; alt.push(+s.seco(x, z).toFixed(3)); bloq.push(P.bloqueia?.(x, z) ? 1 : 0); }
  // conferência: rotas da página para comparar com o Godot
  const us = s.unidades.map((u) => [u.cx, u.cz]);
  const testes = [[us[0], us[4]], [us[0], us[6]], [us[0], us[7]], [us[1], us[5]]].map(([a, b]) => ({ de: a, para: b, rota: s.caminho(a, b) }));
  const grade = { W, H, CEL, PASSO, NX, NZ, celulas, alt, bloq, testes, pisaU: s.unidades.map((u) => [u.cx, u.cz]) };

  // ---- bonecos (parte 5 de exportar.mjs) com todos os clipes dos gestos ------------------------------------------
  let cont = 0; const unidMeta = []; const grupoB = new T.Group(); grupoB.name = 'bonecos'; const clipes = [];
  const reestrutura = (sk, prefixo) => {
    const osso0 = sk.children.filter((c) => c.isBone), pai = sk.parent;
    const env = new T.Group(); env.position.copy(sk.position); env.quaternion.copy(sk.quaternion); env.scale.copy(sk.scale); env.name = prefixo + '_arm';
    sk.position.set(0, 0, 0); sk.quaternion.set(0, 0, 0, 1); sk.scale.set(1, 1, 1);
    pai.remove(sk); osso0.forEach((b) => { sk.remove(b); env.add(b); }); env.add(sk); pai.add(env); sk.updateMatrixWorld(true);
    return env;
  };
  const cache = new Map();
  const padrao = (m) => { const k = [m.type, m.map && m.map.uuid, m.color && m.color.getHex(), m.side, m.opacity, m.transparent, m.vertexColors, m.alphaTest].join('|'); if (!cache.has(k)) cache.set(k, new T.MeshStandardMaterial({ color: m.color || 0xffffff, map: m.map || null, side: m.side, transparent: m.transparent, opacity: m.opacity, alphaTest: m.alphaTest || 0, roughness: 1, metalness: 0, vertexColors: m.vertexColors })); return cache.get(k); };
  for (const [i, u] of s.unidades.entries()) {
    const p = `u${i}`; const m = u.mesh;
    // volta ao parado e zera a pose, como no export da etapa 1
    u.g.remove(u.pega); if (u.leva.g && u.leva.g.parent) u.leva.g.parent.remove(u.leva.g);
    m.skeleton.bones.forEach((b, k) => (b.name = `${p}_b${k}`));
    const filhosSk = []; m.traverse((o) => { if (o !== m && o.isSkinnedMesh) filhosSk.push(o); });
    filhosSk.forEach((w, j) => { w.skeleton.bones.forEach((b, k) => (b.name = `${p}_w${j}_b${k}`)); });
    // tocha na mão (sala-fechada.html:1293-1301): osso da mão e do ombro, o lado e qual peça é o escudo
    const mao = { mao: u.mao ? m.skeleton.bones.indexOf(u.mao) : -1, ombro: u.ombro ? m.skeleton.bones.indexOf(u.ombro) : -1, lado: u.lado || 1, escudo: u.escudo ? filhosSk.indexOf(u.escudo) : -1 };
    if (mao.escudo >= 0) mao.escudo = `${p}_w${mao.escudo}_arm`; else mao.escudo = null;
    reestrutura(m, p); filhosSk.forEach((w, j) => reestrutura(w, `${p}_w${j}`));
    const texCanvas = new Map();
    const canvasDe = (dt) => { if (!texCanvas.has(dt)) { const c = document.createElement('canvas'); c.width = dt.image.width; c.height = dt.image.height; c.getContext('2d').putImageData(new ImageData(new Uint8ClampedArray(dt.image.data), c.width, c.height), 0, 0); const ct = new T.CanvasTexture(c); ct.flipY = false; ct.magFilter = ct.minFilter = T.NearestFilter; ct.wrapS = ct.wrapT = T.RepeatWrapping; texCanvas.set(dt, ct); } return texCanvas.get(dt); };
    u.g.traverse((o) => {
      if (!o.isMesh) return;
      if (o.material.isShaderMaterial && o.material.uniforms.map) { const ca = o.geometry.attributes.color; if (ca) for (let k = 0; k < ca.array.length; k++) ca.array[k] *= 2; const dt = o.material.uniforms.map.value; o.material = new T.MeshStandardMaterial({ map: canvasDe(dt), alphaTest: o.material.alphaTest || 0.1, transparent: false, roughness: 1, metalness: 0, vertexColors: !!o.geometry.attributes.color, side: o.material.side }); }
      else if (!o.material.isMeshBasicMaterial) o.material = padrao(o.material);
    });
    u.g.traverse((o) => { if (!o.isBone) { o.name = o.name && o.name.startsWith(p) ? o.name : `${p}_n${cont++}`; } });
    u.g.name = `${p}_${u.nome.replace(/\s+/g, '')}`;
    // um clipe por índice usado em algum gesto; "gestos" diz a sequência de cada gesto (a página toca em fila)
    const gestos = {}, feitos = new Set(), duracoes = {};
    for (const [g, ids] of Object.entries(u.indices)) {
      gestos[g] = ids.map((k) => `${p}_c${k}`);
      for (const k of ids) {
        if (feitos.has(k)) continue; feitos.add(k);
        const c0 = u.clips[k];
        const tr = c0.tracks.map((t) => { const q = /^\.bones\[(\d+)\]\.(.+)$/.exec(t.name); const t2 = t.clone(); t2.name = `${p}_b${q[1]}.${q[2]}`; return t2; });
        clipes.push(new T.AnimationClip(`${p}_c${k}`, c0.duration, tr)); duracoes[`${p}_c${k}`] = c0.duration;
      }
    }
    // as cinco poses do pulo por saída (pulo-vs.js posesDoPulo): parado, andando, correndo; null quando o SEQ não tem
    const poses = {};
    for (const [modo, fases] of Object.entries(u.poses)) {
      if (!fases) { poses[modo] = null; continue; }
      poses[modo] = {};
      for (const [fase, c0] of Object.entries(fases)) {
        const nome = `${p}_pulo_${modo}_${fase}`; poses[modo][fase] = nome;
        const tr = c0.tracks.map((t) => { const q = /^\.bones\[(\d+)\]\.(.+)$/.exec(t.name); const t2 = t.clone(); t2.name = `${p}_b${q[1]}.${q[2]}`; return t2; });
        clipes.push(new T.AnimationClip(nome, c0.duration, tr)); duracoes[nome] = c0.duration;
      }
    }
    unidMeta.push({ i, no: u.g.name, gestos, poses, duracoes, mao, cx: u.cx, cz: u.cz });
    grupoB.children.push(u.g);
  }
  const bonBuf = await exportar([grupoB], { animations: clipes });
  return { bonecos: b64(bonBuf), unidMeta, grade };
});
writeFileSync('export/bonecos.glb', Buffer.from(r.bonecos, 'base64'));
writeFileSync('export/grade.json', JSON.stringify(r.grade));
const cena = JSON.parse(readFileSync('export/cena.json', 'utf8'));
for (const u of r.unidMeta) { const c = cena.unidades[u.i]; if (c.no !== u.no) throw new Error('nó mudou: ' + c.no + ' ' + u.no); Object.assign(c, { gestos: u.gestos, poses: u.poses, duracoes: u.duracoes, mao: u.mao, cx: u.cx, cz: u.cz }); }
writeFileSync('export/cena.json', JSON.stringify(cena, null, 1));
console.log('grade', r.grade.W, 'x', r.grade.H, 'alturas', r.grade.NX, 'x', r.grade.NZ, 'testes', JSON.stringify(r.grade.testes.map((t) => t.rota && t.rota.length)));
console.log('gestos', JSON.stringify(r.unidMeta.map((u) => [u.no, Object.fromEntries(Object.entries(u.gestos).map(([g, l]) => [g, l.length]))])));
console.log('erros da página:', erros);
await fechar();
