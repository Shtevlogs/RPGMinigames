class_name GameStateSerializable
extends RefCounted

## Base class for all game state objects that need to be serialized.
## Provides a common interface for serialization/deserialization.
## All game state objects (BattleEntity, StatusEffect, Equipment, etc.) should extend this.

func serialize() -> Dictionary:
    """Serialize this object to a dictionary.
    Must be overridden in subclasses."""
    push_error("serialize() must be implemented in subclass")
    return {}

func deserialize(_data: Dictionary) -> void:
    """Deserialize this object from a dictionary.
    Must be overridden in subclasses."""
    push_error("deserialize() must be implemented in subclass")
