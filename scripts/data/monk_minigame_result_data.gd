class_name MonkMinigameResultData
extends MinigameResultData

var enemy_cards: Array = []  # From _get_enemy_cards_data()
var player_move: String = ""
var selected_enemy_card: String = ""
var outcome: String = ""  # "win", "loss", "tie"
var redos_used: int = 0
var won: bool = false
var lost: bool = false
var tied: bool = false

