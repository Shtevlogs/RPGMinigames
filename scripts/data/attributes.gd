class_name Attributes
extends GameStateSerializable

var power: int = 1  # 0-10
var skill: int = 1  # 0-10
var strategy: int = 1  # 0-10
var speed: int = 1  # 0-10
var luck: int = 1  # 0-10

func _init(p_power: int = 1, p_skill: int = 1, p_strategy: int = 1, p_speed: int = 1, p_luck: int = 1):
    power = clamp(p_power, 0, 10)
    skill = clamp(p_skill, 0, 10)
    strategy = clamp(p_strategy, 0, 10)
    speed = clamp(p_speed, 0, 10)
    luck = clamp(p_luck, 0, 10)

func duplicate() -> Attributes:
    return Attributes.new(power, skill, strategy, speed, luck)

func serialize() -> Dictionary:
    """Serialize attributes to dictionary."""
    return {
        "power": power,
        "skill": skill,
        "strategy": strategy,
        "speed": speed,
        "luck": luck
    }

func deserialize(data: Dictionary) -> void:
    """Deserialize attributes from dictionary."""
    power = clamp(data.get("power", 1), 0, 10)
    skill = clamp(data.get("skill", 1), 0, 10)
    strategy = clamp(data.get("strategy", 1), 0, 10)
    speed = clamp(data.get("speed", 1), 0, 10)
    luck = clamp(data.get("luck", 1), 0, 10)
