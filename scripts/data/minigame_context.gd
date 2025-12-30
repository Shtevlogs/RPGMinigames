class_name MinigameContext
extends RefCounted

var character: Character = null
var target: Variant = null  # Character or EnemyData

func _init(p_character: Character = null, p_target: Variant = null):
    character = p_character
    target = p_target

