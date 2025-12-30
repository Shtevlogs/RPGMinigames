class_name MonkMinigame
extends BaseMinigame

# Monk minigame - Rock Paper Scissors implementation
# Core RPS mechanics with enemy cards, win/loss/tie effects, and redo system

# RPS move types
const MOVE_STRIKE: String = "strike"  # Rock
const MOVE_GRAPPLE: String = "grapple"  # Paper
const MOVE_COUNTER: String = "counter"  # Scissors

# RPS card types
const CARD_ROCK: String = "rock"
const CARD_PAPER: String = "paper"
const CARD_SCISSORS: String = "scissors"

# Enemy card representation
class EnemyCard:
    var rps_type: String  # "rock", "paper", or "scissors"
    var win_effect: Dictionary = {}  # Stubbed for equipment
    var loss_effect: Dictionary = {}  # Stubbed for equipment
    var tie_effect: Dictionary = {}  # Stubbed for equipment
    
    func _init(p_rps_type: String):
        rps_type = p_rps_type
    
    func get_display_name() -> String:
        match rps_type:
            CARD_ROCK:
                return "Rock"
            CARD_PAPER:
                return "Paper"
            CARD_SCISSORS:
                return "Scissors"
            _:
                return "Unknown"

# UI References (will be set in _ready)
var status_label: Label = null
var enemy_cards_label: Label = null
var current_card_label: Label = null
var outcome_label: Label = null
var redo_counter_label: Label = null
var strike_button: Button = null
var grapple_button: Button = null
var counter_button: Button = null
var redo_button: Button = null
var confirm_button: Button = null

# Game state
var enemy_cards: Array[EnemyCard] = []
var player_move: String = ""  # Player's chosen move
var selected_enemy_card: EnemyCard = null  # Enemy's randomly selected card
var outcome: String = ""  # "win", "loss", or "tie"
var redos_available: int = 0  # Redos from Speed attribute (0-3)
var redos_used: int = 0  # How many redos have been used
var game_complete: bool = false

func _setup_ui_references() -> void:
    """Set up UI node references. Can be called multiple times safely."""
    if status_label != null:
        return  # Already set up
    
    var vbox: VBoxContainer = get_node_or_null("VBoxContainer")
    if vbox != null:
        status_label = vbox.get_node_or_null("StatusLabel") as Label
        enemy_cards_label = vbox.get_node_or_null("EnemyCardsLabel") as Label
        current_card_label = vbox.get_node_or_null("CurrentCardLabel") as Label
        outcome_label = vbox.get_node_or_null("OutcomeLabel") as Label
        redo_counter_label = vbox.get_node_or_null("RedoCounterLabel") as Label
        
        var move_container: HBoxContainer = vbox.get_node_or_null("MoveContainer") as HBoxContainer
        if move_container != null:
            strike_button = move_container.get_node_or_null("StrikeButton") as Button
            grapple_button = move_container.get_node_or_null("GrappleButton") as Button
            counter_button = move_container.get_node_or_null("CounterButton") as Button
        
        var button_container: HBoxContainer = vbox.get_node_or_null("ButtonContainer") as HBoxContainer
        if button_container != null:
            redo_button = button_container.get_node_or_null("RedoButton") as Button
            confirm_button = button_container.get_node_or_null("ConfirmButton") as Button

func initialize_minigame() -> void:
    # Set up UI references if not already done
    _setup_ui_references()
    
    # Wait for UI to be ready if needed
    if status_label == null:
        await get_tree().process_frame
        _setup_ui_references()
    
    # Get context data
    redos_available = minigame_context.get("redos_available", 0)
    redos_used = 0
    player_move = ""
    selected_enemy_card = null
    outcome = ""
    game_complete = false
    
    # Generate enemy cards
    _generate_enemy_cards()
    
    # Update UI
    _update_display()

func _generate_enemy_cards() -> void:
    """Generate enemy RPS cards. Extensible for enemy-specific cards."""
    enemy_cards.clear()
    
    # EQUIPMENT HOOK: Check if enemy-specific cards are provided in context
    var provided_cards: Array = minigame_context.get("enemy_cards", [])
    if not provided_cards.is_empty():
        # Use provided cards (for future enemy-specific implementation)
        for card_data in provided_cards:
            if card_data is Dictionary:
                var card_type: String = card_data.get("rps_type", "")
                if card_type != "":
                    var card: EnemyCard = EnemyCard.new(card_type)
                    # EQUIPMENT HOOK: Load win/loss/tie effects from card_data
                    card.win_effect = card_data.get("win_effect", {})
                    card.loss_effect = card_data.get("loss_effect", {})
                    card.tie_effect = card_data.get("tie_effect", {})
                    enemy_cards.append(card)
        return
    
    # Default: Generate random cards based on card count
    var target_strategy: int = minigame_context.get("target_strategy", 1)
    if character != null:
        var effective_attrs: Attributes = character.get_effective_attributes()
        var card_count: int = max(1, target_strategy - effective_attrs.strategy)
        
        # EQUIPMENT HOOK: Card count can be modified by equipment
        
        var rps_types: Array[String] = [CARD_ROCK, CARD_PAPER, CARD_SCISSORS]
        for i in range(card_count):
            # Random RPS type
            var random_type: String = rps_types[randi() % rps_types.size()]
            var card: EnemyCard = EnemyCard.new(random_type)
            
            # EQUIPMENT HOOK: Equipment can modify win/loss/tie effects here
            # For now, effects are empty (stubbed)
            
            enemy_cards.append(card)

func _resolve_rps(move: String, enemy_card: EnemyCard) -> String:
    """Resolve RPS: returns "win", "loss", or "tie"."""
    var enemy_type: String = enemy_card.rps_type
    
    # Strike (Rock) beats Scissors, loses to Paper, ties with Rock
    if move == MOVE_STRIKE:
        if enemy_type == CARD_SCISSORS:
            return "win"
        elif enemy_type == CARD_PAPER:
            return "loss"
        else:  # CARD_ROCK
            return "tie"
    
    # Grapple (Paper) beats Rock, loses to Scissors, ties with Paper
    elif move == MOVE_GRAPPLE:
        if enemy_type == CARD_ROCK:
            return "win"
        elif enemy_type == CARD_SCISSORS:
            return "loss"
        else:  # CARD_PAPER
            return "tie"
    
    # Counter (Scissors) beats Paper, loses to Rock, ties with Scissors
    elif move == MOVE_COUNTER:
        if enemy_type == CARD_PAPER:
            return "win"
        elif enemy_type == CARD_ROCK:
            return "loss"
        else:  # CARD_SCISSORS
            return "tie"
    
    return "loss"  # Default to loss if invalid move

func _on_strike_button_pressed() -> void:
    """Handle strike button press."""
    if game_complete:
        return
    
    player_move = MOVE_STRIKE
    _update_move_buttons()
    _update_display()

func _on_grapple_button_pressed() -> void:
    """Handle grapple button press."""
    if game_complete:
        return
    
    player_move = MOVE_GRAPPLE
    _update_move_buttons()
    _update_display()

func _on_counter_button_pressed() -> void:
    """Handle counter button press."""
    if game_complete:
        return
    
    player_move = MOVE_COUNTER
    _update_move_buttons()
    _update_display()

func _on_confirm_button_pressed() -> void:
    """Handle confirm button press - enemy randomly selects card and resolves."""
    if game_complete:
        return
    
    if player_move == "":
        return  # No move selected
    
    if enemy_cards.is_empty():
        return  # No enemy cards
    
    # Enemy randomly selects a card from their hand
    var random_index: int = randi() % enemy_cards.size()
    selected_enemy_card = enemy_cards[random_index]
    
    # Resolve RPS
    outcome = _resolve_rps(player_move, selected_enemy_card)
    
    # EQUIPMENT HOOK: Apply win/loss/tie effects from enemy card
    # For now, effects are stubbed (empty dictionaries)
    
    # Complete minigame
    _complete_minigame()

func _on_redo_button_pressed() -> void:
    """Handle redo button press - allow player to change move."""
    if game_complete:
        return
    
    if redos_used >= redos_available:
        return  # No redos available
    
    # Reset player move and consume a redo
    player_move = ""
    redos_used += 1
    
    _update_display()

func _update_move_buttons() -> void:
    """Update move button states based on current selection."""
    if strike_button != null:
        strike_button.button_pressed = (player_move == MOVE_STRIKE)
    if grapple_button != null:
        grapple_button.button_pressed = (player_move == MOVE_GRAPPLE)
    if counter_button != null:
        counter_button.button_pressed = (player_move == MOVE_COUNTER)

func _update_display() -> void:
    """Update UI display with current game state."""
    if status_label == null:
        return  # UI not ready yet
    
    # Update status
    if game_complete:
        if selected_enemy_card != null and outcome != "":
            var outcome_text: String = ""
            match outcome:
                "win":
                    outcome_text = "Win! ✓"
                "loss":
                    outcome_text = "Loss ✗"
                "tie":
                    outcome_text = "Tie ="
            status_label.text = "Complete! %s" % outcome_text
        else:
            status_label.text = "Complete!"
        status_label.modulate = Color.GREEN
    else:
        status_label.text = "Select your move"
        status_label.modulate = Color.WHITE
    
    # Update enemy cards display - show all cards in enemy's hand
    if enemy_cards_label != null:
        var cards_text: String = "Enemy Hand (%d cards): " % enemy_cards.size()
        for i in range(enemy_cards.size()):
            if i > 0:
                cards_text += ", "
            var card: EnemyCard = enemy_cards[i]
            var card_display: String = card.get_display_name()
            
            # Highlight the selected card if game is complete
            if game_complete and selected_enemy_card == card:
                cards_text += "[%s]" % card_display
            else:
                cards_text += card_display
        enemy_cards_label.text = cards_text
    
    # Update current card label - show selected card if resolved
    if current_card_label != null:
        if game_complete and selected_enemy_card != null:
            current_card_label.text = "Enemy Selected: %s" % selected_enemy_card.get_display_name()
        else:
            current_card_label.text = "Enemy will randomly select a card"
    
    # Update outcome label
    if outcome_label != null:
        if game_complete and outcome != "":
            var outcome_text: String = ""
            match outcome:
                "win":
                    outcome_text = "Win! ✓"
                "loss":
                    outcome_text = "Loss ✗"
                "tie":
                    outcome_text = "Tie ="
            outcome_label.text = "Outcome: %s" % outcome_text
        elif player_move != "":
            outcome_label.text = "Enemy will randomly select a card..."
        else:
            outcome_label.text = "Select a move"
    
    # Update redo counter
    if redo_counter_label != null:
        var remaining: int = redos_available - redos_used
        redo_counter_label.text = "Redos Available: %d | Remaining: %d" % [redos_available, remaining]
    
    # Update buttons
    var can_confirm: bool = (player_move != "" and not game_complete)
    if confirm_button != null:
        confirm_button.disabled = not can_confirm
    
    var can_redo: bool = (player_move != "" and 
                         redos_used < redos_available and 
                         not game_complete)
    if redo_button != null:
        redo_button.disabled = not can_redo
    
    # Update move buttons
    var can_select_move: bool = not game_complete
    if strike_button != null:
        strike_button.disabled = not can_select_move
    if grapple_button != null:
        grapple_button.disabled = not can_select_move
    if counter_button != null:
        counter_button.disabled = not can_select_move

func _complete_minigame() -> void:
    """Complete the minigame and create result."""
    game_complete = true
    
    # Update display to show result
    _update_display()
    
    # Calculate damage
    var damage: int = _calculate_damage()
    
    # Build effects array from card outcome
    var effects: Array[Dictionary] = []
    # EQUIPMENT HOOK: Apply win/loss/tie effects from selected enemy card
    if selected_enemy_card != null:
        match outcome:
            "win":
                # Apply win effect from card
                pass  # Stubbed
            "loss":
                # Apply loss effect from card
                pass  # Stubbed
            "tie":
                # Apply tie effect from card
                pass  # Stubbed
    
    # Create result
    var result: MinigameResult = MinigameResult.new(true, _get_performance_score())
    result.damage = damage
    result.effects = effects
    result.metadata = {
        "enemy_cards": _get_enemy_cards_data(),
        "player_move": player_move,
        "selected_enemy_card": selected_enemy_card.rps_type if selected_enemy_card != null else "",
        "outcome": outcome,
        "redos_used": redos_used,
        "won": (outcome == "win"),
        "lost": (outcome == "loss"),
        "tied": (outcome == "tie")
    }
    
    # Complete minigame
    complete_minigame(result)

func _calculate_damage() -> int:
    """Calculate damage based on outcome and character's base attack."""
    if character == null:
        return 0
    
    # Get base attack damage (Power attribute)
    var effective_attrs: Attributes = character.get_effective_attributes()
    var base_damage: int = effective_attrs.power
    
    # EQUIPMENT HOOK: Equipment can modify damage calculation here
    
    # Damage based on outcome
    var damage_dealt: int = 0
    if outcome == "win":
        damage_dealt = base_damage
    elif outcome == "loss":
        # TODO: Losses deal damage to Monk (reduced by Skill attribute)
        # For now, losses deal no damage (stubbed)
        damage_dealt = 0
    elif outcome == "tie":
        # TODO: Ties may have special damage effects (stubbed)
        @warning_ignore("integer_division")
        damage_dealt = base_damage / 2  # Half damage on tie
    
    return damage_dealt

func _get_performance_score() -> float:
    """Get performance score (0.0-1.0) based on outcome."""
    if outcome == "win":
        return 1.0
    elif outcome == "tie":
        return 0.5
    else:  # loss
        return 0.0

func _get_enemy_cards_data() -> Array:
    """Get array of enemy card data for metadata."""
    var cards_data: Array = []
    for card in enemy_cards:
        cards_data.append({
            "rps_type": card.rps_type,
            "win_effect": card.win_effect,
            "loss_effect": card.loss_effect,
            "tie_effect": card.tie_effect
        })
    return cards_data

static func build_context(_character: CharacterBattleEntity, _target: BattleEntity) -> Dictionary:
    """Build context data for Monk minigame."""
    # This is handled by MonkBehavior.build_minigame_context()
    # This method exists for consistency with other minigames
    return {}

func format_result(result: MinigameResult) -> Array[String]:
    """Format Monk minigame results for logging."""
    var log_entries: Array[String] = []
    
    if result == null or result.metadata.is_empty():
        return log_entries
    
    var player_move_name: String = ""
    match result.metadata.get("player_move", ""):
        MOVE_STRIKE:
            player_move_name = "Strike"
        MOVE_GRAPPLE:
            player_move_name = "Grapple"
        MOVE_COUNTER:
            player_move_name = "Counter"
        _:
            player_move_name = "Unknown"
    
    var enemy_card_type: String = result.metadata.get("selected_enemy_card", "")
    var enemy_card_name: String = ""
    match enemy_card_type:
        CARD_ROCK:
            enemy_card_name = "Rock"
        CARD_PAPER:
            enemy_card_name = "Paper"
        CARD_SCISSORS:
            enemy_card_name = "Scissors"
        _:
            enemy_card_name = "Unknown"
    
    var result_outcome: String = result.metadata.get("outcome", "")
    var outcome_text: String = ""
    match result_outcome:
        "win":
            outcome_text = "wins"
        "loss":
            outcome_text = "loses"
        "tie":
            outcome_text = "ties"
        _:
            outcome_text = "unknown"
    
    log_entries.append("%s uses %s against enemy's %s and %s!" % 
                      [character.display_name, player_move_name, enemy_card_name, outcome_text])
    
    return log_entries

func _ready() -> void:
    # Set up UI references
    _setup_ui_references()
    
    # Wait for UI to be ready
    await get_tree().process_frame
    _setup_ui_references()
    
    # Connect button signals if they exist
    if strike_button != null:
        if not strike_button.pressed.is_connected(_on_strike_button_pressed):
            strike_button.pressed.connect(_on_strike_button_pressed)
    if grapple_button != null:
        if not grapple_button.pressed.is_connected(_on_grapple_button_pressed):
            grapple_button.pressed.connect(_on_grapple_button_pressed)
    if counter_button != null:
        if not counter_button.pressed.is_connected(_on_counter_button_pressed):
            counter_button.pressed.connect(_on_counter_button_pressed)
    if redo_button != null:
        if not redo_button.pressed.is_connected(_on_redo_button_pressed):
            redo_button.pressed.connect(_on_redo_button_pressed)
    if confirm_button != null:
        if not confirm_button.pressed.is_connected(_on_confirm_button_pressed):
            confirm_button.pressed.connect(_on_confirm_button_pressed)
    
    # Update display if game is already initialized
    if not enemy_cards.is_empty():
        _update_display()
