class_name AlterAttributeEffect
extends StatusEffect

var attribute_name: String = ""  # "power", "skill", "strategy", "speed", "luck"
var alteration_amount: int = 0  # Can be positive (buff) or negative (debuff)

func _init(p_attribute_name: String = "", p_alteration_amount: int = 0, p_duration: int = 3):
    attribute_name = p_attribute_name
    alteration_amount = p_alteration_amount
    duration = p_duration
    stacks = 1
    magnitude = 1.0

func get_effect_name() -> String:
    var sgn: String = "+" if alteration_amount >= 0 else ""
    return "%s %s%s" % [attribute_name.capitalize(), sgn, alteration_amount]

func can_stack() -> bool:
    return true  # Stackable - multiple applications increase the debuff/buff

func _matches_existing_effect(existing: StatusEffect) -> bool:
    # Match by both class type AND attribute name
    # This allows multiple AlterAttribute effects (one per attribute) while still matching existing effects of the same attribute
    if not existing is AlterAttributeEffect:
        return false
    var existing_alter: AlterAttributeEffect = existing as AlterAttributeEffect
    return existing_alter.attribute_name == attribute_name

func on_apply(p_target: Variant, status_effects_array: Array[StatusEffect]) -> void:
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

func on_tick(_combatant: Variant = null) -> Dictionary:
    return {}  # No turn-based effects, attribute alteration is passive

func on_modify_attributes(attributes: Attributes) -> void:
    # Modify the specified attribute by the alteration amount
    match attribute_name.to_lower():
        "power":
            attributes.power += alteration_amount
        "skill":
            attributes.skill += alteration_amount
        "strategy":
            attributes.strategy += alteration_amount
        "speed":
            attributes.speed += alteration_amount
        "luck":
            attributes.luck += alteration_amount
    
    # Clamp to valid range (0-10)
    attributes.power = clamp(attributes.power, 0, 10)
    attributes.skill = clamp(attributes.skill, 0, 10)
    attributes.strategy = clamp(attributes.strategy, 0, 10)
    attributes.speed = clamp(attributes.speed, 0, 10)
    attributes.luck = clamp(attributes.luck, 0, 10)

func get_visual_data() -> Dictionary:
    # Color based on whether it's a buff or debuff
    var effect_color: Color = Color.GREEN if alteration_amount > 0 else Color.RED
    return {
        "icon": "res://sprites/placeholder.png",
        "color": effect_color,
        "show_stacks": true
    }

func duplicate() -> StatusEffect:
    var dup = AlterAttributeEffect.new(attribute_name, alteration_amount, duration)
    dup.stacks = stacks
    dup.magnitude = magnitude
    return dup
