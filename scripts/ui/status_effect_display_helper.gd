class_name StatusEffectDisplayHelper
extends RefCounted

# Static utility class for creating status effect display indicators
# Shared between CharacterDisplay and EnemyDisplay

static func create_status_effect_indicator(effect: StatusEffect, visual_data: Dictionary) -> Control:
    # Create a container for the status effect indicator
    var container: Control = Control.new()
    container.custom_minimum_size = Vector2(30, 30)
    container.tooltip_text = "%s (%d turns)" % [effect.get_effect_name(), effect.duration]
    
    # Create background panel
    var panel: Panel = Panel.new()
    panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    var style: StyleBoxFlat = StyleBoxFlat.new()
    style.bg_color = visual_data.get("color", Color.WHITE)
    style.bg_color.a = 0.7
    style.border_width_left = 1
    style.border_width_right = 1
    style.border_width_top = 1
    style.border_width_bottom = 1
    style.border_color = Color.BLACK
    panel.add_theme_stylebox_override("panel", style)
    container.add_child(panel)
    
    # Create label for effect name (first letter) or stack count
    var label: Label = Label.new()
    label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    label.add_theme_font_size_override("font_size", 12)
    label.add_theme_color_override("font_color", Color.BLACK)
    
    if visual_data.get("show_stacks", false) and effect.stacks > 1:
        label.text = str(effect.stacks)
    else:
        label.text = effect.get_effect_name().substr(0, 1)
    
    container.add_child(label)
    
    return container

