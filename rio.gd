class_name Rio
extends Node
## O rio da planta mundo (planta-mundo.js:330-399): o shader do rio do Three (rio.gdshader, cópia do efeitos/agua/nativo)
## no nó n184, com os anéis dos pés de quem está na água (respingos(): entrar = anel forte; andando = 0,6 a cada 0,3 s;
## parado = 0,25 a cada 1,3 s). shortcut: sem as 160 gotas que saltam do pé; trocar se a água parecer parada demais.

const C := preload("res://efeitos/agua/comum/agua_comum.gd")

var bonecos: Bonecos
var no_rio: MeshInstance3D
var mat: ShaderMaterial
var aneis := C.Aneis.new()

func montar(nos: Dictionary, b: Bonecos, meta: Dictionary, cor_three: bool) -> void:
	bonecos = b
	no_rio = nos.get("n184") as MeshInstance3D
	if no_rio == null:
		push_error("rio: nó n184 não encontrado")
		return
	var h: Dictionary = meta.HORA
	var s: Dictionary = meta.sol
	mat = ShaderMaterial.new()
	mat.shader = load("res://rio.gdshader")  # cópia do efeitos/agua/nativo, com a saída bruta opcional
	mat.set_shader_parameter("cru", cor_three)
	mat.set_shader_parameter("zen", _rgb(Color(h.zen)))
	mat.set_shader_parameter("hor", _rgb(Color(h.hor)))
	mat.set_shader_parameter("solCor", Vector3(h.sol[0], h.sol[1], h.sol[2]) * float(h.si))
	mat.set_shader_parameter("solDir", (Vector3(s.pos[0], s.pos[1], s.pos[2]) - Vector3(s.alvo[0], s.alvo[1], s.alvo[2])).normalized())
	mat.set_shader_parameter("ceuI", float(h.ci))
	no_rio.material_override = mat

func _process(dt: float) -> void:
	if mat == null: return
	var pes := []
	for u in bonecos.unidades: pes.append(u.no.position)
	aneis.atualizar(dt, pes, Grade.molha)
	mat.set_shader_parameter("tempo", aneis.tempo)
	mat.set_shader_parameter("aneis", aneis.slots)

static func _rgb(c: Color) -> Vector3:
	return Vector3(c.r, c.g, c.b)
