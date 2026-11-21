# Porte da sala do Vagrant (Three.js → Godot 4.7.2)

Porte 1:1 da cena `sala-fechada.html` (Three.js r117) para o Godot 4.7.2, para comparar os dois motores com números.

- Diário com cada etapa e as medições contra a página: `RESULTADO.md`.
- Cena: `main.tscn` + `vagrant.gd`; nós `Bonecos`, `CameraOrbita`, `Luzes`, `Portas`, `Rio`, `Efeitos` e `MenuOpcoes`.
- Rodar: `godot --path . -- [--caso=1] [--saida=arq.json] [--png=arq.png]`; sem `--saida`, abre e roda solto.
  Testes da linha de comando: `--andar=cx,cz`, `--segurar=W,s`, `--pular`, `--acao=golpe|fogo|raio`, `--tocha`, `--fixa`, `--porta`, `--peso=leve|medio|pesado`, `--controle`, `--rio`, `--opcoes`, `--efeitos-teste`.
- Teclas: WASD anda, Shift corre, Espaço pula, K golpe, F fogo, R raio, T tocha na mão, E porta/tocha fixa/troca, Q troca, P peso, F1 menu. Controle: mapa padrão Xbox/PlayStation.
- `export/` foi gerado da página pelos scripts `exportar-*.mjs`. Os modelos e texturas dos personagens vêm de Vagrant Story (Square Enix), usados aqui só para estudo técnico.
- `efeitos/`: shaders de terceiros, cada um com `ORIGEM.md` e a licença do autor.
