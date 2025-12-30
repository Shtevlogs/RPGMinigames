extends Node

# NOTE: This is an autoload singleton. Do not add class_name.
# Autoload singletons are accessed globally by their autoload name (EncounterManager).
# Adding class_name to autoload singletons can cause conflicts and is unnecessary.

# EncounterManager - Manages encounter data and selection
# Handles encounter pools, creation, and retrieval

var encounter_pools: Dictionary = {}
var encounters_by_id: Dictionary = {}

const ENCOUNTERS_PER_LAND: int = 3  # Standard encounters before boss
const BOSS_ENCOUNTER_INDEX: int = 3  # Boss appears after 3 standard encounters

func _ready() -> void:
    # Initialize placeholder encounter
    _create_placeholder_encounter()
    # Initialize placeholder encounter pools
    _create_placeholder_pools()

func _create_placeholder_encounter() -> void:
    # Create two rats with Power=0, all other stats=1
    var rat_attributes = Attributes.new(0, 1, 1, 1, 1)  # Power=0, others=1
    
    var rat1 = EnemyBattleEntity.new("rat", "Rat", rat_attributes)
    rat1.enemy_type = "beast"
    
    var rat2 = EnemyBattleEntity.new("rat", "Rat", rat_attributes)
    rat2.enemy_type = "beast"
    
    # Create the encounter
    var encounter = Encounter.new("placeholder_two_rats", Encounter.EncounterType.STANDARD)
    encounter.encounter_name = "Two Rats"
    encounter.enemy_composition.append_array([rat1, rat2])
    encounter.enemy_formation.append_array([Vector2(100, 0), Vector2(250, 0)])
    encounter.encounter_pool = "placeholder"
    encounter.rewards = Rewards.new()  # Empty rewards for placeholder
    
    # Store the encounter
    encounters_by_id["placeholder_two_rats"] = encounter
    
    # Add to placeholder pool
    if not encounter_pools.has("placeholder"):
        encounter_pools["placeholder"] = []
    encounter_pools["placeholder"].append(encounter)

func get_encounter(encounter_id: String) -> Encounter:
    # Retrieve an encounter by ID, returns a duplicate to prevent modification
    if encounters_by_id.has(encounter_id):
        return encounters_by_id[encounter_id].duplicate()
    push_warning("Encounter not found: " + encounter_id)
    return null

func get_random_encounter_from_pool(pool_name: String) -> Encounter:
    # Get a random encounter from a specific pool, returns a duplicate
    if not encounter_pools.has(pool_name):
        push_warning("Encounter pool not found: " + pool_name)
        return null
    
    var pool: Array = encounter_pools[pool_name]
    if pool.is_empty():
        push_warning("Encounter pool is empty: " + pool_name)
        return null
    
    var random_index = randi() % pool.size()
    return pool[random_index].duplicate()

func create_placeholder_encounter() -> Encounter:
    # Convenience method to get the placeholder encounter
    return get_encounter("placeholder_two_rats")

func _create_placeholder_pools() -> void:
    # Create placeholder encounter pools for all land themes and difficulties
    var land_themes: Array[String] = ["berserker", "timewizard", "monk", "wildmage", "random", "rift"]
    var difficulties: Array[int] = [1, 2, 3, 4, 5]
    
    for theme in land_themes:
        # Create standard encounter pools for each difficulty
        for difficulty in difficulties:
            var pool_name: String = "%s_%d" % [theme, difficulty]
            _create_pool_encounters(pool_name, theme, difficulty, false)
        
        # Create boss encounter pool
        var boss_pool_name: String = "%s_boss" % [theme]
        _create_pool_encounters(boss_pool_name, theme, 0, true)

func _create_pool_encounters(pool_name: String, theme: String, difficulty: int, is_boss: bool) -> void:
    # Create placeholder encounters for a pool
    if not encounter_pools.has(pool_name):
        encounter_pools[pool_name] = []
    
    # Create a simple placeholder encounter
    var enemy_count: int = 2 if not is_boss else 1
    var enemy_power: int = difficulty if not is_boss else difficulty + 2
    var enemy_attributes: Attributes = Attributes.new(enemy_power, 1, 1, 1, 1)
    
    var enemies: Array[EnemyBattleEntity] = []
    var formations: Array[Vector2] = []
    
    for i in range(enemy_count):
        var enemy_name: String = "Boss %s" % theme.capitalize() if is_boss else "%s Enemy %d" % [theme.capitalize(), i + 1]
        var enemy_id: String = "%s_%s_%d" % [pool_name, "boss" if is_boss else "enemy", i]
        var enemy: EnemyBattleEntity = EnemyBattleEntity.new(enemy_id, enemy_name, enemy_attributes)
        enemy.enemy_type = "placeholder"
        enemies.append(enemy)
        formations.append(Vector2(100 + i * 150, 0))
    
    var encounter_id: String = "%s_placeholder" % pool_name
    var encounter_type: Encounter.EncounterType = Encounter.EncounterType.BOSS if is_boss else Encounter.EncounterType.STANDARD
    var encounter: Encounter = Encounter.new(encounter_id, encounter_type)
    encounter.encounter_name = "%s %s" % [theme.capitalize(), "Boss" if is_boss else "Encounter"]
    encounter.enemy_composition.append_array(enemies)
    encounter.enemy_formation.append_array(formations)
    encounter.encounter_pool = pool_name
    encounter.rewards = Rewards.new()  # Empty rewards for placeholder
    
    encounters_by_id[encounter_id] = encounter
    encounter_pools[pool_name].append(encounter)

func get_next_encounter(land_theme: String, land_number: int, encounter_progress: int) -> Encounter:
    # Determine if next encounter should be boss
    var is_boss: bool = _should_be_boss_encounter(encounter_progress)
    
    # Build pool name
    var pool_name: String
    if is_boss:
        pool_name = "%s_boss" % land_theme
    else:
        pool_name = "%s_%d" % [land_theme, land_number]
    
    # Try to get encounter from pool
    var encounter: Encounter = get_random_encounter_from_pool(pool_name)
    
    # Fallback to placeholder if pool doesn't exist or is empty
    if encounter == null:
        push_warning("Pool not found or empty: %s, using placeholder" % pool_name)
        encounter = create_placeholder_encounter()
    
    return encounter

func _should_be_boss_encounter(encounter_progress: int) -> bool:
    # Boss appears after ENCOUNTERS_PER_LAND standard encounters
    return encounter_progress >= ENCOUNTERS_PER_LAND
