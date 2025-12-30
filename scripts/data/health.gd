class_name Health
extends RefCounted

var current: int
var max_hp: int  # Calculated from Power

func _init(p_max: int = 10, p_current: int = -1):
    max_hp = p_max
    current = p_current if p_current >= 0 else max_hp

func take_damage(amount: int) -> int:
    var actual_damage = min(amount, current)
    current = max(0, current - amount)
    return actual_damage

func heal(amount: int) -> int:
    var actual_healing = min(amount, max_hp - current)
    current = min(max_hp, current + amount)
    return actual_healing

func is_alive() -> bool:
    return current > 0

func get_percentage() -> float:
    if max_hp == 0:
        return 0.0
    return float(current) / float(max_hp)

func duplicate() -> Health:
    return Health.new(max_hp, current)
