class_name PartySelection
extends Control

@onready var class_selection_container: HBoxContainer = $VBoxContainer/ClassSelectionContainer
@onready var confirm_button: Button = $VBoxContainer/ConfirmButton
@onready var reroll_button: Button = $VBoxContainer/RerollButton

var available_characters: Array[Character] = []
var selected_party: Array[Character] = []

const CLASS_TYPES = ["Berserker", "TimeWizard", "Monk", "WildMage"]

func _ready() -> void:
    confirm_button.pressed.connect(_on_confirm_pressed)
    reroll_button.pressed.connect(_on_reroll_pressed)
    generate_class_selection()

func generate_class_selection() -> void:
    available_characters.clear()
    selected_party.clear()
    
    # Track class counts per type to generate unique names
    var class_counts: Dictionary = {}
    for class_type in CLASS_TYPES:
        class_counts[class_type] = 0
    
    # Generate random selection of individual characters (placeholder - should be rerollable)
    for i in range(6):  # Show 6 options
        var class_type: String = CLASS_TYPES[randi() % CLASS_TYPES.size()]
        class_counts[class_type] += 1
        var character_name: String = "%s %d" % [class_type, class_counts[class_type]]
        # Create character with class_type and name, attributes will default
        var character: Character = Character.new(class_type, null, character_name, character_name)
        character.class_type = class_type
        available_characters.append(character)
    
    update_ui()

func update_ui() -> void:
    # Clear existing buttons
    for child in class_selection_container.get_children():
        child.queue_free()
    
    # Create buttons for each available character
    for character in available_characters:
        var button: Button = Button.new()
        button.text = character.display_name
        button.toggle_mode = true
        # Store Character reference in button metadata
        button.set_meta("character", character)
        button.pressed.connect(_on_character_selected.bind(character))
        class_selection_container.add_child(button)

func _on_character_selected(character: Character) -> void:
    # Toggle selection (max 3)
    var index = selected_party.find(character)
    if index >= 0:
        selected_party.erase(character)
    else:
        if selected_party.size() < 3:
            selected_party.append(character)
        else:
            # Remove first and add new
            selected_party.pop_front()
            selected_party.append(character)
    
    update_selection_ui()

func update_selection_ui() -> void:
    # Update button states by matching Character objects by reference
    for i in range(class_selection_container.get_child_count()):
        var button: Button = class_selection_container.get_child(i)
        var character: Character = button.get_meta("character")
        if character in selected_party:
            button.button_pressed = true
        else:
            button.button_pressed = false
    
    confirm_button.disabled = selected_party.size() != 3

func _on_confirm_pressed() -> void:
    if selected_party.size() != 3:
        return
    
    # Use the selected Character objects directly (no need to recreate them)
    # Start new run
    GameManager.start_new_run(selected_party)
    SceneManager.go_to_combat()

func _on_reroll_pressed() -> void:
    generate_class_selection()
