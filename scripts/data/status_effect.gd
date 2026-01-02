class_name StatusEffect
extends GameStateSerializable

var duration: int = 0  # turns remaining
var stacks: int = 1
var target: BattleEntity = null  # Reference to the entity (CharacterBattleEntity or EnemyBattleEntity) this effect is applied to

# For display
func get_effect_name() -> String:
    return "Unknown Effect"

func can_stack() -> bool:
    # Return true if this effect can stack with itself
    push_error("can_stack() must be overridden in subclass")
    return false

func _matches_existing_effect(existing: StatusEffect) -> bool:
    # Determines if an existing effect should be considered a match for this new effect
    # Default implementation: match by script type (same class)
    # Child classes can override to provide custom matching logic (e.g., match by attribute type)
    # Returns true if the existing effect should be considered the same type as this effect
    return existing.get_script() == get_script()

func on_apply(p_target: BattleEntity, status_effects_array: Array[StatusEffect]) -> void:
    # Called when effect is applied to a target
    # p_target: The entity (CharacterBattleEntity or EnemyBattleEntity) this effect is being applied to
    # status_effects_array: The array of status effects on the target (for finding matches and appending)
    # Sets target reference, finds matching existing effect, updates it or appends self
    target = p_target
    
    # Find matching existing effect
    var existing_effect: StatusEffect = null
    for existing in status_effects_array:
        if _matches_existing_effect(existing):
            existing_effect = existing
            break
    
    # If found, update existing effect
    if existing_effect != null:
        if can_stack():
            existing_effect.stacks += stacks
            existing_effect.duration = max(existing_effect.duration, duration)
        else:
            existing_effect.duration = max(existing_effect.duration, duration)
    else:
        # If not found, append this effect to the array
        status_effects_array.append(self)

func on_tick(_battle_state: BattleState) -> void:
    # Called at start of each turn
    # _battle_state: The current battle state, providing access to battle context
    # Effects should apply their changes directly (e.g., target.take_damage())
    # Default implementation does nothing
    pass

func on_remove(_battle_state: BattleState) -> void:
    # Called when effect is removed (expired, death, or forced removal)
    # _battle_state: The current battle state, providing access to battle context
    # Allows effects to perform cleanup logic
    # Default implementation does nothing
    pass

func on_modify_attributes(_attributes: Attributes) -> void:
    # Called when calculating effective attributes
    # Allows status effects to modify attributes (e.g., AlterAttributeEffect)
    # Default implementation does nothing
    # Child classes can override to modify attributes
    pass

func tick() -> bool:
    # Decrements duration, returns true if should be removed
    duration -= 1
    return duration <= 0

func get_visual_data() -> StatusEffectVisualData:
    # Return visual representation data (icon path, color, etc.)
    push_error("get_visual_data() must be overridden in subclass")
    return StatusEffectVisualData.new("", Color.WHITE, false)

func get_file_name() -> String:
    var fpath := (get_script().resource_path as String).split("/")
    return fpath[fpath.size() - 1]

func serialize() -> Dictionary:
    #TODO: check that this ends up being the name of the file
    var fname : String = get_file_name()
    var data: Dictionary = {
        "type": fname,
        "duration": duration,
        "stacks": stacks,
    }
    return data

func deserialize(data: Dictionary) -> void:
    duration = data.get("duration", 0)
    stacks = data.get("stacks", 1)

static var status_type_lookup : Dictionary = {}

static func cache_status_scripts() -> void:
    if status_type_lookup.is_empty():
        var path := "res://scripts/data/status_effects"
        var dir := DirAccess.open(path)
        dir.list_dir_begin()
        var file_name := dir.get_next()
        while file_name != "":
            var effect_script : GDScript = ResourceLoader.load(path + "/" + file_name)
            status_type_lookup[file_name] = effect_script
            file_name = dir.get_next()
        dir.list_dir_end()

static func deserialize_status(data: Dictionary) -> StatusEffect:
    if status_type_lookup.is_empty():
        cache_status_scripts()

    var status : StatusEffect = status_type_lookup[data.type].new()
    status.deserialize(data)
    return status
