class_name LandScreen
extends Control

@onready var land_info_label: Label = $VBoxContainer/LandInfoLabel
@onready var encounter_progress_label: Label = $VBoxContainer/EncounterProgressLabel
@onready var party_info_container: VBoxContainer = $VBoxContainer/PartyInfoContainer
@onready var continue_button: Button = $VBoxContainer/ContinueButton

func _ready() -> void:
    continue_button.pressed.connect(_on_continue_pressed)
    update_display()

func update_display() -> void:
    if GameManager.current_run == null:
        push_error("No current run available in land screen")
        return
    
    var run: RunState = GameManager.current_run
    
    # Update land information
    var land_theme_display: String = run.current_land_theme.capitalize() if run.current_land_theme != "" else "Unknown"
    land_info_label.text = "Land: %d - %s" % [run.current_land, land_theme_display]
    
    # Update encounter progress
    var is_boss: bool = run.encounter_progress >= EncounterManager.ENCOUNTERS_PER_LAND
    var progress_text: String
    if is_boss:
        progress_text = "Boss Encounter"
    else:
        progress_text = "Encounter Progress: %d/%d" % [run.encounter_progress, EncounterManager.ENCOUNTERS_PER_LAND]
    encounter_progress_label.text = progress_text
    
    # Update party information (placeholder)
    _update_party_display(run.party)

func _update_party_display(party: Array[CharacterBattleEntity]) -> void:
    # Clear existing party info
    for child in party_info_container.get_children():
        child.queue_free()
    
    # Display party members
    for character in party:
        var char_label: Label = Label.new()
        var health_info: String = "HP: %d/%d" % [character.health.current, character.health.max_hp]
        var class_string = MinigameRegistry.get_class_type_string(character.class_type)
        char_label.text = "%s (%s) - %s" % [character.display_name, class_string, health_info]
        char_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        party_info_container.add_child(char_label)

func _on_continue_pressed() -> void:
    if GameManager.current_run == null:
        push_error("No current run available")
        return
    
    var run: RunState = GameManager.current_run
    
    # Check if land is complete (boss defeated or threshold reached)
    # encounter_progress was already incremented in Combat.complete_encounter()
    var is_boss: bool = run.encounter_progress >= EncounterManager.ENCOUNTERS_PER_LAND
    var land_complete: bool = is_boss
    
    if land_complete:
        _advance_to_next_land()
        # If run was completed, _advance_to_next_land() will have called _complete_run()
        # which ends the run and transitions to main menu, so we should not continue
        if GameManager.current_run == null:
            return
    
    # Transition to combat scene
    # Combat scene will load the encounter based on current run state
    SceneManager.go_to_combat()

func _advance_to_next_land() -> void:
    if GameManager.current_run == null:
        return
    
    var run: RunState = GameManager.current_run
    
    # Check if run is complete (land 5 boss defeated)
    if run.current_land >= 5:
        _complete_run()
        return
    
    # Advance to next land
    run.current_land += 1
    run.encounter_progress = 0
    
    # Set next land theme from sequence
    if run.land_sequence.size() >= run.current_land:
        run.current_land_theme = run.land_sequence[run.current_land - 1]
    else:
        push_error("Land sequence incomplete, using fallback")
        run.current_land_theme = "random"

func _complete_run() -> void:
    if GameManager.current_run == null:
        return
    
    print("Run completed! Victory!")
    GameManager.end_run(true)
    SceneManager.go_to_main_menu()
