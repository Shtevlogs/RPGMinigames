class_name Rewards
extends RefCounted

var items: Array[Item] = []
var equipment: Array[Equipment] = []
var currency: int = 0

func _init() -> void:
    pass

func duplicate() -> Rewards:
    var dup = Rewards.new()
    dup.items.clear()
    for item in items:
        dup.items.append(item.duplicate())
    dup.equipment.clear()
    for equip in equipment:
        dup.equipment.append(equip.duplicate())
    dup.currency = currency
    return dup
