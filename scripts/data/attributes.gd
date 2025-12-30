class_name Attributes
extends RefCounted

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
