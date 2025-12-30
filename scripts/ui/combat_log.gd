class_name CombatLog
extends Control

enum EventType {
    ATTACK,
    DAMAGE,
    HEALING,
    STATUS_EFFECT,
    DEATH,
    ABILITY,
    ITEM,
    BUFF,
    DEBUFF,
    TURN_START,
    SPECIAL
}

@onready var log_container: VBoxContainer = $LogContainer

const MAX_LOG_ENTRIES: int = 50  # Reduced since we're showing fewer at once
const FADE_DURATION: float = 3.0  # Seconds before fade starts
const FADE_TIME: float = 2.0  # Seconds to fade out

var log_labels: Array[Label] = []

func _ready() -> void:
    # Initialize with empty log
    clear_log()

func clear_log() -> void:
    """Clear all log entries. Should be called at encounter start."""
    # Remove all existing labels
    for label in log_labels:
        if is_instance_valid(label):
            label.queue_free()
    log_labels.clear()

func add_entry(message: String, event_type: EventType = EventType.SPECIAL) -> void:
    """Add a new log entry with color coding based on event type."""
    if log_container == null:
        return
    
    # Create new label
    var label: Label = Label.new()
    label.text = message
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
    label.add_theme_color_override("font_color", _get_color_for_event_type(event_type))
    label.add_theme_font_size_override("font_size", 14)
    
    # Add to container
    log_container.add_child(label)
    log_labels.append(label)
    
    # Limit log size - remove oldest entries
    if log_labels.size() > MAX_LOG_ENTRIES:
        var oldest_label: Label = log_labels.pop_front()
        if is_instance_valid(oldest_label):
            oldest_label.queue_free()
    
    # Start fade animation
    _start_fade_animation(label)

func _get_color_for_event_type(event_type: EventType) -> Color:
    """Get color for event type."""
    match event_type:
        EventType.ATTACK:
            return Color("#FFA500")  # Orange
        EventType.DAMAGE:
            return Color("#FF6B6B")  # Red
        EventType.HEALING:
            return Color("#51CF66")  # Green
        EventType.STATUS_EFFECT:
            return Color("#FFD93D")  # Yellow
        EventType.DEATH:
            return Color("#C92A2A")  # Dark red
        EventType.ABILITY:
            return Color("#4DABF7")  # Cyan/Blue
        EventType.ITEM:
            return Color("#E9ECEF")  # Light gray/White
        EventType.BUFF:
            return Color("#A5D8FF")  # Light blue
        EventType.DEBUFF:
            return Color("#FFA8A8")  # Light red
        EventType.TURN_START:
            return Color("#74C0FC")  # Light cyan
        _:
            return Color.WHITE

func _start_fade_animation(label: Label) -> void:
    """Start fade animation for a label. Runs asynchronously."""
    _fade_label_async(label)

func _fade_label_async(label: Label) -> void:
    """Async function to fade out a label."""
    if label == null or not is_instance_valid(label):
        return
    
    # Wait for fade duration before starting fade
    await get_tree().create_timer(FADE_DURATION).timeout
    
    # Check if label still exists
    if not is_instance_valid(label):
        return
    
    # Create tween for fade
    var tween: Tween = create_tween()
    tween.set_parallel(false)
    tween.tween_property(label, "modulate:a", 0.0, FADE_TIME)
    
    # Remove label after fade completes
    await tween.finished
    if is_instance_valid(label):
        # Remove from array if still present
        if log_labels.has(label):
            log_labels.erase(label)
        label.queue_free()
