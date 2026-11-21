extends Node
# Personagem: recurso nativo, StandardMaterial3D com difusa "Lambert Wrap" (luz que envolve) e cor de vértice; não some.
# O "distance fade" com pontilhado do StandardMaterial3D some pela distância da CÂMERA, não pela falta de luz: não equivale.

const NOME := "Personagem: Lambert Wrap nativo (não some)"
const EXCLUSIVO := true
const VISTA := "bonecos"
const B := preload("../comum/bonecos.gd")

var feitos := []

func ligar(c: Node3D) -> void:
	feitos = B.aplicar(c.bonecos, func(o: BaseMaterial3D, _mi: MeshInstance3D) -> Material:
		var m := o.duplicate() as BaseMaterial3D
		m.diffuse_mode = BaseMaterial3D.DIFFUSE_LAMBERT_WRAP  # envolve conforme a rugosidade (1 = envolve o máximo)
		m.roughness = 1.0
		m.vertex_color_use_as_albedo = true  # textura x cor de vértice, como o shader VSTools do Three
		return m)

func desligar() -> void:
	B.devolver(feitos)
	feitos = []
