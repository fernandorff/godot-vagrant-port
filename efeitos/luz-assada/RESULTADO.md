# Luz assada / luz indireta: candidatos no Godot 4.7.2 (20/11/2026, agente A)

Origem: **[medido]** = rodado nesta sessão; **[documentação: link]**; **[dedução]** = não provado.

## Assar o LightmapGI por linha de comando: não dá

- O `LightmapGI` do 4.7.2 **não tem método `bake`** exposto ao script (lista do `ClassDB` impressa: só set/get de propriedades) [medido]. Tentativa real em `--headless --script`:
  `SCRIPT ERROR: Invalid call. Nonexistent function 'bake (via call)' in base 'LightmapGI'.` [medido]
- Confirma o relato do fórum (4.5.1, mesma limitação): https://forum.godotengine.org/t/is-it-possible-to-bake-lightmapgi-node-using-headless-godot-editor/129607 [documentação]
- O `sala.glb` comum **não tem UV2** (0 de 193 malhas) [medido]; o lightmap precisa de UV2 [documentação: https://docs.godotengine.org/en/4.7/tutorials/3d/global_illumination/using_lightmap_gi.html].

### Como assei mesmo assim (uma tentativa, projeto separado no scratchpad)

1. Cópia do `sala.glb` como `lightmapgi/sala-uv2.glb`, importada com "Light Baking: Static Lightmaps" (gera UV2: 191 de 193 malhas) [medido].
2. Cena `assada.tscn`: sala + as 14 luzes iguais às do `vagrant.gd` (modo de bake Dinâmico = só a luz indireta é assada; a direta segue em tempo real) + `LightmapGI` (qualidade baixa, interior, sem ambiente).
3. Editor aberto **com janela** (fora da tela) e um plugin temporário que seleciona o `LightmapGI`, aperta o botão "Gerar Lightmaps" e responde o diálogo de salvar. Assou em **8,9 s** (`Done baking lightmaps in 00:00:08.89`) [medido]. Saída: `assada.lmbake` (39 KB) + `assada.exr` (6,2 MB).
4. Copiado para `efeitos/luz-assada/lightmapgi/` (com o `unwrap_cache`, para o UV2 sair igual) e importado no projeto comum (`--headless --import`, com o lock).

Ou seja: **headless não**; **automático sim**, desde que o editor abra janela (precisa de placa de vídeo).

## Tabela

| Efeito | Candidato | Origem/URL | Licença | Popularidade | Funciona no 4.7.2? | fps e custo vs base (vista braseiro) | Semelhança 0-5 | Usar? Por quê |
|---|---|---|---|---|---|---|---|---|
| Luz indireta | `lightmapgi`: luz indireta assada (troca a sala por uma cópia com UV2) | motor, https://docs.godotengine.org/en/4.7/tutorials/3d/global_illumination/using_lightmap_gi.html | MIT (motor) | motor Godot, 120.490 estrelas (API GitHub, 20/11) | Assar: só pelo editor (acima). Rodar: sim, sem erro no log [medido] (a 1ª versão do `modulo.gd` tinha erro de tipo, corrigido antes das rodadas que valem) | fps 667,76 / 624,13 / 657,90, mediana 657,90; custo −0,02 ms (dentro do ruído) [medido] | sem nota | **Inconclusivo: a cópia da sala não é igual à original.** Comparando nó a nó (221 nós nos dois, nenhum nome repetido), 2 malhas grandes perderam triângulos ao importar com UV2: `n179` 32.634 → 27.792 índices e `n182` 111.600 → 97.920 [medido]; a soma (6.174 triângulos) é exatamente a diferença de primitivas da medição (72.037 vs 65.863) [medido]. Com isso o piso perto do braseiro saiu **5% mais escuro** que a base (11,04 vs 11,63 de 255) [medido], o que não dá para atribuir à luz assada. Também esconde `cena.sala`: efeitos de outros grupos que mexem na sala ou em `cena.nos` (ex.: o rio) não aparecem com ele ligado. |
| Luz indireta | `voxelgi`: VoxelGI 256, assado ao ligar (`VoxelGI.bake()` é exposto) | motor, https://docs.godotengine.org/en/4.7/tutorials/3d/global_illumination/using_voxel_gi.html | MIT (motor) | idem | Sim, sem erro; assa em 1,5 a 1,6 s ao ligar [medido] | fps 676,00 / 437,83 / 631,30, mediana 631,30; custo +0,04 ms (ruído) [medido] | 2 | Talvez: é o que mais clareia o piso perto do fogo (11,63 → 12,30, +6%) [medido] e assa sozinho em tempo de jogo, sem editor. Efeito pequeno porque as tochas são fracas (energia 0,35 da calibração da etapa 1) [dedução]. |
| Luz indireta | `sdfgi`: SDFGI em tempo real (Environment) | motor, https://docs.godotengine.org/en/4.7/tutorials/3d/global_illumination/using_sdfgi.html | MIT (motor) | idem | Sim, sem erro [medido] | fps 657,23 / 622,79 / 531,40, mediana 622,79; custo +0,07 ms (ruído) [medido] | 1 | Talvez: na vista braseiro quase igual à base (piso 11,67 vs 11,63) [medido], mas na vista padrão é o que mais muda (brilho 0,76 → 1,07): os bonecos, que na base são silhuetas, aparecem com a capa clara e partes do corpo iluminadas [medido, olhando o print]. Aparecem manchas claras soltas perto das colunas no print do braseiro. |

Semelhança: comparada com o print do Three da etapa 1 (`godot-vagrant/print-three.png`) e com a referência de braseiro (`dungeon-tactics-labs/.../mundo-referencias/existente/05-fumaca-no-braseiro.png`), onde paredes e chão perto do fogo são bem mais claros e amarelados. Nenhum dos três chega lá; a diferença principal é a calibração de luz e cor (etapa 1), não a luz indireta [dedução].

## Medição [medido]

Mesma execução da fumaça: `efeitos/fumaca/medicao-braseiro.json`, base mediana 650,85 fps (1,54 ms; essa mediana é a rodada 1, medida com a placa a 52-58% antes, fora do método). Ruído entre rodadas de até ~25% (VoxelGI: 676 → 438): os custos acima são todos menores que o ruído. Ver ressalvas em `efeitos/fumaca/RESULTADO.md`.

## Prints (1280x720)

`efeitos/luz-assada/imagens/<candidato>-braseiro.png` e `-padrao.png`, mais `base-*.png` (cópia da base da fumaça). Brilho médio (0-255) braseiro / padrão: base 3,96 / 0,76; SDFGI 4,03 / 1,07; VoxelGI 4,19 / 1,02; LightmapGI 3,85 / 0,74 [medido]. Olhando: os quatro parecem quase iguais; o VoxelGI deixa o chão um pouco mais visível em volta do braseiro.

## Dúvidas abertas

- Por que a importação com UV2 tira triângulos de `n179` e `n182` (dedução: o desdobramento do UV2 junta/descarta triângulos degenerados ou refaz as normais). Próximo passo: assar só com essas 2 malhas fora do lightmap (`gi_mode` desligado) ou gerar o UV2 no export do Three.
- Ligar, desligar e ligar de novo pelo menu: **não testado** (só `--efeitos` na partida), para os 3 candidatos.
- Testar luzes em modo **Estático** no bake (direta + indireta assadas, como a "luz assada" costuma ser) [documentação: link acima]: teria de mudar o modo das luzes da cena no `ligar` e devolver no `desligar`.
- Assar exige rodar o editor com janela; para o pipeline automático, os dois scripts usados estão guardados como texto (para o Godot não carregar) em `lightmapgi/assar-plugin.gd.txt` (plugin do editor que aperta o botão) e `lightmapgi/montar-cena.gd.txt` (monta `assada.tscn`); rodam num projeto separado, com `[editor_plugins]` ligado só lá.
