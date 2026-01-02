class_name GameStateSerializable
extends RefCounted

## Base class for all game state objects that need to be serialized.
## Provides a common interface for serialization/deserialization.
## All game state objects (BattleEntity, StatusEffect, Equipment, etc.) should extend this.

func serialize() -> Dictionary:
    push_error("serialize() must be implemented in subclass")
    return {}

func deserialize(_data: Dictionary) -> void:
    push_error("deserialize() must be implemented in subclass")
