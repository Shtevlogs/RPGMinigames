class_name EnemyDisplay
extends VBoxContainer

signal enemy_clicked(enemy: EnemyData)

@onready var name_label: Label = $NameLabel
@onready var health_bar: ProgressBar = $HealthBar

var enemy_data: EnemyData = null
var is_selectable: bool = false
var status_effects_container: HBoxContainer = null
var glow_sprite: Sprite2D = null  # For turn highlighting glow

func _ready() -> void:
    # Ensure mouse input is enabled
    mouse_filter = MOUSE_FILTER_STOP
    # Create status effects container
    status_effects_container = HBoxContainer.new()
    status_effects_container.name = "StatusEffectsContainer"
    status_effects_container.custom_minimum_size = Vector2(0, 20)
    add_child(status_effects_container)
    move_child(status_effects_container, 1)  # Place after name label

func set_enemy(enemy_ref: EnemyData) -> void:
    enemy_data = enemy_ref

func set_selectable(selectable: bool) -> void:
    is_selectable = selectable
    _update_highlight()

func _update_highlight() -> void:
    # Visual feedback for selectable enemies
    if is_selectable:
        modulate = Color(1.2, 1.2, 1.0, 1.0)  # Slight yellow tint
    else:
        modulate = Color.WHITE

func update_display() -> void:
    if enemy_data == null:
        return
    
    name_label.text = enemy_data.display_name
    health_bar.max_value = enemy_data.health.max_hp
    health_bar.value = enemy_data.health.current
    
    # Update status effects display
    _update_status_effects_display()

func set_highlighted(highlight: bool) -> void:
    """Set glow effect for turn indication."""
    if highlight:
        if glow_sprite == null:
            # TODO: Create actual glow sprite
            # For now, use modulate as placeholder
            modulate = Color(1.2, 1.2, 1.0, 1.0)
    else:
        if glow_sprite != null:
            # TODO: Remove glow sprite
            pass
        # Reset modulate if not selectable
        if not is_selectable:
            modulate = Color.WHITE

func _update_status_effects_display() -> void:
    if status_effects_container == null or enemy_data == null:
        return
    
    # Clear existing status effect indicators
    for child in status_effects_container.get_children():
        child.queue_free()
    
    # Create indicators for each status effect
    for effect in enemy_data.status_effects:
        var visual_data: Dictionary = effect.get_visual_data()
        var indicator: Control = _create_status_effect_indicator(effect, visual_data)
        status_effects_container.add_child(indicator)

func _create_status_effect_indicator(effect: StatusEffect, visual_data: Dictionary) -> Control:
    return StatusEffectDisplayHelper.create_status_effect_indicator(effect, visual_data)

func _gui_input(event: InputEvent) -> void:
    if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
        if is_selectable and enemy_data != null and enemy_data.health.is_alive():
            enemy_clicked.emit(enemy_data)

func _process(_delta: float) -> void:
    if enemy_data != null:
        update_display()
