extends Node
# Penumbra que alarga (PCSS) nativa: light_size nas luzes de ponto. Com light_size > 0 o Godot busca a distância de quem
# bloqueia e alarga a borda com ela (documentação de Light3D.light_size). Na página: PCSS_LUZ 0.4 = raio da tocha em tiles.

const NOME := "Penumbra que alarga (PCSS nativo, light_size)"
const EXCLUSIVO := true
const VISTA := "braseiro"
const TAMANHO := 0.4  # tiles; --pcss=X na linha de comando muda (calibração)

var antes := {}

func ligar(cena: Node3D) -> void:
	var tam := TAMANHO
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--pcss="): tam = float(a.substr(7))
	for l in cena.luzes:
		antes[l] = l.light_size
		l.light_size = tam

func desligar() -> void:
	for l in antes:
		if is_instance_valid(l): l.light_size = antes[l]
	antes.clear()
