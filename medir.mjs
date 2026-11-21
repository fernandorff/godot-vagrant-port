// Mede variantes de efeito na sala (Godot 4.7.2, Forward+), método da etapa 1 (godot-vagrant/medir.mjs):
// 1280x720 fora da tela, vsync desligado, 2 s de aquecimento + 10 s, rodadas intercaladas (a base entra em toda rodada), mediana.
// Placa <= 5% (3 leituras seguidas) antes de cada rodada; se não chegar em 60 s, mede assim mesmo e marca foraDoMetodo.
// Um medindo por vez: LOCK-MEDICAO.txt (CONTRATO-MODULOS.md, seção 6).
// Uso: node medir.mjs --efeitos "base;chamas/particulas-nativo;sombra/pcss-nativo,sombra/ssao-nativo" [--vista braseiro] [--rodadas 3] [--saida medicoes/x.json] [--quem chamas]
import { spawn, execFileSync } from 'node:child_process';
import { readFileSync, writeFileSync, existsSync, rmSync, mkdirSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
const AQUI = dirname(fileURLToPath(import.meta.url)).replace(/\\/g, '/');
const arg = (k, d) => { const i = process.argv.indexOf('--' + k); return i > 0 ? process.argv[i + 1] : d; };
const VARIANTES = arg('efeitos', 'base').split(';').map((s) => s.trim()).filter(Boolean);
if (!VARIANTES.includes('base')) VARIANTES.unshift('base');
const VISTA = arg('vista', 'padrao');
const RODADAS = +arg('rodadas', 3);
const SAIDA = join(AQUI, arg('saida', `medicoes/medicao-${Date.now()}.json`));
const QUEM = arg('quem', 'sem-nome');
const GODOT = 'D:/Projetos/godot-cidade/Godot_v4.7.2-stable_win64.exe';
const LOGS = join(AQUI, 'medicoes', 'logs'); mkdirSync(LOGS, { recursive: true }); mkdirSync(dirname(SAIDA), { recursive: true });
const LOCK = join(AQUI, 'LOCK-MEDICAO.txt');
const dormir = (ms) => new Promise((r) => setTimeout(r, ms));
const gpu = () => +execFileSync('nvidia-smi', ['--query-gpu=utilization.gpu', '--format=csv,noheader,nounits']).toString().trim();
async function esperarGpu() {
  const t0 = Date.now(); let ok = 0; const lidas = [];
  while (Date.now() - t0 < 60000) { const u = gpu(); lidas.push(u); ok = u <= 5 ? ok + 1 : 0; if (ok >= 3) return { lidas: lidas.slice(-3), fora: false }; await dormir(700); }
  return { lidas: lidas.slice(-5), fora: true };
}
const mediana = (a) => { const s = [...a].sort((x, y) => x - y); return s.length % 2 ? s[(s.length - 1) / 2] : (s[s.length / 2 - 1] + s[s.length / 2]) / 2; };
while (existsSync(LOCK)) { console.log('esperando lock: ' + readFileSync(LOCK, 'utf8').trim()); await dormir(10000); }
writeFileSync(LOCK, `${QUEM} ${new Date().toISOString()}\n`);
const solta = () => rmSync(LOCK, { force: true });
process.on('SIGINT', () => { solta(); process.exit(1); });
const res = [];
try {
  for (let r = 1; r <= RODADAS; r++) for (const v of VARIANTES) {
    const nome = v.replace(/[\/,]/g, '_'), arq = join(LOGS, `${nome}-${VISTA}-r${r}.json`); rmSync(arq, { force: true });
    const g = await esperarGpu();
    const p = spawn(GODOT, ['--path', AQUI, '--rendering-method', 'forward_plus', '--resolution', '1280x720', '--position', '-5000,0', '--disable-vsync',
      '--', `--efeitos=${v === 'base' ? '' : v}`, `--vista=${VISTA}`, `--saida=${arq}`], { stdio: ['ignore', 'pipe', 'pipe'] });
    let log = ''; p.stdout.on('data', (d) => (log += d)); p.stderr.on('data', (d) => (log += d));
    const t0 = Date.now(); let saiu = null; p.on('exit', (k) => (saiu = k ?? 'sinal'));
    while (saiu === null && Date.now() - t0 < 120000) await dormir(200);
    if (saiu === null) execFileSync('taskkill', ['/PID', String(p.pid), '/T', '/F'], { stdio: 'ignore' });
    writeFileSync(join(LOGS, `${nome}-${VISTA}-r${r}.log`), log);
    const erros = log.split('\n').filter((l) => /ERROR|SCRIPT ERROR|Parse Error/i.test(l));
    if (!existsSync(arq)) { console.log(`${v} r${r}: SEM JSON (saiu ${saiu})`, erros.slice(0, 3)); continue; }
    const b = JSON.parse(readFileSync(arq, 'utf8')); Object.assign(b, { variante: v, rodada: r, gpuAntes: g.lidas, foraDoMetodo: g.fora, errosNoLog: erros.slice(0, 5) }); res.push(b);
    console.log(`${v} r${r}: ${b.fpsMedio} fps | ${b.msMedio} ms | 1%low ${b.fps1pctLow} | prim ${b.primVisivel}/${b.primSombra} | draw ${b.drawVisivel}/${b.drawSombra} | gpu antes ${g.lidas}${g.fora ? ' (FORA DO METODO)' : ''} | erros ${erros.length}`);
    writeFileSync(SAIDA, JSON.stringify(res, null, 1));
  }
} finally { solta(); }
console.log('--- medianas (vista ' + VISTA + ')');
const base = mediana(res.filter((x) => x.variante === 'base').map((x) => x.msMedio));
for (const v of VARIANTES) {
  const xs = res.filter((x) => x.variante === v); if (!xs.length) continue;
  const f = mediana(xs.map((x) => x.fpsMedio)), ms = mediana(xs.map((x) => x.msMedio));
  console.log(`${v}: fps [${xs.map((x) => x.fpsMedio).join(', ')}] mediana ${f} | ms mediana ${ms} | custo ${(ms - base).toFixed(3)} ms vs base | fora do metodo ${xs.filter((x) => x.foraDoMetodo).length}/${xs.length}`);
}
