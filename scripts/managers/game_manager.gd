extends Node

# GameManager - Central game state management
# Handles run state, party state, and overall game flow

var current_run: RunState = null
var persistent_currency: int = 0  # Currency that persists between runs

signal run_started(run_state: RunState)
signal run_ended(run_state: RunState, success: bool)
signal currency_changed(new_amount: int)

func _ready() -> void:
    load_persistent_data()

func start_new_run(party: Array[CharacterBattleEntity]) -> void:
    current_run = RunState.new()
    current_run.party = party
    current_run.run_start_time = Time.get_ticks_msec() / 1000.0
    current_run.generate_land_sequence()
    run_started.emit(current_run)

func end_run(success: bool) -> void:
    if current_run == null:
        return
    
    if success:
        # Award currency on success (placeholder)
        add_currency(100)
    else:
        # Award currency on failure (less, but still something)
        add_currency(50)
    
    run_ended.emit(current_run, success)
    current_run = null

func add_currency(amount: int) -> void:
    persistent_currency += amount
    currency_changed.emit(persistent_currency)
    save_persistent_data()

func spend_currency(amount: int) -> bool:
    if persistent_currency >= amount:
        persistent_currency -= amount
        currency_changed.emit(persistent_currency)
        save_persistent_data()
        return true
    return false

func save_persistent_data() -> void:
    var save_data: Dictionary = {
        "currency": persistent_currency
    }
    var file: FileAccess = FileAccess.open("user://persistent_data.save", FileAccess.WRITE)
    if file:
        file.store_string(JSON.stringify(save_data))
        file.close()

func load_persistent_data() -> void:
    var file: FileAccess = FileAccess.open("user://persistent_data.save", FileAccess.READ)
    if file:
        var json_string: String = file.get_as_text()
        file.close()
        var json: JSON = JSON.new()
        var error: Error = json.parse(json_string)
        if error == OK:
            var save_data: Dictionary = json.data
            persistent_currency = save_data.get("currency", 0)
            currency_changed.emit(persistent_currency)
