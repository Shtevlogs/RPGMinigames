class_name WildMageMinigameContext
extends MinigameContext

var pre_drawn_card: Variant = null  # Card from basic attack state
var hand_size: int = 4
var discards_available: int = 0

func _init(p_character: CharacterBattleEntity = null, p_target: BattleEntity = null, p_pre_drawn_card: Variant = null, p_hand_size: int = 4, p_discards_available: int = 0):
    super._init(p_character, p_target)
    pre_drawn_card = p_pre_drawn_card
    hand_size = p_hand_size
    discards_available = p_discards_available

