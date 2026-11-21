class_name Efeitos
extends Node3D
## Os módulos de efeito dos candidatos (godot-candidatos/CONTRATO-MODULOS.md), ligados pelo menu F1 por cima da cena portada.
## Este nó é a "cena" que cada módulo recebe em ligar(): tem os campos da seção 3 do contrato, e os módulos ficam como filhos dele.

const RAIZ := "res://efeitos"

# campos do contrato (seção 3); a cena preenche antes de montar()
var ambiente: Environment
var camera: Camera3D
var luzes: Array[OmniLight3D] = []
var sol: DirectionalLight3D
var fogos: Array = []
var sala: Node3D
var bonecos: Node3D            # a raiz do bonecos.glb (no contrato não é o nó Bonecos)
var unidades: Array = []
var nos := {}
var meta: Dictionary
var claro := false

var modulos := {}              # "grupo/candidato" -> {caminho, grupo, nome, exclusivo}
var ativos := {}               # "grupo/candidato" -> nó do módulo ligado
var erros: Array[String] = []

func montar() -> void:
	for f: Dictionary in meta.fogos:
		fogos.append({"chama": Vector3(f.chama[0], f.chama[1], f.chama[2]), "forca": f.forca, "braseiro": f.braseiro, "apagada": f.apagada, "nome": f.nome})
	unidades = meta.unidades
	var d := DirAccess.open(RAIZ)
	if d == null: return
	for g in d.get_directories():
		for c in DirAccess.open(RAIZ + "/" + g).get_directories():
			var caminho := "%s/%s/%s/modulo.gd" % [RAIZ, g, c]
			if not FileAccess.file_exists(caminho): continue
			var s := load(caminho) as GDScript
			if s == null or not s.can_instantiate():
				erros.append(g + "/" + c)
				continue
			var k := s.get_script_constant_map()
			modulos[g + "/" + c] = {"caminho": caminho, "grupo": g, "nome": k.get("NOME", c), "exclusivo": k.get("EXCLUSIVO", true)}

func grupos() -> Array:
	var r := {}
	for k: String in modulos: r[modulos[k].grupo] = true
	var l := r.keys()
	l.sort()
	return l

func do_grupo(g: String) -> Array:
	var l := modulos.keys().filter(func(k: String) -> bool: return modulos[k].grupo == g)
	l.sort()
	return l

func ligar(chave: String) -> void:
	if ativos.has(chave) or not modulos.has(chave): return
	var info: Dictionary = modulos[chave]
	if info.exclusivo:  # no mesmo grupo, um exclusivo por vez
		for outro: String in ativos.keys():
			if modulos[outro].grupo == info.grupo and modulos[outro].exclusivo: desligar(outro)
	var m: Node = load(info.caminho).new()
	m.name = chave.replace("/", "__")
	add_child(m)
	m.ligar(self)
	ativos[chave] = m

func desligar(chave: String) -> void:
	if not ativos.has(chave): return
	var m: Node = ativos[chave]
	ativos.erase(chave)
	m.desligar()
	m.queue_free()

func desligar_exclusivos(g: String) -> void:
	for k: String in ativos.keys():
		if modulos[k].grupo == g and modulos[k].exclusivo: desligar(k)

## Entradas do menu: um grupo vira uma escolha (exclusivos + "desligado") e uma caixa por módulo não exclusivo.
func por_no_menu(menu: MenuOpcoes) -> void:
	if not erros.is_empty(): menu.titulo("Não carregaram: " + ", ".join(erros))
	for g: String in grupos():
		menu.titulo("Efeito: " + g)
		var textos := {"": "desligado"}
		for k: String in do_grupo(g):
			if modulos[k].exclusivo: textos[k] = modulos[k].nome
		if textos.size() > 1: menu.escolha(StringName("efeito:" + g), textos, "")
		for k: String in do_grupo(g):
			if not modulos[k].exclusivo: menu.caixa(StringName("efeito+:" + k), modulos[k].nome, false)

func opcao(chave: String, valor: Variant) -> void:  # o que o menu mandou para cá (chaves "efeito:..." e "efeito+:...")
	if chave.begins_with("efeito+:"):
		var k := chave.substr(8)
		if valor: ligar(k)
		else: desligar(k)
	else:
		desligar_exclusivos(chave.substr(7))
		if valor != "": ligar(valor)
