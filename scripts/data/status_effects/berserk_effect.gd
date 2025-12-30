class_name BerserkEffect
extends StatusEffect

const ALTER_ATTRIBUTE_EFFECT = preload("res://scripts/data/status_effects/alter_attribute_effect.gd")

var berserk_stacks: int = 1  # Number of berserk stacks (1-10)
var power_effect_ref: StatusEffect = null  # Reference to the Power effect we created
var speed_effect_ref: StatusEffect = null  # Reference to the Speed effect we created

func _init(p_berserk_stacks: int = 1):
    berserk_stacks = min(p_berserk_stacks, 10)  # Cap at 10
    duration = 999  # Very long duration, persists until cleared
    stacks = 1
    magnitude = 1.0

func get_effect_name() -> String:
    return "Berserk x%d" % berserk_stacks

func can_stack() -> bool:
    return true  # Can stack to increase berserk_stacks

func _matches_existing_effect(existing: StatusEffect) -> bool:
    # Match other BerserkEffect instances
    return existing is BerserkEffect

func on_apply(p_target: Variant, status_effects_array: Array[StatusEffect]) -> void:
    # Call parent to handle matching and appending
    super.on_apply(p_target, status_effects_array)
    
    # If we found an existing effect, update its stacks
    var existing_effect: BerserkEffect = null
    for existing in status_effects_array:
        if existing is BerserkEffect and existing != self:
            existing_effect = existing as BerserkEffect
            break
    
    if existing_effect != null:
        # Stack: increment berserk_stacks (cap at 10)
        existing_effect.berserk_stacks = min(existing_effect.berserk_stacks + berserk_stacks, 10)
        # Update class_state
        _update_class_state(p_target, existing_effect.berserk_stacks)
        # Update Power/Speed effects (this will update the existing effect's references)
        _update_attribute_effects(p_target, existing_effect.berserk_stacks, existing_effect)
    else:
        # New effect: set up class_state and apply Power/Speed effects
        if p_target is Character:
            var character: Character = p_target as Character
            character.class_state["is_berserking"] = true
            character.class_state["berserk_stacks"] = berserk_stacks
            
            # Apply Power and Speed AlterAttributeEffects and store references
            power_effect_ref = ALTER_ATTRIBUTE_EFFECT.new("power", berserk_stacks, 999)
            speed_effect_ref = ALTER_ATTRIBUTE_EFFECT.new("speed", berserk_stacks, 999)
            character.add_status_effect(power_effect_ref)
            character.add_status_effect(speed_effect_ref)

func on_tick(_combatant: Variant = null) -> Dictionary:
    return {}  # No turn-based effects

func on_remove() -> void:
    # Called when effect is removed - clean up class_state and attribute effects
    if target is Character:
        var character: Character = target as Character
        character.class_state["is_berserking"] = false
        character.class_state["berserk_stacks"] = 0
        
        # Remove Power and Speed berserk effects using stored references
        if power_effect_ref != null and power_effect_ref in character.status_effects:
            character.status_effects.erase(power_effect_ref)
        if speed_effect_ref != null and speed_effect_ref in character.status_effects:
            character.status_effects.erase(speed_effect_ref)

func _update_class_state(p_target: Variant, num_stacks: int) -> void:
    """Update class_state with berserk information."""
    if p_target is Character:
        var character: Character = p_target as Character
        character.class_state["is_berserking"] = true
        character.class_state["berserk_stacks"] = num_stacks

func _update_attribute_effects(p_target: Variant, num_stacks: int, effect_to_update: BerserkEffect = null) -> void:
    """Update Power and Speed AlterAttributeEffects to match current stacks."""
    if not (p_target is Character):
        return
    
    var character: Character = p_target as Character
    
    # Determine which effect instance to update (self or existing effect when stacking)
    var target_effect: BerserkEffect = effect_to_update if effect_to_update != null else self
    
    # Remove old Power/Speed berserk effects using stored references
    if target_effect.power_effect_ref != null and target_effect.power_effect_ref in character.status_effects:
        character.status_effects.erase(target_effect.power_effect_ref)
    if target_effect.speed_effect_ref != null and target_effect.speed_effect_ref in character.status_effects:
        character.status_effects.erase(target_effect.speed_effect_ref)
    
    # Apply new Power and Speed AlterAttributeEffects and store references
    target_effect.power_effect_ref = ALTER_ATTRIBUTE_EFFECT.new("power", num_stacks, 999)
    target_effect.speed_effect_ref = ALTER_ATTRIBUTE_EFFECT.new("speed", num_stacks, 999)
    character.add_status_effect(target_effect.power_effect_ref)
    character.add_status_effect(target_effect.speed_effect_ref)

func get_visual_data() -> Dictionary:
    return {
        "icon": "res://sprites/placeholder.png",
        "color": Color.RED,
        "show_stacks": true
    }

func duplicate() -> StatusEffect:
    var dup = BerserkEffect.new(berserk_stacks)
    dup.duration = duration
    dup.stacks = stacks
    dup.magnitude = magnitude
    return dup
