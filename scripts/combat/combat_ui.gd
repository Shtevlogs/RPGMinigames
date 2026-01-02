class_name CombatUI
extends RefCounted

var battle_state: BattleState
var party_container: HBoxContainer
var enemy_container: Control
var turn_order_container: HBoxContainer

func _init(p_battle_state: BattleState, p_party_container: HBoxContainer, p_enemy_container: Control, p_turn_order_container: HBoxContainer):
    battle_state = p_battle_state
    party_container = p_party_container
    enemy_container = p_enemy_container
    turn_order_container = p_turn_order_container

func update_party_displays() -> void:
    for child in party_container.get_children():
        if child is CharacterDisplay:
            var char_display: CharacterDisplay = child as CharacterDisplay
            char_display.update_display()

func update_enemy_displays() -> void:
    for child in enemy_container.get_children():
        if child is EnemyDisplay:
            var enemy_display: EnemyDisplay = child as EnemyDisplay
            enemy_display.update_display()

func update_turn_order_display() -> void:
    if turn_order_container == null:
        return
    
    var container: HBoxContainer = turn_order_container
    # Clear existing children
    for child in container.get_children():
        child.queue_free()
    
    # Create UI entries for each turn order entry
    for i in range(battle_state.turn_order.size()):
        var entry: TurnOrderEntry = battle_state.turn_order[i]
        var entry_ui: Control = _create_turn_order_entry_ui(entry, i == battle_state.current_turn_index)
        container.add_child(entry_ui)

func highlight_party_member(character: CharacterBattleEntity, highlight: bool) -> void:
    for child in party_container.get_children():
        if child is CharacterDisplay:
            var char_display: CharacterDisplay = child as CharacterDisplay
            if char_display.character == character:
                char_display.set_highlighted(highlight)

func highlight_enemy(enemy: EnemyBattleEntity, highlight: bool) -> void:
    for child in enemy_container.get_children():
        if child is EnemyDisplay:
            var enemy_display: EnemyDisplay = child as EnemyDisplay
            if enemy_display.enemy_data == enemy:
                enemy_display.set_highlighted(highlight)

func display_party() -> void:
    # Clear existing
    for child in party_container.get_children():
        child.queue_free()
    
    # Display party members from BattleState
    if battle_state != null and not battle_state.party_states.is_empty():
        for character in battle_state.party_states:
            var char_ui: Node = preload("res://ui/character_display.tscn").instantiate()
            char_ui.set_character(character)
            party_container.add_child(char_ui)

func display_enemies(encounter: Encounter, enemy_click_handler: Callable = Callable()) -> void:
    # Clear existing
    clear_enemies()
    
    # Display enemies from BattleState
    var enemies_to_display: Array[EnemyBattleEntity] = []
    if battle_state != null and not battle_state.enemy_states.is_empty():
        enemies_to_display = battle_state.enemy_states
    
    if enemies_to_display.is_empty():
        return
    
    # Display enemies using formation positions
    for i in range(enemies_to_display.size()):
        var enemy: EnemyBattleEntity = enemies_to_display[i]
        var enemy_ui: Node = preload("res://ui/enemy_display.tscn").instantiate()
        
        # Cast to EnemyDisplay to access methods
        if enemy_ui is EnemyDisplay:
            var enemy_display: EnemyDisplay = enemy_ui as EnemyDisplay
            enemy_display.set_enemy(enemy)
            # Connect click signal if handler provided
            if enemy_click_handler.is_valid():
                enemy_display.enemy_clicked.connect(enemy_click_handler)
        
        # Position using formation coordinates
        if encounter != null and i < encounter.enemy_formation.size():
            enemy_ui.position = encounter.enemy_formation[i]
        else:
            # Fallback positioning if formation array is shorter than composition
            enemy_ui.position = Vector2(i * 150, 0)
        
        enemy_container.add_child(enemy_ui)

func clear_enemies() -> void:
    for child in enemy_container.get_children():
        child.queue_free()

func update_enemy_selectability(selectable: bool) -> void:
    for child in enemy_container.get_children():
        if child is EnemyDisplay:
            var enemy_display: EnemyDisplay = child as EnemyDisplay
            if enemy_display.enemy_data != null and enemy_display.enemy_data.is_alive():
                enemy_display.set_selectable(selectable)
            else:
                enemy_display.set_selectable(false)

func get_enemy_position(enemy: EnemyBattleEntity) -> Vector2:
    for child in enemy_container.get_children():
        if child is EnemyDisplay:
            var enemy_display: EnemyDisplay = child as EnemyDisplay
            if enemy_display.enemy_data == enemy:
                return enemy_display.global_position + enemy_display.size / 2
    return Vector2.ZERO

func remove_enemy_display(enemy: EnemyBattleEntity) -> void:
    for child in enemy_container.get_children():
        if child is EnemyDisplay:
            var enemy_display: EnemyDisplay = child as EnemyDisplay
            if enemy_display.enemy_data == enemy:
                child.queue_free()
                break

func _create_turn_order_entry_ui(entry: TurnOrderEntry, is_current: bool) -> Control:
    var container: Control = Control.new()
    container.custom_minimum_size = Vector2(100, 60)
    
    # Background panel
    var panel: Panel = Panel.new()
    panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    if is_current:
        panel.add_theme_stylebox_override("panel", StyleBoxFlat.new())
        var style: StyleBoxFlat = panel.get_theme_stylebox("panel")
        style.bg_color = Color(1.0, 1.0, 0.0, 0.3)  # Semi-transparent yellow
        style.border_width_left = 2
        style.border_width_right = 2
        style.border_width_top = 2
        style.border_width_bottom = 2
        style.border_color = Color.YELLOW
    container.add_child(panel)
    
    # Content container
    var content: VBoxContainer = VBoxContainer.new()
    content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    content.add_theme_constant_override("separation", 2)
    container.add_child(content)
    
    # Name label
    var name_label: Label = Label.new()
    name_label.text = entry.display_name
    name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    name_label.add_theme_font_size_override("font_size", 14)
    if is_current:
        name_label.add_theme_color_override("font_color", Color.YELLOW)
    elif entry.is_party:
        name_label.add_theme_color_override("font_color", Color.CYAN)
    else:
        name_label.add_theme_color_override("font_color", Color.RED)
    content.add_child(name_label)
    
    # Turn value label
    var value_label: Label = Label.new()
    value_label.text = "Value: " + str(entry.turn_value)
    value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    value_label.add_theme_font_size_override("font_size", 12)
    value_label.add_theme_color_override("font_color", Color.WHITE)
    content.add_child(value_label)
    
    return container
