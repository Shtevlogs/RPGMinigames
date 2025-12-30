class_name Encounter
extends RefCounted

enum EncounterType {
    STANDARD,
    BOSS,
    ELITE,
    SPECIAL,
    SHOP,
    MERCENARY
}

var encounter_id: String
var encounter_type: EncounterType
var enemy_composition: Array[EnemyData] = []
var enemy_formation: Array[Vector2] = []  # Positions for enemies
var rewards: Rewards
var encounter_pool: String = ""  # land theme + difficulty
var encounter_name: String = ""

func _init(p_id: String = "", p_type: EncounterType = EncounterType.STANDARD):
    encounter_id = p_id
    encounter_type = p_type
    rewards = Rewards.new()

func duplicate() -> Encounter:
    var dup = Encounter.new(encounter_id, encounter_type)
    dup.encounter_name = encounter_name
    dup.enemy_composition.clear()
    for enemy in enemy_composition:
        dup.enemy_composition.append(enemy.duplicate())
    dup.enemy_formation = enemy_formation.duplicate()
    dup.rewards = rewards.duplicate()
    dup.encounter_pool = encounter_pool
    return dup
