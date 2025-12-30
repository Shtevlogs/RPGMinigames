class_name MinigameBattleState
extends RefCounted

var class_type: String = ""
var state_data: Variant = null  # Class-specific state data (type depends on class)

func serialize() -> Dictionary:
    """Serialize to dictionary for save system."""
    var data: Dictionary = {
        "class_type": class_type
    }
    
    # Serialize state_data if it's a dictionary or has serialize method
    if state_data is Dictionary:
        data["state_data"] = state_data
    elif state_data != null and state_data.has_method("serialize"):
        data["state_data"] = state_data.serialize()
    else:
        data["state_data"] = null
    
    return data

func deserialize(data: Dictionary) -> void:
    """Deserialize from dictionary."""
    class_type = data.get("class_type", "")
    state_data = data.get("state_data", null)

