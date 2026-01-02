extends Node

# DelayManager - Centralized delay/timing system for combat
# Provides configurable delay durations and async wait methods

# Delay Constants
const ACTION_MENU_BEAT_DURATION: float = 0.3
const MINIGAME_OPEN_BEAT_DURATION: float = 0.4
const MINIGAME_CLOSE_BEAT_DURATION: float = 0.4
const TARGET_SELECTION_ARROW_DELAY: float = 0.2
const TURN_HIGHLIGHT_DURATION: float = 0.3
const ENEMY_ACTION_ANIMATION_DURATION: float = 0.5
const ATTACK_ANIMATION_DURATION: float = 0.6
const DEATH_ANIMATION_DURATION: float = 0.8
const VICTORY_MESSAGE_DELAY: float = 0.5
const DEFEAT_MESSAGE_DELAY: float = 0.5
const ENCOUNTER_MESSAGE_DELAY: float = 1.0

func wait(duration: float) -> void:
    """Wait for specified duration. Must be called with await."""
    await get_tree().create_timer(duration).timeout

func wait_for_animation(_animation_node: Node) -> void:
    """Wait for animation completion via signals. Must be called with await."""
    # TODO: Implement animation completion detection
    # For now, use a default delay
    await get_tree().create_timer(0.5).timeout
