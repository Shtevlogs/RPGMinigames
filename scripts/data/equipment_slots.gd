class_name EquipmentSlots
extends GameStateSerializable

var rings: Array[Equipment] = []  # 2 slots
var neck: Equipment = null  # 1 slot
var armor: Equipment = null  # 1 slot
var head: Equipment = null  # 1 slot
var class_specific: Array[Equipment] = []  # 1-2 slots, class-dependent

func get_total_attribute_bonuses() -> Attributes:
    var bonuses = Attributes.new()
    
    # Sum bonuses from all equipment
    if neck != null:
        bonuses.power += neck.attribute_bonuses.power
        bonuses.skill += neck.attribute_bonuses.skill
        bonuses.strategy += neck.attribute_bonuses.strategy
        bonuses.speed += neck.attribute_bonuses.speed
        bonuses.luck += neck.attribute_bonuses.luck
    
    if armor != null:
        bonuses.power += armor.attribute_bonuses.power
        bonuses.skill += armor.attribute_bonuses.skill
        bonuses.strategy += armor.attribute_bonuses.strategy
        bonuses.speed += armor.attribute_bonuses.speed
        bonuses.luck += armor.attribute_bonuses.luck
    
    if head != null:
        bonuses.power += head.attribute_bonuses.power
        bonuses.skill += head.attribute_bonuses.skill
        bonuses.strategy += head.attribute_bonuses.strategy
        bonuses.speed += head.attribute_bonuses.speed
        bonuses.luck += head.attribute_bonuses.luck
    
    for ring in rings:
        if ring != null:
            bonuses.power += ring.attribute_bonuses.power
            bonuses.skill += ring.attribute_bonuses.skill
            bonuses.strategy += ring.attribute_bonuses.strategy
            bonuses.speed += ring.attribute_bonuses.speed
            bonuses.luck += ring.attribute_bonuses.luck
    
    for item in class_specific:
        if item != null:
            bonuses.power += item.attribute_bonuses.power
            bonuses.skill += item.attribute_bonuses.skill
            bonuses.strategy += item.attribute_bonuses.strategy
            bonuses.speed += item.attribute_bonuses.speed
            bonuses.luck += item.attribute_bonuses.luck
    
    return bonuses

func duplicate() -> EquipmentSlots:
    var dup = EquipmentSlots.new()
    dup.rings = []
    for ring in rings:
        dup.rings.append(ring.duplicate() if ring != null else null)
    dup.neck = neck.duplicate() if neck != null else null
    dup.armor = armor.duplicate() if armor != null else null
    dup.head = head.duplicate() if head != null else null
    dup.class_specific = []
    for item in class_specific:
        dup.class_specific.append(item.duplicate() if item != null else null)
    return dup

func serialize() -> Dictionary:
    """Serialize equipment slots to dictionary."""
    var data: Dictionary = {
        "rings": [],
        "neck": {},
        "armor": {},
        "head": {},
        "class_specific": []
    }
    
    for ring in rings:
        data["rings"].append(ring.serialize() if ring != null else {})
    
    data["neck"] = neck.serialize() if neck != null else {}
    data["armor"] = armor.serialize() if armor != null else {}
    data["head"] = head.serialize() if head != null else {}
    
    for item in class_specific:
        data["class_specific"].append(item.serialize() if item != null else {})
    
    return data

func deserialize(data: Dictionary) -> void:
    """Deserialize equipment slots from dictionary."""
    rings.clear()
    for ring_data in data.get("rings", []):
        if ring_data is Dictionary and not ring_data.is_empty():
            var ring: Equipment = Equipment.new()
            ring.deserialize(ring_data)
            rings.append(ring)
        else:
            rings.append(null)
    
    var neck_data = data.get("neck", {})
    if neck_data is Dictionary and not neck_data.is_empty():
        neck = Equipment.new()
        neck.deserialize(neck_data)
    else:
        neck = null
    
    var armor_data = data.get("armor", {})
    if armor_data is Dictionary and not armor_data.is_empty():
        armor = Equipment.new()
        armor.deserialize(armor_data)
    else:
        armor = null
    
    var head_data = data.get("head", {})
    if head_data is Dictionary and not head_data.is_empty():
        head = Equipment.new()
        head.deserialize(head_data)
    else:
        head = null
    
    class_specific.clear()
    for item_data in data.get("class_specific", []):
        if item_data is Dictionary and not item_data.is_empty():
            var item: Equipment = Equipment.new()
            item.deserialize(item_data)
            class_specific.append(item)
        else:
            class_specific.append(null)
