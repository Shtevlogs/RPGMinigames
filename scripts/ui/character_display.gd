class_name CharacterDisplay
extends VBoxContainer

@onready var name_label: Label = $NameLabel
@onready var health_bar: ProgressBar = $HealthBar
@onready var attributes_label: Label = $AttributesLabel

var character: Character = null
var status_effects_container: HBoxContainer = null
var highlight_panel: Panel = null  # For turn highlighting border

func _ready() -> void:
    # Create status effects container
    status_effects_container = HBoxContainer.new()
    status_effects_container.name = "StatusEffectsContainer"
    status_effects_container.custom_minimum_size = Vector2(0, 20)
    add_child(status_effects_container)
    move_child(status_effects_container, 1)  # Place after name label

func set_character(character_ref: Character) -> void:
    character = character_ref

func update_display() -> void:
    if character == null:
        return
    
    name_label.text = character.display_name
    health_bar.max_value = character.health.max_hp
    health_bar.value = character.health.current
    
    var attrs: Attributes = character.get_effective_attributes()
    attributes_label.text = "P:%d S:%d St:%d Sp:%d L:%d" % [
        attrs.power, attrs.skill, attrs.strategy, attrs.speed, attrs.luck
    ]
    
    # Update grey-out for dead characters
    if not character.is_alive():
        modulate = Color(0.5, 0.5, 0.5, 1.0)  # Grey out
    else:
        modulate = Color.WHITE
    
    # Update status effects display
    _update_status_effects_display()

func set_highlighted(highlight: bool) -> void:
    """Set highlight border for turn indication."""
    if highlight:
        if highlight_panel == null:
            # Create highlight panel
            highlight_panel = Panel.new()
            highlight_panel.name = "HighlightPanel"
            highlight_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
            var style: StyleBoxFlat = StyleBoxFlat.new()
            style.bg_color = Color.TRANSPARENT
            style.border_width_left = 3
            style.border_width_right = 3
            style.border_width_top = 3
            style.border_width_bottom = 3
            style.border_color = Color.CYAN
            highlight_panel.add_theme_stylebox_override("panel", style)
            add_child(highlight_panel)
            move_child(highlight_panel, 0)  # Move to front
        highlight_panel.visible = true
    else:
        if highlight_panel != null:
            highlight_panel.visible = false

func _update_status_effects_display() -> void:
    if status_effects_container == null or character == null:
        return

    # Clear existing status effect indicators
    for child in status_effects_container.get_children():
        child.queue_free()
    
    # Create indicators for each status effect
    for effect in character.status_effects:
        var visual_data: Dictionary = effect.get_visual_data()
        var indicator: Control = _create_status_effect_indicator(effect, visual_data)
        status_effects_container.add_child(indicator)

func _create_status_effect_indicator(effect: StatusEffect, visual_data: Dictionary) -> Control:
    return StatusEffectDisplayHelper.create_status_effect_indicator(effect, visual_data)

func _process(_delta: float) -> void:
    if character != null:
        update_display()
