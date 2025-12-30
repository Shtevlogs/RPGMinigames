class_name StatusEffect
extends RefCounted

var duration: int = 0  # turns remaining
var stacks: int = 1
var magnitude: float = 1.0  # For scaling effects
var target: Variant = null  # Reference to the entity (Character or EnemyData) this effect is applied to

# Virtual methods to be overridden by subclasses
func get_effect_name() -> String:
    # Return display name of effect
    push_error("get_effect_name() must be overridden in subclass")
    return "Unknown"

func can_stack() -> bool:
    # Return true if this effect can stack with itself
    push_error("can_stack() must be overridden in subclass")
    return false

func _matches_existing_effect(existing: StatusEffect) -> bool:
    # Determines if an existing effect should be considered a match for this new effect
    # Default implementation: match by script type (same class)
    # Child classes can override to provide custom matching logic (e.g., match by attribute type)
    # Returns true if the existing effect should be considered the same type as this effect
    return existing.get_script() == get_script()

func on_apply(p_target: Variant, status_effects_array: Array[StatusEffect]) -> void:
    # Called when effect is applied to a target
    # p_target: The entity (Character or EnemyData) this effect is being applied to
    # status_effects_array: The array of status effects on the target (for finding matches and appending)
    # Sets target reference, finds matching existing effect, updates it or appends self
    target = p_target
    
    # Find matching existing effect
    var existing_effect: StatusEffect = null
    for existing in status_effects_array:
        if _matches_existing_effect(existing):
            existing_effect = existing
            break
    
    # If found, update existing effect
    if existing_effect != null:
        if can_stack():
            existing_effect.stacks += stacks
            existing_effect.duration = max(existing_effect.duration, duration)
        else:
            existing_effect.duration = max(existing_effect.duration, duration)
    else:
        # If not found, append this effect to the array
        status_effects_array.append(self)

func on_tick(_combatant: Variant = null) -> Dictionary:
    # Called at start of each turn
    # _combatant: The entity (Character or EnemyData) - can use target property instead
    # Returns Dictionary with effects to apply (damage, etc.)
    # Return {"remove": true} to remove effect after processing
    # Note: Use target property if _combatant is null for backward compatibility
    return {}

func on_modify_attributes(_attributes: Attributes) -> void:
    # Called when calculating effective attributes
    # Allows status effects to modify attributes (e.g., AlterAttributeEffect)
    # Default implementation does nothing
    # Child classes can override to modify attributes
    pass

func tick() -> bool:
    # Decrements duration, returns true if should be removed
    duration -= 1
    return duration <= 0

func get_visual_data() -> Dictionary:
    # Return visual representation data (icon path, color, etc.)
    push_error("get_visual_data() must be overridden in subclass")
    return {
        "icon": "",
        "color": Color.WHITE,
        "show_stacks": false
    }

func duplicate() -> StatusEffect:
    # Create a copy of this effect
    push_error("duplicate() must be overridden in subclass")
    return null
