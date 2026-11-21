# Fumaça: candidatos no Godot 4.7.2 (20/11/2026, agente A)

Origem: **[medido]** = rodado nesta sessão; **[documentação: link]**; **[dedução]** = não provado.

## Tabela

| Efeito | Candidato | Origem/URL | Licença | Popularidade | Funciona no 4.7.2? | fps e custo vs base (vista braseiro) | Semelhança 0-5 | Usar? Por quê |
|---|---|---|---|---|---|---|---|---|
| Fumaça | `nevoa-nativa`: névoa volumétrica nativa do Environment, densidade 0,03 em tudo | motor (`Environment.volumetric_fog_*`), https://docs.godotengine.org/en/4.7/tutorials/3d/volumetric_fog.html | MIT (motor) | motor Godot, 120.490 estrelas, push 20/11/2026 (API GitHub, lida 20/11) | Sim, sem erro no log [medido] | fps 652,98 / 503,05 / 667,00, mediana 652,98; custo −0,01 ms (dentro do ruído) [medido] | 1 | Não como fumaça: é uma neblina avermelhada uniforme que lava a sala inteira (brilho médio do print 4 → 32 de 255) [medido]; sem pluma, sem fiapos. Serve só como "ar pesado" de fundo. |
| Fumaça | `fogvolume-ruido`: FogVolume com porte da `densidade()` do fumaca.js (camada rasteira + pluma por fogo aceso + erosão por ruído) | próprio (porte de `dungeon-tactics-labs/.../vagrant/fumaca.js`), ver `fogvolume-ruido/ORIGEM.md` | do dono | n/a | Sim, sem erro no log [medido] | fps 593,59 / 603,11 / 504,77, mediana 593,59; custo +0,14 ms [medido] | 3 | **Sim, o melhor dos testados.** Camada no chão que se mexe, encobre os pés dos bonecos e acende perto do braseiro (luz das tochas somada pelo próprio motor). Falta: a pluma vira um borrão, sem os fiapos finos da referência, porque a grade da névoa do Godot é grossa (64x64x64 em 64 unidades) [dedução]. |
| Fumaça | `fogvolume-demo`: shader de névoa rasteira do demo oficial, só parâmetros mudados | https://github.com/godotengine/godot-demo-projects/releases/download/4.2-31d1c0c/3d_volumetric_fog.zip (Asset Library 2754) | MIT [documentação: API GitHub] | 9.818 estrelas, push 08/10/2026 (lida 20/11) | Sim, sem erro no log [medido] | fps 466,08 / 523,20 / 581,53, mediana 523,20; custo +0,37 ms [medido] | 2 | Não: névoa baixa bonita, mas não sabe dos fogos (sem pluma sobre o braseiro). Custo diferente do porte não está provado (os dois abaixo do ruído). Fica como base para quem quiser só névoa de chão. |
| Fumaça | `knowercoder-fire-smoke` (partículas + shader, "Stylized 3D Fire and Smoke VFX") | https://knowercoder.itch.io/3d-fire-and-smoke | MIT no código, segundo a página [documentação: página itch.io] | 1 avaliação (5,0) na itch.io (lida 20/11) | **Não testado** | — | — | A pasta `baixados\knowercoder-fire-smoke` está **vazia** e a itch.io respondeu `429 Too Many Requests` às 4 tentativas desta sessão (20:31 a 21:15) [medido]. Não baixei pelo navegador do dono (seria download pedindo o sim dele). |

**Item (c) incompleto:** fora o demo oficial, nenhum pacote de terceiros foi testado. O knowercoder não baixou (acima) e a busca por outros pacotes de fumaça na web **não foi feita**.

Ligar, desligar e ligar de novo pelo menu: **não testado** (só `--efeitos` na partida).

## Medição [medido]

- `node medir.mjs --quem "fumaca+luz-assada" --vista braseiro --rodadas 3 ...` → `efeitos/fumaca/medicao-braseiro.json` (os 7 casos de fumaça e luz assada na mesma execução, base intercalada em cada rodada). Base: 650,85 / 723,30 / 648,19, mediana 650,85 fps (1,54 ms); essa mediana é justamente a rodada 1, medida com a placa a 52-58% antes (fora do método).
- **O ruído é maior que os efeitos.** A mesma variante oscilou até 25% entre rodadas (névoa nativa: 667 → 503 fps). Custos abaixo de ~0,3 ms não são confiáveis com 3 rodadas. Placa acima de 5% antes de algumas rodadas (base r1 a 52-58%, demo r3 a 7-8%) → marcadas `foraDoMetodo`.
- A partir da rodada 2 rodou junto o `esconder-janela.ps1` pedido pelo coordenador (empurra a janela a cada 50 ms); pode ter somado ruído [dedução].
- Os logs em `medicoes/logs/` têm nomes que outros agentes também usam (`base-braseiro-r*.json`): os números válidos são os do `medicao-braseiro.json` acima.

## Prints (1280x720)

Em `efeitos/fumaca/imagens/`: `<candidato>-braseiro.png` e `<candidato>-padrao.png`, mais `base-*.png`.

- Referência usada para a nota: `D:\Projetos\dungeon-tactics-labs\web\public\content\vagrant\mundo-referencias\existente\05-fumaca-no-braseiro.png` (Three, fumaca.js ligado, câmera diferente: perto do braseiro). Lá a fumaça é uma coluna fina, cinza-azulada, iluminada de laranja, subindo do braseiro, quase sem névoa no chão.
- O que eu vi:
  - `nevoa-nativa`: tudo coberto por uma névoa marrom-avermelhada lisa; bonecos viram silhuetas; nenhuma forma.
  - `fogvolume-ruido`: manchas de névoa lilás no chão, que se mexem; um halo claro sobre o braseiro (a pluma), largo e borrado; os bonecos ficam com as pernas na névoa.
  - `fogvolume-demo`: faixa de névoa rosada à esquerda e no chão, mais lisa; nada sobre o braseiro.
- A câmera `padrao` é ~99% preta sem efeito (etapa 1); com fumaça fica bem mais clara (brilho médio 0,76 → 14,6 no porte, 15,0 no demo, 36,2 na nativa) [medido]. A cor é avermelhada porque a névoa de profundidade da cena (`#6e5a66`) soma por cima [dedução].

## Dúvidas abertas

- Fiapos finos: testar `RenderingServer.environment_set_volumetric_fog_volume_size(128, 128)` (estado global, teria de voltar em `desligar`) ou ruído mais grosso. Não testado.
- A emissão azulada (`ambiente`) do porte está chutada (energia 0,3), não calibrada contra o Three.
- Medir de novo com 5+ rodadas se o custo pequeno importar.
