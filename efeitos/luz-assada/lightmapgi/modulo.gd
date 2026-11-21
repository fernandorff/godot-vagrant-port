extends Node
# LightmapGI: luz indireta das 14 tochas/braseiros assada em textura (assada.lmbake/.exr, assada no editor, ver RESULTADO.md).
# Troca a sala da cena por uma cópia do mesmo sala.glb importada com UV2 (o lightmap precisa de UV2; o sala.glb comum não tem).

const NOME := "Luz indireta: LightmapGI (assada)"
const EXCLUSIVO := true
const VISTA := "braseiro"

var _sala: Node3D

func ligar(cena: Node3D) -> void:
	var cena_assada: PackedScene = load(get_script().resource_path.get_base_dir() + "/assada.tscn")
	if cena_assada == null:
		push_error("luz-assada/lightmapgi: assada.tscn não carrega (projeto importado?)")
		return
	var inst := cena_assada.instantiate()
	for n in inst.get_children():
		if n is OmniLight3D: n.free()  # as luzes do bake são cópias das da cena; a luz direta continua vindo de cena.luzes
	for n in inst.find_children("*", "", true, false):  # mesma visibilidade, camada e sombra que o vagrant.gd dá à sala comum
		var o: Node = cena.nos.get(String(n.name))
		if o == null or o is not Node3D or n is not Node3D: continue
		n.visible = o.visible
		if n is GeometryInstance3D and o is GeometryInstance3D:
			n.layers = o.layers
			n.cast_shadow = o.cast_shadow
			n.custom_aabb = o.custom_aabb
		if n is MeshInstance3D and n.mesh != null:
			for i in n.mesh.get_surface_count():
				var m = n.mesh.surface_get_material(i)
				if m is BaseMaterial3D: m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
	add_child(inst)
	_sala = cena.sala
	_sala.visible = false

func desligar() -> void:
	if _sala: _sala.visible = true
