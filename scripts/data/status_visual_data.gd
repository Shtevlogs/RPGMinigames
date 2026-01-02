class_name StatusEffectVisualData
extends RefCounted

var icon: String
var color: Color
var show_stacks: bool

func _init(p_icon: String, p_color: Color, p_show_stacks: bool):
    icon = p_icon
    color = p_color
    show_stacks = p_show_stacks