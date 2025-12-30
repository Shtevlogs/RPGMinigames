class_name EquipmentSlots
extends RefCounted

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
