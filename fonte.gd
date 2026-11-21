class_name Fonte
extends RefCounted
## Uma fonte de luz da sala-fechada.html (sala-fechada.html:1601): tocha fixa, clarão ou tocha na mão.
## A lista de fontes decide quais 2 fazem sombra e o que o shader dos bonecos e a fumaça recebem.

enum Tipo { TOCHA, CLARAO, LEVA }

const PRIO := {Tipo.TOCHA: 0, Tipo.LEVA: 1, Tipo.CLARAO: 2}  # clarão primeiro, depois tocha na mão, depois as fixas

var tipo: Tipo
var luz: OmniLight3D
var cor: Color                 # valor bruto do Three (uniform sem conversão de cor)
var alcance: float
var intensidade := 0.0         # o I da página: força x tremor, ou a queda do clarão
var forca := 0.0
var apagada := false           # tocha fixa apagada (tecla E perto dela, sala-fechada.html:980)
var braseiro := false
var brasas: CPUParticles3D
var fase := 0.0                # fase do tremor
# tocha fixa e tocha na mão
var chama_sprite: MeshInstance3D
var halo: MeshInstance3D
var tamanho := 0.0
# clarão
var pico := 0.0
var duracao := 0.0
var pulsos := 1
var tempo := 0.0
# tocha na mão
var ligada := false
var braco := 0.0
var lado := 1
var modelo: Node3D             # cabo e copo
var chama := Vector3.ZERO
var escudo: Node3D
var faiscas: CPUParticles3D

func _init(t: Tipo, l: OmniLight3D, c: Color, a: float) -> void:
	tipo = t
	luz = l
	cor = c
	alcance = a

func prioridade() -> int:
	return PRIO[tipo]
