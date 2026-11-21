# Chamas, halos e brasas: candidatos testados (20/11/2026)

Origem: **[medido]** = rodado hoje nesta pasta; **[documentação: link]**; **[dedução]** = não provado.
Godot 4.7.2, Forward+, RTX 5070, 1280x720. Vista `braseiro`: câmera em (21; 6,5; 21) olhando o braseiro aceso em (29; 2,95; 13).
A câmera da etapa 1 (`padrao`) não mostra nenhuma chama acesa: os prints `*-padrao.png` e `*-padrao-claro.png` dos dois
candidatos são idênticos pixel a pixel à base (diferença 0,0) [medido]. Por isso a vista extra.

## Tabela

| Efeito | Candidato | Origem/URL | Licença | Popularidade | Funciona no 4.7.2? | fps (mediana de 3) e custo | Semelhança 0-5 | Usar? |
|---|---|---|---|---|---|---|---|---|
| Chama + halo + brasas | **Nativo** (`particulas-nativo`): quadrado virado para a câmera com o degradê da página + GPUParticles3D, 10 brasas por fogo | recursos do próprio Godot; cópia do desenho da página (sala-fechada.html 616-647, 982-988) | do motor (MIT) | n/a | **sim, sem erro** [medido] | 678,6 fps; +0,12 ms vs base 740,4 (1,35 ms) [medido, ruído alto, ver abaixo] | **4** | **Usar.** É o mesmo desenho do original, custa pouco e não depende de terceiros |
| Chama | Shader de tocha (`tocha-godotshaders`), CaptainLaptop | https://godotshaders.com/shader/procedural-torch-candle-shader-fire-smoke-sparks/ | CC0 / MIT | 37 curtidas; publicado 19/10/2025, alterado 06/11/2026 [lido na página hoje] | **sim, sem erro** [medido] (é shader 2D: rodou num SubViewport, ver ORIGEM.md) | 712,5 fps; +0,05 ms [medido, dentro do ruído] | **2** | Não usar como chama da sala: estilo diferente (língua de fogo fina e alta, fumaça clara). Serve para vela |
| Chama | PYROLUX Lite (gennai) | https://store.godotengine.org/asset/gennai/pyrolux-lite-fire-explosion-vfx/ | "PYROLUX Lite License": grátis, **proibido redistribuir** (não é permissiva) | loja: 0 avaliações, sem contagem de downloads; versão 1.0.3 marcada "unstable"; atualizado 23/10/2026; testado pelo autor no 4.4.1 e 4.7.2 [lido na loja hoje] | **não testado** | — | — | Ver "não testado" |
| Chama/fumaça | Stylized 3D Fire and Smoke VFX (knowercoder) | itch.io | MIT (busca anterior, não conferido) | — | **não testado** | — | — | itch.io não está entre as fontes aceitas; a pasta em `baixados/` estava vazia |

## Imagens (olhei cada uma)

Em `imagens/`: `three-braseiro.png` (original, mesma câmera: conferida, posição igual até 1e-5), `base-braseiro*.png`,
`particulas-nativo-braseiro*.png`, `tocha-godotshaders-braseiro*.png` (`-claro` = luz clara de diagnóstico).

- **Original (Three):** bola de fogo amarela e branca no centro, pequena, sobre a bacia; brilho alaranjado suave em volta; fumaça
  dos braseiros subindo (é outro efeito, grupo fumaça).
- **Nativo:** a mesma bola amarela e branca no mesmo lugar e tamanho, halo alaranjado em volta e brasas subindo. Diferenças: a borda
  do quadrado da chama aparece como um disco levemente marcado; o núcleo é um pouco menos estourado que no Three. O halo da página
  (opacidade 0,22) ficou forte demais no Godot (o Godot converte a saída para sRGB e o three r117 não): calibrei para 0,05 olhando o
  lado a lado [medido nos prints; causa: dedução, a mesma da etapa 1].
- **Shader de tocha:** chama alta e fina, pixelada, laranja e vermelha, com uma nuvem clara em cima (a fumaça do shader fica clara
  porque o quadrado é aditivo). Bonita, mas não lembra a bola de fogo do Vagrant. Na luz clara a fumaça some.
- Na câmera da etapa 1 (`padrao`) nenhum dos dois aparece (não há chama acesa no quadro).

## Fps [medido]

`node medir.mjs --vista braseiro --rodadas 3 --efeitos "base;chamas/particulas-nativo;chamas/tocha-godotshaders;..."`,
`medicoes/chamas-sombra-braseiro.json` e `.log`. 1280x720 fora da tela, vsync desligado, 2 s + 10 s, rodadas intercaladas.

| Variante | r1 | r2 | r3 | Mediana | ms (mediana) | Custo vs base |
|---|---|---|---|---|---|---|
| base | 740,38 | 782,96 | 581,90 (placa ocupada antes) | 740,38 | 1,35 | — |
| nativo | 730,02 | 678,55 | 657,68 (placa 10%) | 678,55 | 1,47 | +0,12 ms |
| shader de tocha | 741,66 | 712,46 | 613,58 (placa 10-11%) | 712,46 | 1,40 | +0,05 ms |

**Ressalva:** a base variou 200 fps entre rodadas (582 a 783). Na rodada 3 a placa estava acima de 5% antes de começar
(RustDesk codificando vídeo, ~12% da placa, e Edge); o driver mediu assim mesmo e marcou "fora do método". Custos abaixo de ~0,2 ms
estão dentro desse ruído: a conclusão segura é "os dois custam pouco", não a ordem entre eles.

## Não testado e por quê

- **PYROLUX Lite:** o zip que um agente anterior deixou em `baixados/` não tinha origem comprovável (sha256
  `ac9e3377...b9ab99d`, 55.484 bytes; a loja anuncia 56,82 KB). Baixar de novo na loja oficial exige concordar com os termos da loja
  ("By downloading this asset, you agree to the terms"), o que pede o sim do Fernando. O zip foi para
  `D:\_PARA-APAGAR\godot-candidatos-baixados\pyrolux-lite\` (com POR-QUE.txt); só o Fernando apaga. A licença também proíbe redistribuir,
  então não poderia ir para um repositório público.
- **knowercoder (itch.io):** fonte fora das aceitas (GitHub do autor, Asset Library, godotshaders.com); pasta vazia.
