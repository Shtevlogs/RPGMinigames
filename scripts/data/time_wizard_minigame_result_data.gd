class_name TimeWizardMinigameResultData
extends MinigameResultData

var completion_percentage: float = 0.0
var event_activated: bool = false
var mega_time_burst: bool = false
var time_expired: bool = false
var revealed_count: int = 0
var total_squares: int = 0
var event_symbol: String = ""  # Optional, if event_activated
var event_symbol_text: String = ""  # Optional, if event_activated
var event_position: Dictionary = {}  # Optional, if event_activated (contains x, y)

