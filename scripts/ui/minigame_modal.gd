class_name MinigameModal
extends Control

# Modal container for minigames
# Displays minigame as an overlay on combat scene

signal modal_closed
signal minigame_result_received(result: MinigameResult)

var minigame_instance: BaseMinigame = null
var resolve_button: Button = null

func _ready() -> void:
    # Set up modal to cover full screen
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    mouse_filter = Control.MOUSE_FILTER_STOP
    
    # Create background overlay (darkened)
    var background: ColorRect = ColorRect.new()
    background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    background.color = Color(0, 0, 0, 0.7)  # Semi-transparent black
    background.mouse_filter = Control.MOUSE_FILTER_STOP
    add_child(background)
    
    # Create modal container (80% height, square aspect ratio)
    var modal_container: Control = Control.new()
    modal_container.name = "ModalContainer"
    var screen_size: Vector2 = get_viewport_rect().size
    var modal_height: float = screen_size.y * 0.8
    var modal_width: float = modal_height  # Square aspect ratio
    modal_container.custom_minimum_size = Vector2(modal_width, modal_height)
    modal_container.position = Vector2(
        (screen_size.x - modal_width) / 2,
        (screen_size.y - modal_height) / 2
    )
    add_child(modal_container)
    
    # Create panel for modal content
    var panel: Panel = Panel.new()
    panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    modal_container.add_child(panel)
    
    # Create container for minigame
    var minigame_container: Control = Control.new()
    minigame_container.name = "MinigameContainer"
    minigame_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    minigame_container.offset_bottom = -60  # Leave space for resolve button
    modal_container.add_child(minigame_container)
    
    # Create resolve button (for testing)
    resolve_button = Button.new()
    resolve_button.name = "ResolveButton"
    resolve_button.text = "Resolve (Test)"
    resolve_button.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    resolve_button.offset_top = modal_height - 50
    resolve_button.offset_bottom = -10
    resolve_button.offset_left = 10
    resolve_button.offset_right = -10
    resolve_button.pressed.connect(_on_resolve_pressed)
    modal_container.add_child(resolve_button)
    
    # Handle ESC key to close
    set_process_input(true)

func _input(event: InputEvent) -> void:
    if event.is_action_pressed("ui_cancel"):
        close_modal()

func load_minigame(minigame_scene_path: String, context: Dictionary) -> void:
    """Load and display a minigame scene with the given context."""
    # Clear any existing minigame
    if minigame_instance != null:
        minigame_instance.queue_free()
        minigame_instance = null
    
    # Load minigame scene
    var minigame_scene: PackedScene = load(minigame_scene_path)
    if minigame_scene == null:
        push_error("Failed to load minigame scene: " + minigame_scene_path)
        close_modal()
        return
    
    # Instantiate minigame
    minigame_instance = minigame_scene.instantiate() as BaseMinigame
    if minigame_instance == null:
        push_error("Failed to instantiate minigame from: " + minigame_scene_path)
        close_modal()
        return
    
    # Set context directly on minigame instance
    minigame_instance.character = context.get("character")
    minigame_instance.target = context.get("target", null)
    minigame_instance.minigame_context = context.get("data", {})
    
    # Add minigame to container
    var minigame_container: Control = get_node("ModalContainer/MinigameContainer")
    if minigame_container != null:
        minigame_container.add_child(minigame_instance)
        minigame_instance.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
        
        # Connect to minigame completion signal
        minigame_instance.minigame_completed.connect(_on_minigame_completed)
        
        # Initialize minigame after context is set and it's added to scene
        minigame_instance.initialize_minigame()
    else:
        push_error("MinigameContainer not found")
        close_modal()

func _on_resolve_pressed() -> void:
    """Create a test result and complete the minigame."""
    if minigame_instance == null:
        push_error("No minigame instance to resolve")
        return
    
    # Create test result
    var test_result: MinigameResult = MinigameResult.new(true, 0.5)
    test_result.damage = 10
    test_result.effects = []
    test_result.metadata = {}
    
    # Complete minigame with test result
    minigame_instance.complete_minigame(test_result)

func _on_minigame_completed(result: MinigameResult) -> void:
    """Handle minigame completion - emit signal and close modal."""
    # Emit signal with result (combat scene will handle it)
    minigame_result_received.emit(result)
    modal_closed.emit()
    close_modal()

func close_modal() -> void:
    """Close the modal and clean up."""
    # Disconnect signals
    if minigame_instance != null:
        if minigame_instance.minigame_completed.is_connected(_on_minigame_completed):
            minigame_instance.minigame_completed.disconnect(_on_minigame_completed)
    
    # Queue free
    queue_free()
