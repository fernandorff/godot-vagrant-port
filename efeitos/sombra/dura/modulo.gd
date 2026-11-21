extends Node
# Sombra dura: filtro de sombra do Godot no modo "hard" (sem suavizar), como o sombras=dura da página.

const NOME := "Sombra dura (filtro nativo HARD)"
const EXCLUSIVO := true
const VISTA := "braseiro"

func ligar(_cena: Node3D) -> void:
	RenderingServer.positional_soft_shadow_filter_set_quality(RenderingServer.SHADOW_QUALITY_HARD)
	RenderingServer.directional_soft_shadow_filter_set_quality(RenderingServer.SHADOW_QUALITY_HARD)

func desligar() -> void:  # volta ao padrão da cena (SOFT_HIGH, vagrant.gd)
	RenderingServer.positional_soft_shadow_filter_set_quality(RenderingServer.SHADOW_QUALITY_SOFT_HIGH)
	RenderingServer.directional_soft_shadow_filter_set_quality(RenderingServer.SHADOW_QUALITY_SOFT_HIGH)
