extends Node

# NOTE: This is an autoload singleton. Do not add class_name.
# Autoload singletons are accessed globally by their autoload name (MinigameRegistry).

# MinigameRegistry - Maps class types to their minigame scenes and behaviors
# Provides centralized registration and lookup for class-specific minigame data

var class_behaviors: Dictionary = {}  # class_type -> BaseClassBehavior instance
var minigame_scenes: Dictionary = {}  # class_type -> scene path

func _ready() -> void:
    # Register all class types
    _register_classes()

func _register_classes() -> void:
    # Register Berserker
    register_class("Berserker", BerserkerBehavior, "res://scenes/minigames/berserker_minigame.tscn")
    
    # Register TimeWizard
    register_class("TimeWizard", TimeWizardBehavior, "res://scenes/minigames/time_wizard_minigame.tscn")
    
    # Register Monk
    register_class("Monk", MonkBehavior, "res://scenes/minigames/monk_minigame.tscn")
    
    # Register WildMage
    register_class("WildMage", WildMageBehavior, "res://scenes/minigames/wild_mage_minigame.tscn")

func register_class(class_type: String, behavior_class: GDScript, scene_path: String) -> void:
    """Register a class type with its behavior and scene path."""
    minigame_scenes[class_type] = scene_path
    
    # Instantiate behavior class directly using class_name
    var behavior_instance = behavior_class.new()
    if behavior_instance == null:
        push_error("Failed to instantiate behavior for class: " + class_type)
        return
    
    class_behaviors[class_type] = behavior_instance

func get_behavior(class_type: String) -> BaseClassBehavior:
    """Get the behavior instance for a class type."""
    return class_behaviors.get(class_type, null)

func get_minigame_scene_path(class_type: String) -> String:
    """Get the minigame scene path for a class type."""
    return minigame_scenes.get(class_type, "")

func has_class(class_type: String) -> bool:
    """Check if a class type is registered."""
    return class_type in class_behaviors
