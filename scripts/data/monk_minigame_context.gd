class_name MonkMinigameContext
extends MinigameContext

var target_strategy: int = 0
var enemy_cards: Array = []  # Array of EnemyCard (from MonkMinigame.EnemyCard)
var enemy_id: String = ""
var redos_available: int = 0

func _init(p_character: Character = null, p_target: Variant = null, p_target_strategy: int = 0, p_enemy_cards: Array = [], p_enemy_id: String = "", p_redos_available: int = 0):
    super._init(p_character, p_target)
    target_strategy = p_target_strategy
    enemy_cards = p_enemy_cards
    enemy_id = p_enemy_id
    redos_available = p_redos_available

