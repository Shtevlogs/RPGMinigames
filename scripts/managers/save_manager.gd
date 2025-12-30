extends Node

# NOTE: This is an autoload singleton. Do not add class_name.
# Autoload singletons are accessed globally by their autoload name (SaveManager).
# Adding class_name to autoload singletons can cause conflicts and is unnecessary.

# SaveManager - Handles auto-save functionality
# Prevents save-scumming by only allowing auto-saves

const SAVE_PATH = "user://run_autosave.save"

signal save_created()
signal save_loaded()
signal save_deleted()

func _ready() -> void:
    pass

func auto_save(run_state: RunState) -> void:
    if run_state == null:
        push_warning("Cannot save: run_state is null")
        return
    
    var save_data: Dictionary = serialize_run_state(run_state)
    
    var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
    if file:
        file.store_string(JSON.stringify(save_data))
        file.close()
        save_created.emit()
    else:
        push_error("Failed to create save file")

func load_auto_save() -> RunState:
    var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.READ)
    if file == null:
        return null
    
    var json_string: String = file.get_as_text()
    file.close()
    
    var json: JSON = JSON.new()
    var error: Error = json.parse(json_string)
    if error != OK:
        push_error("Failed to parse save file")
        return null
    
    var save_data: Dictionary = json.data
    var run_state: RunState = deserialize_run_state(save_data)
    
    if run_state:
        save_loaded.emit()
    
    return run_state

func has_auto_save() -> bool:
    return FileAccess.file_exists(SAVE_PATH)

func delete_auto_save() -> void:
    if FileAccess.file_exists(SAVE_PATH):
        DirAccess.remove_absolute(SAVE_PATH)
        save_deleted.emit()

func serialize_run_state(run_state: RunState) -> Dictionary:
    # Serialize run state to dictionary
    # This is a simplified version - you may need to expand this
    var data: Dictionary = {
        "current_land": run_state.current_land,
        "current_land_theme": run_state.current_land_theme,
        "encounter_progress": run_state.encounter_progress,
        "land_sequence": run_state.land_sequence,
        "currency": run_state.currency,
        "run_start_time": run_state.run_start_time,
        "party": [],
        "inventory": [],
        "auto_save_data": run_state.auto_save_data,
        "battle_state": null  # Will be set if in combat
    }
    
    # Serialize battle state if present
    if run_state.auto_save_data.has("battle_state"):
        data["battle_state"] = run_state.auto_save_data["battle_state"]
    
    # Serialize party (simplified - you'll need to expand this)
    for character in run_state.party:
        var char_data: Dictionary = {
            "class_type": character.class_type,
            "attributes": {
                "power": character.attributes.power,
                "skill": character.attributes.skill,
                "strategy": character.attributes.strategy,
                "speed": character.attributes.speed,
                "luck": character.attributes.luck
            },
            "health": {
                "current": character.health.current,
                "max": character.health.max_hp
            }
        }
        data.party.append(char_data)
    
    # Serialize inventory (simplified)
    for item in run_state.inventory:
        var item_data: Dictionary = {
            "item_id": item.item_id,
            "item_name": item.item_name,
            "item_type": item.item_type
        }
        data.inventory.append(item_data)
    
    return data

func deserialize_run_state(data: Dictionary) -> RunState:
    # Deserialize dictionary to run state
    # This is a simplified version - you'll need to expand this
    var run_state: RunState = RunState.new()
    
    run_state.current_land = data.get("current_land", 1)
    run_state.current_land_theme = data.get("current_land_theme", "")
    run_state.encounter_progress = data.get("encounter_progress", 0)
    run_state.land_sequence = data.get("land_sequence", [])
    run_state.currency = data.get("currency", 0)
    run_state.run_start_time = data.get("run_start_time", 0.0)
    run_state.auto_save_data = data.get("auto_save_data", {})
    
    # Regenerate land_sequence if missing (for backward compatibility)
    if run_state.land_sequence.is_empty() and not run_state.party.is_empty():
        run_state.generate_land_sequence()
    
    # Deserialize party
    for character_data in data.get("party", []):
        var attrs: Attributes = Attributes.new(
            character_data.attributes.power,
            character_data.attributes.skill,
            character_data.attributes.strategy,
            character_data.attributes.speed,
            character_data.attributes.luck
        )
        var character: Character = Character.new(character_data.class_type, attrs)
        character.health.current = character_data.health.current
        character.health.max_hp = character_data.health.max
        run_state.party.append(character)
    
    # Deserialize inventory (simplified)
    for item_data in data.get("inventory", []):
        var item: Item = Item.new(item_data.item_id, item_data.item_name, item_data.item_type)
        run_state.inventory.append(item)
    
    return run_state
