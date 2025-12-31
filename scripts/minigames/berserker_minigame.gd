class_name BerserkerMinigame
extends BaseMinigame

const BERSERKER_MINIGAME_CONTEXT = preload("res://scripts/data/berserker_minigame_context.gd")
const BERSERK_EFFECT = preload("res://scripts/data/status_effects/berserk_effect.gd")
const BERSERKER_MINIGAME_RESULT_DATA = preload("res://scripts/data/berserker_minigame_result_data.gd")

# Berserker minigame - Blackjack implementation
# First pass: Core blackjack mechanics with stubbed advanced features

# Card representation
class Card:
    var suit: String  # "hearts", "diamonds", "clubs", "spades"
    var rank: int  # 1-13 (1=Ace, 11=Jack, 12=Queen, 13=King)
    
    func _init(p_suit: String, p_rank: int):
        suit = p_suit
        rank = p_rank
    
    func get_base_value() -> int:
        # Returns base value without ace handling
        if rank == 1:
            return 11  # Ace default
        elif rank >= 11:
            return 10  # Face cards
        else:
            return rank
    
    func get_display_name() -> String:
        var rank_name: String
        match rank:
            1: rank_name = "Ace"
            11: rank_name = "Jack"
            12: rank_name = "Queen"
            13: rank_name = "King"
            _: rank_name = str(rank)
        return "%s of %s" % [rank_name, suit.capitalize()]

# UI References (will be set in _ready)
var hand_value_label: Label = null
var cards_label: Label = null
var status_label: Label = null
var hit_button: Button = null
var stand_button: Button = null

# Game state
var deck: Array[Card] = []
var hand: Array[Card] = []
var hand_value: int = 0
var is_busted: bool = false
var is_blackjack: bool = false
var game_complete: bool = false

# Stubbed advanced features (from minigame_context)
var effect_ranges: Array = []  # Will be populated from context if available
var is_berserking: bool = false  # Stub: track berserk state
var berserk_stacks: int = 0  # Stub: track berserk stacks

func _setup_ui_references() -> void:
    """Set up UI node references. Can be called multiple times safely."""
    if hand_value_label != null:
        return  # Already set up
    
    var vbox: VBoxContainer = get_node_or_null("VBoxContainer")
    if vbox != null:
        hand_value_label = vbox.get_node_or_null("HandValueLabel") as Label
        cards_label = vbox.get_node_or_null("CardsLabel") as Label
        status_label = vbox.get_node_or_null("StatusLabel") as Label
        var button_container: HBoxContainer = vbox.get_node_or_null("ButtonContainer") as HBoxContainer
        if button_container != null:
            hit_button = button_container.get_node_or_null("HitButton") as Button
            stand_button = button_container.get_node_or_null("StandButton") as Button

func initialize_minigame() -> void:
    # Set up UI references if not already done
    _setup_ui_references()
    
    # Wait for UI to be ready if needed
    if hand_value_label == null:
        await get_tree().process_frame
        _setup_ui_references()
    
    # Cast context to BerserkerMinigameContext
    var context = minigame_context as BerserkerMinigameContext
    if context == null:
        push_error("Invalid context type for BerserkerMinigame")
        return
    
    # Get data from typed context
    effect_ranges = context.effect_ranges
    is_berserking = context.is_berserking
    berserk_stacks = context.berserk_stacks
    
    # Initialize deck
    _create_deck()
    _shuffle_deck()
    
    # Deal initial two cards
    _deal_initial_cards()
    
    # Update UI
    _update_display()
    
    # Auto-complete on natural blackjack (21 with 2 cards)
    if is_blackjack:
        await get_tree().process_frame  # Brief delay to show the blackjack
        _on_stand_button_pressed()

func _create_deck() -> void:
    """Create a standard 52-card deck."""
    deck.clear()
    var suits: Array[String] = ["hearts", "diamonds", "clubs", "spades"]
    
    for suit in suits:
        for rank in range(1, 14):  # 1-13 (Ace through King)
            deck.append(Card.new(suit, rank))

func _shuffle_deck() -> void:
    """Shuffle the deck."""
    deck.shuffle()

func _deal_initial_cards() -> void:
    """Deal two initial cards to the player."""
    hand.clear()
    is_busted = false
    is_blackjack = false
    game_complete = false
    
    if deck.size() < 2:
        push_error("Not enough cards in deck!")
        return
    
    # Deal two cards
    hand.append(_draw_card())
    hand.append(_draw_card())
    
    # Calculate initial hand value
    _calculate_hand_value()
    
    # Check for natural blackjack (21 with 2 cards)
    if hand_value == 21 and hand.size() == 2:
        is_blackjack = true
        # Trigger berserk state on blackjack
        _trigger_berserk_state()

func _draw_card() -> Card:
    """Draw a card from the deck."""
    if deck.is_empty():
        push_error("Deck is empty!")
        return null
    
    return deck.pop_back()

func _calculate_hand_value() -> int:
    """Calculate hand value with proper ace handling."""
    var total: int = 0
    var ace_count: int = 0
    
    # First pass: count non-aces
    for card in hand:
        if card.rank == 1:  # Ace
            ace_count += 1
        else:
            total += card.get_base_value()
    
    # Second pass: add aces optimally
    # Each ace can be 11 or 1, choose to maximize value without busting
    for i in range(ace_count):
        if total + 11 <= 21:
            total += 11
        else:
            total += 1
    
    hand_value = total
    
    # Check for bust
    if hand_value > 21:
        is_busted = true
        # Trigger berserk state on bust
        _trigger_berserk_state()
    
    return hand_value

func _update_display() -> void:
    """Update UI display with current game state."""
    if hand_value_label == null:
        return  # UI not ready yet
    
    # Update hand value
    hand_value_label.text = "Hand Value: %d" % hand_value
    
    # Update cards display
    var cards_text: String = "Cards: "
    for i in range(hand.size()):
        if i > 0:
            cards_text += ", "
        cards_text += hand[i].get_display_name()
    cards_label.text = cards_text
    
    # Update status
    if is_blackjack:
        status_label.text = "BLACKJACK!"
        status_label.modulate = Color.GREEN
    elif is_busted:
        status_label.text = "BUST!"
        status_label.modulate = Color.RED
    else:
        status_label.text = ""
        status_label.modulate = Color.WHITE
    
    # Update buttons
    if hit_button != null:
        hit_button.disabled = is_busted or game_complete or is_blackjack
    if stand_button != null:
        stand_button.disabled = is_busted or game_complete or is_blackjack

func _on_hit_button_pressed() -> void:
    """Handle hit button press."""
    if is_busted or game_complete or is_blackjack:
        return
    
    # Draw a card
    var new_card: Card = _draw_card()
    if new_card == null:
        return
    
    hand.append(new_card)
    
    # Recalculate hand value
    _calculate_hand_value()
    
    # Stub: Hit damage - would deal damage to Berserker here
    # TODO: Deal damage to character based on enemy attack
    # TODO: Apply Luck-based damage reduction
    
    # Update display
    _update_display()
    
    # If busted or reached 21, auto-complete
    if is_busted or hand_value == 21:
        _on_stand_button_pressed()

func _on_stand_button_pressed() -> void:
    """Handle stand button press."""
    if game_complete:
        return
    
    game_complete = true
    
    # Stub: Check effect ranges
    # TODO: If hand_value matches any effect range, trigger target selection
    # For now, use existing target from context
    
    # Calculate damage
    var damage: int = _calculate_damage()
    
    # Create result
    var result: MinigameResult = MinigameResult.new(not is_busted, _get_performance_score())
    result.damage = damage
    
    # Add berserk effect if berserking
    if is_berserking and berserk_stacks > 0:
        var effect = BERSERK_EFFECT.new(berserk_stacks)
        effect.target = character  # Self-target
        result.add_status_effect(effect)
    
    # Create result data
    var result_data = BERSERKER_MINIGAME_RESULT_DATA.new()
    result_data.hand_value = hand_value
    result_data.cards_drawn = hand.size()
    result_data.busted = is_busted
    result_data.blackjack = is_blackjack
    result_data.is_berserking = is_berserking
    result_data.berserk_stacks = berserk_stacks
    result_data.effect_ranges = effect_ranges
    result.result_data = result_data
    
    # Complete minigame
    complete_minigame(result)

func _calculate_damage() -> int:
    """Calculate damage based on hand value and character's base attack."""
    if character == null:
        return 0
    
    # Get base attack damage (Power attribute)
    var effective_attrs: Attributes = character.get_effective_attributes()
    var base_damage: int = effective_attrs.power
    
    # Apply multiplier based on hand value
    var multiplier: float = 1.0
    if is_busted:
        multiplier = 0.5
    elif hand_value == 21:
        multiplier = 2.0
    elif hand_value >= 16:
        multiplier = 1.5
    elif hand_value >= 11:
        multiplier = 1.0
    else:
        multiplier = 0.5
    
    return int(base_damage * multiplier)

func _get_performance_score() -> float:
    """Get performance score (0.0-1.0) based on hand value."""
    if is_busted:
        return 0.0
    return clamp(float(hand_value) / 21.0, 0.0, 1.0)

func _trigger_berserk_state() -> void:
    """Trigger berserk state: set is_berserking and increment stacks (max 10)."""
    is_berserking = true
    # Increment stacks, capping at 10
    berserk_stacks = min(berserk_stacks + 1, 10)

static func build_context(_character: CharacterBattleEntity, _target: BattleEntity) -> Dictionary:
    """Build context data for Berserker minigame."""
    var class_state = _character.class_state
    
    return {
        "effect_ranges": class_state.get("effect_ranges", []),
        "berserk_stacks": class_state.get("berserk_stacks", 0),
        "is_berserking": class_state.get("is_berserking", false)
    }

func _ready() -> void:
    # Set up UI references
    _setup_ui_references()
    
    # Wait for UI to be ready
    await get_tree().process_frame
    _setup_ui_references()
    
    # Connect button signals if they exist
    if hit_button != null:
        if not hit_button.pressed.is_connected(_on_hit_button_pressed):
            hit_button.pressed.connect(_on_hit_button_pressed)
    if stand_button != null:
        if not stand_button.pressed.is_connected(_on_stand_button_pressed):
            stand_button.pressed.connect(_on_stand_button_pressed)
    
    # Update display if game is already initialized
    if not hand.is_empty():
        _update_display()
