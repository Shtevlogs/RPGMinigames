extends Node

# NOTE: This is an autoload singleton. Do not add class_name.
# Autoload singletons are accessed globally by their autoload name (MinigameRegistry).

# MinigameRegistry - Maps class types to their minigame scenes and behaviors
# Provides centralized registration and lookup for class-specific minigame data

var class_behaviors: Dictionary = {}  # GDScript -> BaseClassBehavior instance
var minigame_scenes: Dictionary = {}  # GDScript -> scene path
var class_type_to_string: Dictionary = {}  # GDScript -> String (for serialization/display)
var string_to_class_type: Dictionary = {}  # String -> GDScript (for deserialization)

func _ready() -> void:
    # Register all class types
    _register_classes()

func _register_classes() -> void:
    # Register Berserker
    register_class(BerserkerBehavior, BerserkerBehavior, "res://scenes/minigames/berserker_minigame.tscn")
    
    # Register TimeWizard
    register_class(TimeWizardBehavior, TimeWizardBehavior, "res://scenes/minigames/time_wizard_minigame.tscn")
    
    # Register Monk
    register_class(MonkBehavior, MonkBehavior, "res://scenes/minigames/monk_minigame.tscn")
    
    # Register WildMage
    register_class(WildMageBehavior, WildMageBehavior, "res://scenes/minigames/wild_mage_minigame.tscn")

func register_class(class_type: GDScript, behavior_class: GDScript, scene_path: String) -> void:
    """Register a class type with its behavior and scene path."""
    minigame_scenes[class_type] = scene_path
    var class_string = _derive_class_string(class_type)
    
    # Instantiate behavior class directly using class_name
    var behavior_instance = behavior_class.new()
    if behavior_instance == null:
        push_error("Failed to instantiate behavior for class: " + class_string)
        return
    
    class_behaviors[class_type] = behavior_instance
    
    # Build string mapping for serialization/deserialization
    class_type_to_string[class_type] = class_string
    string_to_class_type[class_string] = class_type

func get_behavior(class_type: GDScript) -> BaseClassBehavior:
    """Get the behavior instance for a class type."""
    return class_behaviors.get(class_type, null)

func get_minigame_scene_path(class_type: GDScript) -> String:
    """Get the minigame scene path for a class type."""
    return minigame_scenes.get(class_type, "")

func has_class(class_type: GDScript) -> bool:
    """Check if a class type is registered."""
    return class_type in class_behaviors

func _derive_class_string(class_type: GDScript) -> String:
    """Derive string identifier from GDScript class type."""
    # Example: BerserkerBehavior -> "Berserker"
    var script_path = class_type.resource_path
    var file_name = script_path.get_file().get_basename()
    # Remove "Behavior" suffix if present
    if file_name.ends_with("_behavior"):
        return file_name.substr(0, file_name.length() - 9).capitalize()
    elif file_name.ends_with("Behavior"):
        return file_name.substr(0, file_name.length() - 8)
    return file_name.capitalize()

func get_class_type_string(class_type: GDScript) -> String:
    """Get string identifier for a GDScript class type."""
    if class_type == null:
        return ""
    return class_type_to_string.get(class_type, "")

func get_class_type_from_string(class_string: String) -> GDScript:
    """Get GDScript type from string identifier."""
    if class_string.is_empty():
        return null
    return string_to_class_type.get(class_string, null)
