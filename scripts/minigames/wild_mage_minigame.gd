class_name WildMageMinigame
extends BaseMinigame

# Wild Mage minigame - Poker-like card game implementation
# Core poker mechanics with hand evaluation and discard system

# Modular scoring configuration
const HAND_MULTIPLIERS = {
    "high_card": 1.0,
    "pair": 1.5,
    "two_pair": 2.0,
    "flush": 3.0,
    "straight": 4.0,
    "straight_flush": 5.0
}

# Card representation
class Card:
    var suit: String  # "square" or "circle"
    var number: int  # 9, 8, 7, 6, 5, 4, 3, or 2
    
    func _init(p_suit: String, p_number: int):
        suit = p_suit
        number = p_number
    
    func get_display_name() -> String:
        var suit_color: String = "red" if suit == "square" else "black"
        var suit_name: String = "Square" if suit == "square" else "Circle"
        return "%d of %s (%s)" % [number, suit_name, suit_color]

# UI References (will be set in _ready)
var hand_display_label: Label = null
var hand_strength_label: Label = null
var status_label: Label = null
var discard_button: Button = null
var play_button: Button = null
var discard_counter_label: Label = null
var card_container: VBoxContainer = null
var card_buttons: Array[Button] = []

# Game state
var deck: Array[Card] = []
var hand: Array[Card] = []
var selected_cards: Array[int] = []  # Indices of selected cards
var discard_limit: int = 0  # Maximum cards that can be discarded in one action
var total_discards: int = 0  # Total discards available
var discards_used: int = 0  # Discards already used
var hand_size: int = 4
var game_complete: bool = false

# Hand evaluation result (for selected cards)
var current_hand_type: String = "high_card"
var current_multiplier: float = 1.0

func _setup_ui_references() -> void:
    if hand_display_label != null:
        return  # Already set up
    
    var vbox: VBoxContainer = get_node_or_null("VBoxContainer")
    if vbox != null:
        hand_strength_label = vbox.get_node_or_null("HandStrengthLabel") as Label
        hand_display_label = vbox.get_node_or_null("HandDisplayLabel") as Label
        status_label = vbox.get_node_or_null("StatusLabel") as Label
        discard_counter_label = vbox.get_node_or_null("DiscardCounterLabel") as Label
        card_container = vbox.get_node_or_null("CardContainer") as VBoxContainer
        
        var button_container: HBoxContainer = vbox.get_node_or_null("ButtonContainer") as HBoxContainer
        if button_container != null:
            discard_button = button_container.get_node_or_null("DiscardButton") as Button
            play_button = button_container.get_node_or_null("PlayButton") as Button
            # Fallback: if PlayButton doesn't exist, use ConfirmButton
            if play_button == null:
                play_button = button_container.get_node_or_null("ConfirmButton") as Button

func initialize_minigame() -> void:
    # Set up UI references if not already done
    _setup_ui_references()
    
    # Wait for UI to be ready if needed
    if hand_display_label == null:
        await get_tree().process_frame
        _setup_ui_references()
    
    # Cast context to WildMageMinigameContext
    var context = minigame_context as WildMageMinigameContext
    if context == null:
        push_error("Invalid context type for WildMageMinigame")
        return
    
    # Get context data from typed context
    hand_size = context.hand_size
    total_discards = context.discards_available
    discard_limit = total_discards  # For now, discard limit equals total discards
    discards_used = 0
    
    # Stub: Pre-drawn card (ignore for now)
    var _pre_drawn_card = context.pre_drawn_card
    # EQUIPMENT HOOK: Pre-drawn card should be added to hand without counting toward hand size
    
    # Initialize deck
    _create_deck()
    _shuffle_deck()
    
    # Deal initial hand
    _deal_initial_hand()
    
    # Evaluate initial selection (empty, so will show "No valid hand")
    _evaluate_selected_cards()
    
    # Update UI
    _update_display()

func _create_deck() -> void:
    deck.clear()
    var suits: Array[String] = ["square", "circle"]
    var numbers: Array[int] = [9, 8, 7, 6, 5, 4, 3, 2]
    
    for suit in suits:
        for number in numbers:
            deck.append(Card.new(suit, number))

func _shuffle_deck() -> void:
    deck.shuffle()

func _deal_initial_hand() -> void:
    hand.clear()
    selected_cards.clear()
    game_complete = false
    
    # Draw cards up to hand_size
    for i in range(hand_size):
        if deck.is_empty():
            push_warning("Deck is empty! Hand size may be smaller than requested.")
            break
        hand.append(_draw_card())

func _draw_card() -> Card:
    if deck.is_empty():
        push_error("Deck is empty!")
        return null
    
    return deck.pop_back()

func _get_selected_cards() -> Array[Card]:
    var selected: Array[Card] = []
    for index in selected_cards:
        if index >= 0 and index < hand.size():
            selected.append(hand[index])
    return selected

func _evaluate_selected_cards() -> void:
    var selected: Array[Card] = _get_selected_cards()
    
    if selected.is_empty():
        current_hand_type = "high_card"
        current_multiplier = HAND_MULTIPLIERS["high_card"]
        return
    
    # EQUIPMENT HOOK: Apply equipment effects that modify card values or suits before evaluation
    
    # Evaluate hand type (check highest to lowest)
    if _is_straight_flush(selected):
        current_hand_type = "straight_flush"
    elif _is_straight(selected):
        current_hand_type = "straight"
    elif _is_flush(selected):
        current_hand_type = "flush"
    elif _is_two_pair(selected):
        current_hand_type = "two_pair"
    elif _is_pair(selected):
        current_hand_type = "pair"
    else:
        current_hand_type = "high_card"
    
    # EQUIPMENT HOOK: Apply equipment effects that modify hand type multipliers
    
    # Get multiplier from configuration
    current_multiplier = HAND_MULTIPLIERS.get(current_hand_type, 1.0)
    
    # EQUIPMENT HOOK: Apply equipment effects that add bonus multipliers or effects

func _is_pair(cards: Array[Card]) -> bool:
    if cards.size() < 2:
        return false
    
    var number_counts: Dictionary = {}
    for card in cards:
        if not number_counts.has(card.number):
            number_counts[card.number] = 0
        number_counts[card.number] += 1
    
    var pair_count: int = 0
    for number in number_counts:
        if number_counts[number] >= 2:
            pair_count += 1
    
    return pair_count == 1

func _is_two_pair(cards: Array[Card]) -> bool:
    if cards.size() < 4:
        return false
    
    var number_counts: Dictionary = {}
    for card in cards:
        if not number_counts.has(card.number):
            number_counts[card.number] = 0
        number_counts[card.number] += 1
    
    var pair_count: int = 0
    for number in number_counts:
        if number_counts[number] >= 2:
            pair_count += 1
    
    return pair_count >= 2

func _is_flush(cards: Array[Card]) -> bool:
    if cards.size() != 5:
        return false
    
    var first_suit: String = cards[0].suit
    for card in cards:
        if card.suit != first_suit:
            return false
    
    return true

func _is_straight(cards: Array[Card]) -> bool:
    if cards.size() != 5:
        return false
    
    # Get unique numbers and sort them
    var numbers: Array[int] = []
    for card in cards:
        if not numbers.has(card.number):
            numbers.append(card.number)
    
    if numbers.size() != 5:
        return false  # Must have 5 unique numbers
    
    numbers.sort()
    
    # Check for straight (including wrap-around)
    # Possible straights: 9-8-7-6-5, 8-7-6-5-4, 7-6-5-4-3, 6-5-4-3-2, 5-4-3-2-9, 4-3-2-9-8, 3-2-9-8-7, 2-9-8-7-6
    var valid_straights: Array[Array] = [
        [9, 8, 7, 6, 5],
        [8, 7, 6, 5, 4],
        [7, 6, 5, 4, 3],
        [6, 5, 4, 3, 2],
        [5, 4, 3, 2, 9],
        [4, 3, 2, 9, 8],
        [3, 2, 9, 8, 7],
        [2, 9, 8, 7, 6]
    ]
    
    for valid_straight in valid_straights:
        var matches: bool = true
        for num in valid_straight:
            if not numbers.has(num):
                matches = false
                break
        if matches:
            return true
    
    return false

func _is_straight_flush(cards: Array[Card]) -> bool:
    if cards.size() != 5:
        return false
    
    # Must be a flush
    if not _is_flush(cards):
        return false
    
    # Must be a straight
    return _is_straight(cards)

func _update_display() -> void:
    if hand_display_label == null:
        return  # UI not ready yet
    
    # Update card buttons
    _update_card_buttons()
    
    # Update hand display (summary text)
    var hand_text: String = "Hand (%d cards): " % hand.size()
    for i in range(hand.size()):
        if i > 0:
            hand_text += ", "
        var card_name: String = hand[i].get_display_name()
        if i in selected_cards:
            hand_text += "[%s]" % card_name
        else:
            hand_text += card_name
    hand_display_label.text = hand_text
    
    # Update hand strength label (based on selected cards)
    var selected: Array[Card] = _get_selected_cards()
    if selected.is_empty():
        hand_strength_label.text = "Hand Type: No cards selected"
    else:
        var strength_text: String = "Hand Type: "
        var hand_type_display: String = ""
        match current_hand_type:
            "straight_flush":
                hand_type_display = "Straight Flush (%.1fx)" % current_multiplier
            "straight":
                hand_type_display = "Straight (%.1fx)" % current_multiplier
            "flush":
                hand_type_display = "Flush (%.1fx)" % current_multiplier
            "two_pair":
                hand_type_display = "Two Pair (%.1fx)" % current_multiplier
            "pair":
                hand_type_display = "Pair (%.1fx)" % current_multiplier
            "high_card":
                hand_type_display = "High Card (%.1fx)" % current_multiplier
        strength_text += hand_type_display
        hand_strength_label.text = strength_text
    
    # Update discard counter
    if discard_counter_label != null:
        var remaining: int = total_discards - discards_used
        discard_counter_label.text = "Discard Limit: %d | Remaining: %d" % [discard_limit, remaining]
    
    # Update status
    if status_label != null:
        if game_complete:
            status_label.text = "Complete!"
            status_label.modulate = Color.GREEN
        elif selected_cards.size() > 0:
            status_label.text = "%d card(s) selected" % selected_cards.size()
            status_label.modulate = Color.WHITE
        else:
            status_label.text = "Select cards to play or discard"
            status_label.modulate = Color.WHITE
    
    # Update buttons
    var remaining_discards: int = total_discards - discards_used
    if discard_button != null:
        # Discard button: enabled when selected cards ≤ discard limit and discards remaining
        var can_discard: bool = (selected_cards.size() > 0 and 
                                 selected_cards.size() <= discard_limit and 
                                 remaining_discards > 0 and
                                 not game_complete)
        discard_button.disabled = not can_discard
    
    if play_button != null:
        # Play button: enabled when 5 or fewer cards are selected
        var can_play: bool = (selected_cards.size() > 0 and 
                             selected_cards.size() <= 5 and 
                             not game_complete)
        play_button.disabled = not can_play
        if play_button.text != "Play":
            play_button.text = "Play"

func _update_card_buttons() -> void:
    if card_container == null:
        return
    
    # Clear existing buttons
    for button in card_buttons:
        if is_instance_valid(button):
            button.queue_free()
    card_buttons.clear()
    
    # Create buttons for each card
    for i in range(hand.size()):
        var card: Card = hand[i]
        var button: Button = Button.new()
        button.text = card.get_display_name()
        button.toggle_mode = true
        button.button_pressed = (i in selected_cards)
        
        # Style selected cards
        if i in selected_cards:
            button.modulate = Color.CYAN
        else:
            button.modulate = Color.WHITE
        
        # Connect signal
        var card_index: int = i  # Capture index in closure
        button.pressed.connect(func(): _on_card_clicked(card_index))
        
        # Disable if game complete
        if game_complete:
            button.disabled = true
        else:
            button.disabled = false
        
        card_container.add_child(button)
        card_buttons.append(button)

func _on_card_clicked(card_index: int) -> void:
    if game_complete:
        return
    
    # Toggle selection (no restrictions on number of cards)
    if card_index in selected_cards:
        selected_cards.erase(card_index)
    else:
        selected_cards.append(card_index)
    
    # Re-evaluate selected cards
    _evaluate_selected_cards()
    
    # Update display
    _update_display()

func _on_discard_button_pressed() -> void:
    """Handle discard button press."""
    var remaining_discards: int = total_discards - discards_used
    if remaining_discards <= 0 or selected_cards.is_empty() or game_complete:
        return
    
    if selected_cards.size() > discard_limit:
        push_warning("Cannot discard more than %d cards at once" % discard_limit)
        return
    
    # Remove selected cards from hand (in reverse order to maintain indices)
    var cards_to_discard: int = selected_cards.size()
    selected_cards.sort()
    selected_cards.reverse()
    
    for index in selected_cards:
        if index < hand.size():
            hand.remove_at(index)
    
    # Draw replacement cards
    for i in range(cards_to_discard):
        if not deck.is_empty():
            hand.append(_draw_card())
    
    # Update discards used
    discards_used += cards_to_discard
    selected_cards.clear()
    
    # Re-evaluate selected cards (now empty)
    _evaluate_selected_cards()
    
    # Update display
    _update_display()

func _on_play_button_pressed() -> void:
    if game_complete:
        return
    
    var selected: Array[Card] = _get_selected_cards()
    if selected.is_empty() or selected.size() > 5:
        return
    
    # Finalize and complete the minigame
    game_complete = true
    
    # EQUIPMENT HOOK: Apply equipment effects that modify damage or add status effects
    
    # Calculate damage
    var damage: int = _calculate_damage()
    
    # Create result
    var result: MinigameResult = MinigameResult.new(true, _get_performance_score())
    
    # Create action with source, target and damage
    var action = Action.new(character)
    if target != null:
        action.targets = [target]
    action.damage = damage
    
    result.actions.append(action)
    
    # Create result data
    var result_data = WildMageMinigameResultData.new()
    result_data.hand_type = current_hand_type
    result_data.hand_cards = _get_selected_cards_data()
    result_data.multiplier = current_multiplier
    result_data.cards_played = selected.size()
    result_data.equipment_modifiers = {}  # Placeholder for future equipment effects
    result.result_data = result_data
    
    # Complete minigame
    complete_minigame(result)

func _calculate_damage() -> int:
    if character == null:
        return 0
    
    # Get base attack damage (Power attribute)
    var effective_attrs: Attributes = character.get_effective_attributes()
    var base_damage: int = effective_attrs.power
    
    # EQUIPMENT HOOK: Apply equipment effects that modify damage or add status effects
    
    # Apply multiplier based on hand strength
    return int(base_damage * current_multiplier)

func _get_performance_score() -> float:
    # Map multiplier to performance score (1.0x = 0.0, 5.0x = 1.0)
    return clamp((current_multiplier - 1.0) / 4.0, 0.0, 1.0)

func _get_selected_cards_data() -> Array:
    var cards_data: Array = []
    var selected: Array[Card] = _get_selected_cards()
    for card in selected:
        cards_data.append({
            "suit": card.suit,
            "number": card.number
        })
    return cards_data

static func build_context(_character: CharacterBattleEntity, _target: BattleEntity) -> Dictionary:
    # This is handled by WildMageBehavior.build_minigame_context()
    # This method exists for consistency with other minigames
    return {}

func _ready() -> void:
    # Set up UI references
    _setup_ui_references()
    
    # Wait for UI to be ready
    await get_tree().process_frame
    _setup_ui_references()
    
    # Connect button signals if they exist
    if discard_button != null:
        if not discard_button.pressed.is_connected(_on_discard_button_pressed):
            discard_button.pressed.connect(_on_discard_button_pressed)
    if play_button != null:
        if not play_button.pressed.is_connected(_on_play_button_pressed):
            play_button.pressed.connect(_on_play_button_pressed)
    
    # Update display if game is already initialized
    if not hand.is_empty():
        _update_display()
