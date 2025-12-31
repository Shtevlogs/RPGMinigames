extends Node

# NOTE: This is an autoload singleton. Do not add class_name.
# Autoload singletons are accessed globally by their autoload name (SceneManager).
# Adding class_name to autoload singletons can cause conflicts and is unnecessary.

# SceneManager - Handles scene transitions and loading
# Provides smooth transitions between game scenes

signal scene_changed(new_scene: String)

var current_scene: String = ""
var transition_in_progress: bool = false

# Scene paths
const MAIN_MENU = "res://scenes/main_menu.tscn"
const PARTY_SELECTION = "res://scenes/party_selection.tscn"
const COMBAT = "res://scenes/combat.tscn"
const LAND_SCREEN = "res://scenes/land_screen.tscn"
const MINIGAME_BERSERKER = "res://scenes/minigames/berserker_minigame.tscn"
const MINIGAME_TIME_WIZARD = "res://scenes/minigames/time_wizard_minigame.tscn"
const MINIGAME_MONK = "res://scenes/minigames/monk_minigame.tscn"
const MINIGAME_WILD_MAGE = "res://scenes/minigames/wild_mage_minigame.tscn"

func _ready() -> void:
    pass

func change_scene(scene_path: String, transition_data: Dictionary = {}) -> void:
    if transition_in_progress:
        push_warning("Scene transition already in progress")
        return
    
    transition_in_progress = true
    
    # Store transition data for next scene
    if not transition_data.is_empty():
        StateManager.set_transition_data(transition_data)
    
    # Get tree and current scene
    var tree = get_tree()
    if tree == null:
        push_error("Cannot get scene tree")
        transition_in_progress = false
        return
        
    await tree.process_frame
   
    # Load and change scene
    var error = tree.change_scene_to_file(scene_path)
    if error != OK:
        push_error("Failed to change scene to: " + scene_path)
        transition_in_progress = false
        return
    
    current_scene = scene_path
    scene_changed.emit(scene_path)
    transition_in_progress = false

func load_minigame_scene(class_type: GDScript) -> String:
    # Use MinigameRegistry instead of match statement
    return MinigameRegistry.get_minigame_scene_path(class_type)

func go_to_main_menu() -> void:
    change_scene(MAIN_MENU)

func go_to_party_selection() -> void:
    change_scene(PARTY_SELECTION)

func go_to_combat() -> void:
    change_scene(COMBAT)

func go_to_land_screen() -> void:
    change_scene(LAND_SCREEN)

func go_to_minigame(class_type: GDScript, minigame_data: Dictionary = {}) -> void:
    var scene_path = load_minigame_scene(class_type)
    if scene_path != "":
        change_scene(scene_path, minigame_data)
