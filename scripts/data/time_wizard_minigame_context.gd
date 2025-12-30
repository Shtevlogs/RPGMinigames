class_name TimeWizardMinigameContext
extends MinigameContext

var board_state: Array = []  # Pre-cleared squares from basic attacks
var board_size: int = 4
var time_limit: float = 10.0
var event_count: int = 1

func _init(p_character: CharacterBattleEntity = null, p_target: BattleEntity = null, p_board_state: Array = [], p_board_size: int = 4, p_time_limit: float = 10.0, p_event_count: int = 1):
    super._init(p_character, p_target)
    board_state = p_board_state
    board_size = p_board_size
    time_limit = p_time_limit
    event_count = p_event_count

