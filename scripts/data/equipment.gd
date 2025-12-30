class_name Equipment
extends RefCounted

var equipment_id: String = ""
var equipment_name: String = ""
var slot_type: String = ""  # "ring", "neck", "armor", "head", "class_specific"
var attribute_bonuses: Attributes = Attributes.new()
var special_effects: Dictionary = {}  # For class-specific ability modifications

func _init(p_id: String = "", p_name: String = "", p_slot: String = ""):
    equipment_id = p_id
    equipment_name = p_name
    slot_type = p_slot

func duplicate() -> Equipment:
    var dup = Equipment.new(equipment_id, equipment_name, slot_type)
    dup.attribute_bonuses = attribute_bonuses.duplicate()
    dup.special_effects = special_effects.duplicate()
    return dup
