class_name BaseMinigame
extends Control

# Base class for all minigames
# Provides common interface for minigame integration

signal minigame_completed(result: MinigameResult)

var character: CharacterBattleEntity = null
var target: Variant = null
var minigame_context: Dictionary = {}

func _ready() -> void:
    # Get context from StateManager only if not already set
    # This allows context to be set directly (e.g., from modal)
    if character == null:
        var context: Dictionary = StateManager.get_minigame_context()
        if not context.is_empty():
            character = context.get("character")
            target = context.get("target")
            minigame_context = context.get("data", {})
    
    initialize_minigame()

func initialize_minigame() -> void:
    # Override in subclasses
    pass

func complete_minigame(result: MinigameResult) -> void:
    minigame_completed.emit(result)
    # Modal will handle closing and returning to combat

# Static method to build context for this minigame type
# Override in subclasses to build class-specific context
static func build_context(_character: CharacterBattleEntity, _target: BattleEntity) -> Dictionary:
    push_error("build_context() must be implemented in subclass")
    return {}

# Format minigame result for logging
# Override in subclasses to provide class-specific formatting
func format_result(_result: MinigameResult) -> Array[String]:
    # Default: no special formatting
    return []
