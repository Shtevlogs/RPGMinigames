class_name MinigameContext
extends RefCounted

var character: CharacterBattleEntity = null
var target: BattleEntity = null  # CharacterBattleEntity or EnemyBattleEntity

func _init(p_character: CharacterBattleEntity = null, p_target: BattleEntity = null):
    character = p_character
    target = p_target

