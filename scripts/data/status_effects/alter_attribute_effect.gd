class_name AlterAttributeEffect
extends StatusEffect

var attribute_name: String = ""  # "power", "skill", "strategy", "speed", "luck"
var alteration_amount: int = 0  # Can be positive (buff) or negative (debuff)

func _init():
    attribute_name = "power"
    alteration_amount = 0
    duration = 3
    stacks = 1

# For display
func get_effect_name() -> String:
    return "%s %s" % ["Increase" if alteration_amount > 0 else "Reduce", attribute_name.to_pascal_case()]

func can_stack() -> bool:
    return true  # Stackable - multiple applications increase the debuff/buff

func _matches_existing_effect(existing: StatusEffect) -> bool:
    # Match by both class type AND attribute name
    # This allows multiple AlterAttribute effects (one per attribute) while still matching existing effects of the same attribute
    if not existing is AlterAttributeEffect:
        return false
    var existing_alter: AlterAttributeEffect = existing as AlterAttributeEffect
    return existing_alter.attribute_name == attribute_name

func on_apply(p_target: BattleEntity, status_effects_array: Array[StatusEffect]) -> void:
    # Call parent to handle matching and appending
    super.on_apply(p_target, status_effects_array)
    
    # If we found an existing effect, update its alteration amount (stacking)
    # Find the existing effect we just matched
    var existing_effect: AlterAttributeEffect = null
    for existing in status_effects_array:
        if existing is AlterAttributeEffect:
            var existing_alter: AlterAttributeEffect = existing as AlterAttributeEffect
            if existing_alter.attribute_name == attribute_name and existing_alter != self:
                existing_effect = existing_alter
                break
    
    if existing_effect != null:
        # Stack the alteration amount
        existing_effect.alteration_amount += alteration_amount
        # Update duration to the longer of the two
        existing_effect.duration = max(existing_effect.duration, duration)

func on_tick(_battle_state: BattleState) -> void:
    # No turn-based effects, attribute alteration is passive (handled via on_modify_attributes)
    pass

func on_remove(_battle_state: BattleState) -> void:
    # No cleanup needed - attribute restoration handled by duration expiration
    pass

func on_modify_attributes(attributes: Attributes) -> void:
    # Modify the specified attribute by the alteration amount
    var new_value := clampi(attributes.get(attribute_name.to_lower()) + alteration_amount, 0, 10)
    attributes.set(attribute_name.to_lower(), new_value)

func get_visual_data() -> StatusEffectVisualData:
    # Color based on whether it's a buff or debuff
    var effect_color: Color = Color.GREEN if alteration_amount > 0 else Color.RED
    return StatusEffectVisualData.new("res://sprites/placeholder.png", effect_color, true)

func serialize() -> Dictionary:
    var data: Dictionary = super.serialize()
    data["class"] = "alter_attribute"
    data["attribute_name"] = attribute_name
    data["alteration_amount"] = alteration_amount
    return data

func deserialize(data: Dictionary) -> void:
    super.deserialize(data)
    attribute_name = data.get("attribute_name", "")
    alteration_amount = data.get("alteration_amount", 0)
