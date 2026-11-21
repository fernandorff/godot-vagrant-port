extends Node
# VoxelGI: luz indireta assada em voxels na hora de ligar (VoxelGI.bake é exposto ao script), cobrindo a parte da sala perto da câmera.

const NOME := "Luz indireta: VoxelGI (assa ao ligar)"
const EXCLUSIVO := true
const VISTA := "braseiro"

const CAIXA_MIN := Vector3(-2, -1, -2)
const CAIXA_MAX := Vector3(46, 13, 92)

func ligar(cena: Node3D) -> void:
	var gi := VoxelGI.new()
	gi.subdiv = VoxelGI.SUBDIV_256
	gi.size = CAIXA_MAX - CAIXA_MIN
	gi.position = (CAIXA_MIN + CAIXA_MAX) * 0.5
	add_child(gi)
	var t0 := Time.get_ticks_msec()
	gi.bake(cena.sala)  # assa só a sala (bonecos animados ficam de fora; recebem a luz indireta mesmo assim)
	print("luz-assada/voxelgi: assado em ", Time.get_ticks_msec() - t0, " ms")

func desligar() -> void:
	pass
