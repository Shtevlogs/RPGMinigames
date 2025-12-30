class_name BerserkerMinigameContext
extends MinigameContext

var effect_ranges: Array = []  # Array of effect ranges (structure TBD in backlog item 06)
var is_berserking: bool = false
var berserk_stacks: int = 0

func _init(p_character: Character = null, p_target: Variant = null, p_effect_ranges: Array = [], p_is_berserking: bool = false, p_berserk_stacks: int = 0):
    super._init(p_character, p_target)
    effect_ranges = p_effect_ranges
    is_berserking = p_is_berserking
    berserk_stacks = p_berserk_stacks

