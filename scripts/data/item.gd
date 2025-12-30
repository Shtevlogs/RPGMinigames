class_name Item
extends RefCounted

enum ItemType {
    HEALING,
    BUFF,
    DEBUFF,
    UTILITY,
}

var item_id: String = ""
var item_name: String = ""
var item_type: ItemType
var combat_only: bool = false
var effects: Dictionary = {}  # Effect data

func _init(p_id: String = "", p_name: String = "", p_type: ItemType = ItemType.HEALING):
    item_id = p_id
    item_name = p_name
    item_type = p_type

func duplicate() -> Item:
    var dup = Item.new(item_id, item_name, item_type)
    dup.combat_only = combat_only
    dup.effects = effects.duplicate()
    return dup
