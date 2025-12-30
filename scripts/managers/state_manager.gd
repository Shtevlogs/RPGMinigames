extends Node

# NOTE: This is an autoload singleton. Do not add class_name.
# Autoload singletons are accessed globally by their autoload name (StateManager).
# Adding class_name to autoload singletons can cause conflicts and is unnecessary.

# StateManager - Manages game state during transitions
# Stores temporary state data for scene transitions

var transition_data: Dictionary = {}
var encounter_state: Dictionary = {}
var combat_state: Dictionary = {}
var minigame_context: Dictionary = {}

func _ready() -> void:
    pass

func set_transition_data(data: Dictionary) -> void:
    transition_data = data

func get_transition_data() -> Dictionary:
    var data = transition_data.duplicate()
    transition_data.clear()
    return data

func set_encounter_state(state: Dictionary) -> void:
    encounter_state = state

func get_encounter_state() -> Dictionary:
    return encounter_state.duplicate()

func set_combat_state(state: Dictionary) -> void:
    combat_state = state

func get_combat_state() -> Dictionary:
    return combat_state.duplicate()

func set_minigame_context(context: Dictionary) -> void:
    minigame_context = context

func get_minigame_context() -> Dictionary:
    return minigame_context.duplicate()

func clear_all_state() -> void:
    transition_data.clear()
    encounter_state.clear()
    combat_state.clear()
    minigame_context.clear()
