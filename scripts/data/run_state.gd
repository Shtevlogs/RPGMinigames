class_name RunState
extends RefCounted

var party: Array[Character] = []  # 3 characters
var current_land: int = 1  # 1-5
var current_land_theme: String = ""
var encounter_progress: int = 0  # encounters completed in current land
var land_sequence: Array[String] = []  # Sequence of land themes (1-5)
var inventory: Array[Item] = []
var currency: int = 0
var run_start_time: float = 0.0
var auto_save_data: Dictionary = {}

func _init():
    run_start_time = Time.get_ticks_msec() / 1000.0

func generate_land_sequence() -> void:
    # Generate land sequence from party classes
    # One land per unique class + random lands + The Rift (always last)
    land_sequence.clear()
    
    # Get unique class types from party
    var unique_classes: Array[String] = []
    var class_set: Dictionary = {}
    for character in party:
        var class_type: String = character.class_type.to_lower()
        if not class_set.has(class_type):
            unique_classes.append(class_type)
            class_set[class_type] = true
    
    # Add unique class lands
    land_sequence.append_array(unique_classes)
    
    # Fill remaining slots (up to 4) with random lands, then add The Rift
    var available_classes: Array[String] = ["berserker", "timewizard", "monk", "wildmage"]
    var remaining_slots: int = 4 - unique_classes.size()
    
    # Remove already used classes from available pool
    for used_class in unique_classes:
        var index: int = available_classes.find(used_class)
        if index >= 0:
            available_classes.remove_at(index)
    
    # Add random lands if needed
    for i in range(remaining_slots):
        if available_classes.is_empty():
            break
        var random_index: int = randi() % available_classes.size()
        land_sequence.append(available_classes[random_index])
        available_classes.remove_at(random_index)
    
    # Ensure we have exactly 4 lands before The Rift
    while land_sequence.size() < 4:
        # If we've exhausted all classes, use "random" as fallback
        if available_classes.is_empty():
            land_sequence.append("random")
        else:
            var random_index: int = randi() % available_classes.size()
            land_sequence.append(available_classes[random_index])
            available_classes.remove_at(random_index)
    
    # The Rift is always the final land (land 5)
    land_sequence.append("rift")
    
    # Initialize first land
    if land_sequence.size() > 0:
        current_land_theme = land_sequence[0]
        current_land = 1
        encounter_progress = 0

func duplicate() -> RunState:
    var dup = RunState.new()
    dup.party = []
    for character in party:
        dup.party.append(character.duplicate())
    dup.current_land = current_land
    dup.current_land_theme = current_land_theme
    dup.encounter_progress = encounter_progress
    dup.land_sequence = land_sequence.duplicate()
    dup.inventory = []
    for item in inventory:
        dup.inventory.append(item.duplicate())
    dup.currency = currency
    dup.run_start_time = run_start_time
    dup.auto_save_data = auto_save_data.duplicate()
    return dup
