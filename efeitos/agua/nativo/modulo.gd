extends Node
# Água nativa: porte direto do shader do rio do Three (planta-mundo.js) no nó n184 + poça de demonstração sob os bonecos,
# com os anéis dos pés de respingos() (boneco parado = anel fraco a cada 1,3 s). Sem plugin, só shader do Godot.

const NOME := "Água nativa (porte do rio do Three + poça com anéis)"
const EXCLUSIVO := true
const VISTA := "rio"
const C := preload("../comum/agua_comum.gd")

var cena: Node3D
var rio: MeshInstance3D
var mat_rio: ShaderMaterial
var mat_poca: ShaderMaterial
var aneis_rio := C.Aneis.new()
var aneis_poca := C.Aneis.new()
var pes: Array = []

func ligar(c: Node3D) -> void:
	cena = c
	pes = C.pes(c)
	var H: Dictionary = c.meta.HORA
	var s: Dictionary = c.meta.sol
	mat_rio = ShaderMaterial.new()
	mat_rio.shader = load("res://efeitos/agua/nativo/rio.gdshader")
	mat_rio.set_shader_parameter("zen", _rgb(Color(H.zen)))
	mat_rio.set_shader_parameter("hor", _rgb(Color(H.hor)))
	mat_rio.set_shader_parameter("solCor", Vector3(H.sol[0], H.sol[1], H.sol[2]) * float(H.si))
	mat_rio.set_shader_parameter("solDir", (Vector3(s.pos[0], s.pos[1], s.pos[2]) - Vector3(s.alvo[0], s.alvo[1], s.alvo[2])).normalized())
	mat_rio.set_shader_parameter("ceuI", float(H.ci))
	rio = C.rio(c)
	if rio == null:
		push_error("agua/nativo: nó n184 (rio) não encontrado")
	else:
		rio.material_override = mat_rio
	mat_poca = ShaderMaterial.new()
	mat_poca.shader = load("res://efeitos/agua/nativo/poca.gdshader")
	C.criar_poca(self).material_override = mat_poca

func desligar() -> void:
	if rio != null and rio.material_override == mat_rio:
		rio.material_override = null

func _process(dt: float) -> void:
	aneis_rio.atualizar(dt, pes, C.no_rio)
	aneis_poca.atualizar(dt, pes, C.na_poca)
	mat_rio.set_shader_parameter("tempo", aneis_rio.tempo)
	mat_rio.set_shader_parameter("aneis", aneis_rio.slots)
	mat_poca.set_shader_parameter("tempo", aneis_poca.tempo)
	mat_poca.set_shader_parameter("aneis", aneis_poca.slots)

func _rgb(c: Color) -> Vector3:
	return Vector3(c.r, c.g, c.b)
