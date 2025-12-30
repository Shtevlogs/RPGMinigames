class_name VFXConfig
extends RefCounted

var scale: float = 1.0
var color: Color = Color.WHITE
var duration: float = 1.0
var rotation: float = 0.0

func _init(p_scale: float = 1.0, p_color: Color = Color.WHITE, p_duration: float = 1.0, p_rotation: float = 0.0):
    scale = p_scale
    color = p_color
    duration = p_duration
    rotation = p_rotation

