class_name MainMenu
extends Control

@onready var new_run_button: Button = $VBoxContainer/NewRunButton
@onready var resume_button: Button = $VBoxContainer/ResumeButton
@onready var settings_button: Button = $VBoxContainer/SettingsButton

func _ready() -> void:
    new_run_button.pressed.connect(_on_new_run_pressed)
    resume_button.pressed.connect(_on_resume_pressed)
    settings_button.pressed.connect(_on_settings_pressed)
    
    # Check if there's a save to resume
    resume_button.disabled = not SaveManager.has_auto_save()

func _on_new_run_pressed() -> void:
    SceneManager.go_to_party_selection()

func _on_resume_pressed() -> void:
    if SaveManager.has_auto_save():
        var run_state: RunState = SaveManager.load_auto_save()
        if run_state:
            GameManager.current_run = run_state
            SceneManager.go_to_combat()

func _on_settings_pressed() -> void:
    # Placeholder for settings
    print("Settings not implemented yet")
