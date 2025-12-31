class_name TimeWizardMinigame
extends BaseMinigame

const TIME_WIZARD_MINIGAME_CONTEXT = preload("res://scripts/data/time_wizard_minigame_context.gd")
const TIME_WIZARD_MINIGAME_RESULT_DATA = preload("res://scripts/data/time_wizard_minigame_result_data.gd")

# Time Wizard minigame - Minesweeper analogue with time-based mechanics
# Core minesweeper mechanics with timeline events, time limit, and completion-based damage

# Square state representation
class Square:
    var revealed: bool = false
    var flagged: bool = false
    var is_event: bool = false
    var event_symbol: int = 0  # 0 = triangle, 1 = square, 2 = pentagon, 3 = hexagon, etc.
    var nearby_count: int = 0  # Number of adjacent events (minesweeper logic)
    var nearby_event_symbols: Array[int] = []  # Non-repeating array of nearby event symbol types
    
    func _init():
        revealed = false
        flagged = false
        is_event = false
        event_symbol = 0
        nearby_count = 0
        nearby_event_symbols = []

# UI References
var time_label: Label = null
var status_label: Label = null
var completion_label: Label = null
var grid_container: GridContainer = null
var activate_event_button: Button = null

# Game state
var grid: Array[Array] = []  # 2D array of Square objects
var board_size: int = 4
var event_count: int = 1
var time_limit: float = 10.0
var time_remaining: float = 10.0
var revealed_count: int = 0
var total_squares: int = 16
var game_complete: bool = false
var selected_event: Vector2i = Vector2i(-1, -1)  # Position of selected event for activation
var first_click: bool = true  # Track first click to ensure it's safe
var timer: Timer = null
var square_buttons: Array[Array] = []  # 2D array of Button references

# Event symbols (polygon types)
const EVENT_SYMBOL_TRIANGLE: int = 0
const EVENT_SYMBOL_SQUARE: int = 1
const EVENT_SYMBOL_PENTAGON: int = 2
const EVENT_SYMBOL_HEXAGON: int = 3

func _setup_ui_references() -> void:
    """Set up UI node references. Can be called multiple times safely."""
    if time_label != null:
        return  # Already set up
    
    var vbox: VBoxContainer = get_node_or_null("VBoxContainer")
    if vbox != null:
        time_label = vbox.get_node_or_null("TimeLabel") as Label
        status_label = vbox.get_node_or_null("StatusLabel") as Label
        completion_label = vbox.get_node_or_null("CompletionLabel") as Label
        grid_container = vbox.get_node_or_null("GridContainer") as GridContainer
        activate_event_button = vbox.get_node_or_null("ActivateEventButton") as Button

func initialize_minigame() -> void:
    # Set up UI references if not already done
    _setup_ui_references()
    
    # Wait for UI to be ready if needed
    if time_label == null:
        await get_tree().process_frame
        _setup_ui_references()
    
    # Cast context to TimeWizardMinigameContext
    var context = minigame_context as TimeWizardMinigameContext
    if context == null:
        push_error("Invalid context type for TimeWizardMinigame")
        return
    
    # Get context data from typed context
    board_size = context.board_size
    time_limit = context.time_limit
    event_count = context.event_count
    
    # TODO: Load board_state from context (pre-cleared squares from basic attacks)
    # EQUIPMENT HOOK: Board state persistence from basic attacks
    # board_state is available as context.board_state
    
    # Initialize game state
    time_remaining = time_limit
    revealed_count = 0
    total_squares = board_size * board_size
    game_complete = false
    selected_event = Vector2i(-1, -1)
    first_click = true
    
    # Initialize grid
    _initialize_grid()
    
    # Set up timer
    _setup_timer()
    
    # Update UI
    _update_display()
    _update_grid_display()

func _initialize_grid() -> void:
    """Initialize the grid with empty squares."""
    grid.clear()
    square_buttons.clear()
    
    # Create 2D array of squares
    for y in range(board_size):
        var row: Array = []
        var button_row: Array = []
        for x in range(board_size):
            row.append(Square.new())
            button_row.append(null)
        grid.append(row)
        square_buttons.append(button_row)
    
    # TODO: Apply pre-cleared squares from board_state
    # EQUIPMENT HOOK: Apply board state from basic attacks

func _place_events(safe_x: int, safe_y: int) -> void:
    """Place events randomly on the board, ensuring the first click is safe."""
    var events_placed: int = 0
    var max_attempts: int = 1000
    
    # Ensure we don't place more events than squares (minus the safe square)
    var max_events: int = min(event_count, total_squares - 1)
    
    while events_placed < max_events and max_attempts > 0:
        var x: int = randi() % board_size
        var y: int = randi() % board_size
        
        # Skip if this is the safe square or already has an event
        if (x == safe_x and y == safe_y) or grid[y][x].is_event:
            max_attempts -= 1
            continue
        
        # Place event with random symbol
        grid[y][x].is_event = true
        grid[y][x].event_symbol = events_placed % 4  # Cycle through symbols
        events_placed += 1
        max_attempts -= 1
    
    # Calculate nearby counts for all squares
    _calculate_nearby_counts()

func _calculate_nearby_counts() -> void:
    """Calculate the number of adjacent events for each square (minesweeper logic)."""
    for y in range(board_size):
        for x in range(board_size):
            if grid[y][x].is_event:
                continue  # Events don't need counts
            
            var count: int = 0
            var nearby_symbols: Array[int] = []
            
            # Check all 8 adjacent squares
            for dy in range(-1, 2):
                for dx in range(-1, 2):
                    if dx == 0 and dy == 0:
                        continue
                    
                    var nx: int = x + dx
                    var ny: int = y + dy
                    
                    if nx >= 0 and nx < board_size and ny >= 0 and ny < board_size:
                        if grid[ny][nx].is_event:
                            count += 1
                            var symbol: int = grid[ny][nx].event_symbol
                            if not nearby_symbols.has(symbol):
                                nearby_symbols.append(symbol)
            
            grid[y][x].nearby_count = count
            grid[y][x].nearby_event_symbols = nearby_symbols

func _setup_timer() -> void:
    """Set up the countdown timer."""
    if timer == null:
        timer = Timer.new()
        timer.wait_time = 0.1  # Update every 0.1 seconds
        timer.timeout.connect(_on_timer_tick)
        add_child(timer)
    
    timer.start()

func _on_timer_tick() -> void:
    """Handle timer tick - update time remaining."""
    if game_complete:
        return
    
    time_remaining -= 0.1
    if time_remaining <= 0.0:
        time_remaining = 0.0
        _on_time_expired()
    
    _update_display()

func _on_time_expired() -> void:
    """Handle time expiration - auto-complete minigame."""
    if game_complete:
        return
    
    game_complete = true
    if timer != null:
        timer.stop()
    
    # Reveal all remaining squares
    for y in range(board_size):
        for x in range(board_size):
            if not grid[y][x].revealed:
                grid[y][x].revealed = true
                revealed_count += 1
    
    _update_grid_display()
    _complete_minigame()

func _reveal_square(x: int, y: int) -> void:
    """Reveal a square and cascade if needed."""
    if x < 0 or x >= board_size or y < 0 or y >= board_size:
        return
    
    if grid[y][x].revealed:
        return  # Already revealed
    
    # Clear flag if present (flags only apply to unrevealed squares)
    grid[y][x].flagged = false
    
    # Reveal the square
    grid[y][x].revealed = true
    revealed_count += 1
    
    # If this is the first click, place events (ensuring this square is safe)
    if first_click:
        first_click = false
        _place_events(x, y)
        _update_grid_display()  # Update to show the safe square
    
    # If this square has no nearby events, cascade reveal adjacent squares
    if grid[y][x].nearby_count == 0 and not grid[y][x].is_event:
        for dy in range(-1, 2):
            for dx in range(-1, 2):
                if dx == 0 and dy == 0:
                    continue
                _reveal_square(x + dx, y + dy)
    
    _update_grid_display()

func _on_square_clicked(x: int, y: int) -> void:
    """Handle square button left-click."""
    if game_complete:
        return
    
    # Ignore clicks on flagged squares
    if grid[y][x].flagged:
        return
    
    if grid[y][x].revealed:
        # If already revealed and is an event, activate immediately
        if grid[y][x].is_event:
            selected_event = Vector2i(x, y)
            _activate_event()
        return
    
    # Reveal the square
    _reveal_square(x, y)
    
    # Check if an event was revealed - if so, activate immediately
    if grid[y][x].is_event:
        selected_event = Vector2i(x, y)
        _activate_event()
        return
    
    _update_display()

func _on_square_gui_input(x: int, y: int, event: InputEvent) -> void:
    """Handle GUI input events (for right-click detection)."""
    if event is InputEventMouseButton:
        var mouse_event: InputEventMouseButton = event as InputEventMouseButton
        if mouse_event.button_index == MOUSE_BUTTON_RIGHT and mouse_event.pressed:
            _on_square_right_clicked(x, y)

func _on_square_right_clicked(x: int, y: int) -> void:
    """Handle square button right-click for flagging."""
    if game_complete:
        return
    
    # Do nothing on revealed squares
    if grid[y][x].revealed:
        return
    
    # Toggle flag
    grid[y][x].flagged = not grid[y][x].flagged
    
    # Update display to show flag state
    _update_grid_display()

func _activate_event() -> void:
    """Activate the selected event and complete minigame."""
    if game_complete or selected_event.x < 0 or selected_event.y < 0:
        return
    
    # Complete minigame with event activation
    game_complete = true
    if timer != null:
        timer.stop()
    
    _update_display()
    _complete_minigame()

func _on_activate_event_button_pressed() -> void:
    """Handle event activation button press (kept for compatibility, but events now activate on click)."""
    _activate_event()

func _update_grid_display() -> void:
    """Update the grid display with current square states."""
    if grid_container == null:
        return
    
    # Clear existing buttons
    for row in square_buttons:
        for button in row:
            if is_instance_valid(button):
                button.queue_free()
    
    square_buttons.clear()
    
    # Set grid container columns
    grid_container.columns = board_size
    
    # Create buttons for each square
    for y in range(board_size):
        var button_row: Array = []
        for x in range(board_size):
            var button: Button = Button.new()
            var square: Square = grid[y][x]
            
            if square.revealed:
                if square.is_event:
                    # Show event symbol
                    button.text = _get_event_symbol_text(square.event_symbol)
                    button.modulate = Color.YELLOW
                    button.disabled = false
                else:
                    # Show number or space character
                    if square.nearby_count > 0:
                        button.text = str(square.nearby_count)
                    else:
                        button.text = " "  # Space character when no number
                    button.modulate = Color.WHITE
                    button.disabled = true
            else:
                # Hidden square - show flag or question mark
                if square.flagged:
                    button.text = "🚩"  # Flag emoji
                    button.modulate = Color.RED
                else:
                    button.text = "?"
                    button.modulate = Color.GRAY
                button.disabled = false
            
            # Connect signals
            var square_x: int = x
            var square_y: int = y
            button.pressed.connect(func(): _on_square_clicked(square_x, square_y))
            
            # Connect right-click signal (using gui_input signal)
            button.gui_input.connect(func(event): _on_square_gui_input(square_x, square_y, event))
            
            grid_container.add_child(button)
            button_row.append(button)
        
        square_buttons.append(button_row)
    
    # Update activate button state
    if activate_event_button != null:
        var can_activate: bool = (not game_complete and 
                                 selected_event.x >= 0 and 
                                 selected_event.y >= 0 and
                                 grid[selected_event.y][selected_event.x].revealed and
                                 grid[selected_event.y][selected_event.x].is_event)
        activate_event_button.disabled = not can_activate

func _get_event_symbol_text(symbol: int) -> String:
    """Get text representation of event symbol."""
    match symbol:
        EVENT_SYMBOL_TRIANGLE:
            return "△"
        EVENT_SYMBOL_SQUARE:
            return "□"
        EVENT_SYMBOL_PENTAGON:
            return "⬟"
        EVENT_SYMBOL_HEXAGON:
            return "⬡"
        _:
            return "?"

func _update_display() -> void:
    """Update UI display with current game state."""
    if time_label == null:
        return  # UI not ready yet
    
    # Update time remaining
    time_label.text = "Time Remaining: %.1f" % time_remaining
    
    # Update status
    if status_label != null:
        if game_complete:
            status_label.text = "Complete!"
            status_label.modulate = Color.GREEN
        elif selected_event.x >= 0 and selected_event.y >= 0:
            status_label.text = "Event selected - Click Activate to trigger"
            status_label.modulate = Color.YELLOW
        else:
            status_label.text = "Click squares to reveal them"
            status_label.modulate = Color.WHITE
    
    # Update completion percentage
    if completion_label != null:
        var completion: float = float(revealed_count) / float(total_squares) * 100.0
        completion_label.text = "Board Completion: %.1f%% (%d/%d)" % [completion, revealed_count, total_squares]

func _calculate_completion_percentage() -> float:
    """Calculate board completion percentage (0.0-1.0)."""
    return float(revealed_count) / float(total_squares)

func _is_mega_time_burst() -> bool:
    """Check if all non-event squares are cleared (Mega Time Burst condition)."""
    for y in range(board_size):
        for x in range(board_size):
            if not grid[y][x].is_event and not grid[y][x].revealed:
                return false
    return true

func _complete_minigame() -> void:
    """Complete the minigame and create result."""
    var completion: float = _calculate_completion_percentage()
    var is_event_activated: bool = (selected_event.x >= 0 and selected_event.y >= 0)
    var is_mega_burst: bool = _is_mega_time_burst() and not is_event_activated
    
    # Calculate damage
    var damage: int = _calculate_damage(completion, is_event_activated, is_mega_burst)
    
    # Create result
    var result: MinigameResult = MinigameResult.new(true, completion)
    
    # Create action with source, target and damage
    var action = Action.new(character)
    if target != null:
        action.targets.append(target)
    action.damage = damage
    
    result.actions.append(action)
    
    # Create result data
    var result_data = TIME_WIZARD_MINIGAME_RESULT_DATA.new()
    result_data.completion_percentage = completion
    result_data.event_activated = is_event_activated
    result_data.mega_time_burst = is_mega_burst
    result_data.time_expired = (time_remaining <= 0.0)
    result_data.revealed_count = revealed_count
    result_data.total_squares = total_squares
    
    if is_event_activated:
        var event_square: Square = grid[selected_event.y][selected_event.x]
        result_data.event_symbol = event_square.event_symbol
        result_data.event_symbol_text = _get_event_symbol_text(event_square.event_symbol)
        # EQUIPMENT HOOK: Event position-based targeting (left = first enemy, etc.)
        result_data.event_position = {"x": selected_event.x, "y": selected_event.y}
    
    result.result_data = result_data
    
    # EQUIPMENT HOOK: Apply event-specific effects based on symbol
    # TODO: Apply effects based on event symbol type
    
    # Complete minigame
    complete_minigame(result)

func _calculate_damage(completion: float, is_event_activated: bool, is_mega_burst: bool) -> int:
    """Calculate damage based on completion percentage and outcome type."""
    if character == null:
        return 0
    
    # Get base attack damage (Power attribute)
    var effective_attrs: Attributes = character.get_effective_attributes()
    var base_damage: int = effective_attrs.power
    
    # EQUIPMENT HOOK: Apply Luck-based damage scaling
    var luck_multiplier: float = 1.0 + (effective_attrs.luck * 0.1)  # 10% per luck point
    
    var damage_multiplier: float = 1.0
    
    if is_mega_burst:
        # Mega Time Burst - highest damage
        damage_multiplier = 2.0 + completion  # 2.0x to 3.0x based on completion
    elif is_event_activated:
        # Event activation - scales with completion
        damage_multiplier = 1.0 + (completion * 1.5)  # 1.0x to 2.5x
    else:
        # Time Burst - standard damage spell
        damage_multiplier = 0.5 + completion  # 0.5x to 1.5x
    
    return int(base_damage * damage_multiplier * luck_multiplier)

static func build_context(_character: CharacterBattleEntity, _target: BattleEntity) -> Dictionary:
    """Build context data for Time Wizard minigame."""
    # This is handled by TimeWizardBehavior.build_minigame_context()
    # This method exists for consistency with other minigames
    return {}

func _ready() -> void:
    # Set up UI references
    _setup_ui_references()
    
    # Wait for UI to be ready
    await get_tree().process_frame
    _setup_ui_references()
    
    # Connect button signals if they exist
    if activate_event_button != null:
        if not activate_event_button.pressed.is_connected(_on_activate_event_button_pressed):
            activate_event_button.pressed.connect(_on_activate_event_button_pressed)
    
    # Update display if game is already initialized
    if not grid.is_empty():
        _update_display()
        _update_grid_display()
