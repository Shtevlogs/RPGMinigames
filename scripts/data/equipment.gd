class_name Equipment
extends GameStateSerializable

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

func serialize() -> Dictionary:
    """Serialize equipment to dictionary."""
    return {
        "equipment_id": equipment_id,
        "equipment_name": equipment_name,
        "slot_type": slot_type,
        "attribute_bonuses": {
            "power": attribute_bonuses.power,
            "skill": attribute_bonuses.skill,
            "strategy": attribute_bonuses.strategy,
            "speed": attribute_bonuses.speed,
            "luck": attribute_bonuses.luck
        },
        "special_effects": special_effects.duplicate()
    }

func deserialize(data: Dictionary) -> void:
    """Deserialize equipment from dictionary."""
    equipment_id = data.get("equipment_id", "")
    equipment_name = data.get("equipment_name", "")
    slot_type = data.get("slot_type", "")
    
    var bonuses_data: Dictionary = data.get("attribute_bonuses", {})
    attribute_bonuses = Attributes.new(
        bonuses_data.get("power", 0),
        bonuses_data.get("skill", 0),
        bonuses_data.get("strategy", 0),
        bonuses_data.get("speed", 0),
        bonuses_data.get("luck", 0)
    )
    
    special_effects = data.get("special_effects", {}).duplicate()
