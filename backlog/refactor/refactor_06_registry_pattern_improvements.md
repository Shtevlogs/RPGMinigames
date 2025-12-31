# Registry Pattern Improvements

**Priority**: Refactor 06 (Architecture Improvement)

## Description

Update `MinigameRegistry` to use GDScript types as dictionary keys instead of strings. This provides type safety and eliminates string-based lookups. `CharacterBattleEntity.class_type` should be changed from `String` to a GDScript reference.

**Design Philosophy**: Using types as keys provides compile-time safety and eliminates string matching. GDScript types can be used as dictionary keys, making the registry more robust and type-safe. This follows the principle of using types over strings wherever possible.

## Context from Architecture Documents

### From architecture_review_notes.md:
> "Overall a good design, my only note would be to just pass in the GDScript as that can be used as a key in these dictionaries instead of the String that's being passed around now."

> "We should avoid passing strings around where possible, it's just best practice."

### From ARCHITECTURE_PRIMER.md:
- `MinigameRegistry` uses `String` keys for class types: `class_behaviors: Dictionary = {}` (class_type -> BaseClassBehavior)
- `CharacterBattleEntity.class_type` is `String` (e.g., "Berserker", "Monk")
- Registry methods: `register_class(class_type: String, ...)`, `get_behavior(class_type: String)`
- Current lookup: `class_behaviors.get(class_type, null)` where class_type is a string

### From gamedoc.md:
- Character classes are well-defined types
- Class system is extensible but types are known at compile time
- Type safety is important for the class system

## Dependencies

**None** - This refactor is independent but works well with:
- refactor_01_battle_entity_base_class.md (BattleEntity could have class_type)
- refactor_08_combat_system_decomposition.md (Registry improvements help with organization)

## Current State

### Current Architecture

1. **MinigameRegistry** (`scripts/managers/minigame_registry.gd`):
   - `class_behaviors: Dictionary = {}` - Maps `String` to `BaseClassBehavior`
   - `minigame_scenes: Dictionary = {}` - Maps `String` to scene path
   - `register_class(class_type: String, behavior_class: GDScript, scene_path: String) -> void`
   - `get_behavior(class_type: String) -> BaseClassBehavior`
   - `get_minigame_scene_path(class_type: String) -> String`

2. **CharacterBattleEntity.class_type**:
   - Type: `String`
   - Values: "Berserker", "TimeWizard", "Monk", "WildMage"
   - Used for registry lookups
   - Serialized as string in save files

3. **Registry Usage**:
   - `MinigameRegistry.get_behavior(character.class_type)` - String lookup
   - `MinigameRegistry.get_minigame_scene_path(character.class_type)` - String lookup

### Problems with Current Approach

1. **String Matching**: Error-prone, no compile-time checks
2. **Type Safety**: No guarantee that class_type string matches actual class
3. **Refactoring Risk**: String changes don't cause compile errors
4. **No IDE Support**: String literals don't provide autocomplete
5. **Runtime Errors**: Typos in strings cause runtime failures

### Existing Class Types

Classes that need to be registered:
- `BerserkerBehavior` / Berserker class
- `TimeWizardBehavior` / TimeWizard class
- `MonkBehavior` / Monk class
- `WildMageBehavior` / WildMage class

## Requirements

### Core Functionality

1. **MinigameRegistry Updates**:
   - Change dictionary keys from `String` to `GDScript`
   - Update `register_class()` to accept `GDScript` instead of `String`
   - Update lookup methods to accept `GDScript` instead of `String`
   - Support GDScript types as keys

2. **CharacterBattleEntity.class_type Updates**:
   - Change `class_type: String` to `class_type: GDScript`
   - Store class reference instead of string name
   - Update initialization to use class references
   - Add serialization/deserialization helpers for string conversion (JSON compatibility)

3. **Registry Registration**:
   - Register classes using GDScript types as keys
   - Update registration calls to use class references

4. **Compatibility**:
   - Ensure all registry lookups use GDScript types
   - Update all code that accesses `character.class_type`

### Interface Requirements

**MinigameRegistry**:
```gdscript
var class_behaviors: Dictionary = {}  # GDScript -> BaseClassBehavior
var minigame_scenes: Dictionary = {}  # GDScript -> String

func register_class(class_type: GDScript, behavior_class: GDScript, scene_path: String) -> void:
    class_behaviors[class_type] = behavior_instance
    minigame_scenes[class_type] = scene_path

func get_behavior(class_type: GDScript) -> BaseClassBehavior:
    return class_behaviors.get(class_type, null)
```

**CharacterBattleEntity**:
```gdscript
var class_type: GDScript  # Changed from String

func _init(p_class_type: GDScript, ...):
    class_type = p_class_type

func serialize() -> Dictionary:
    var data = super.serialize()
    data["class_type"] = MinigameRegistry.get_class_type_string(class_type)
    return data

func deserialize(data: Dictionary) -> void:
    super.deserialize(data)
    class_type = MinigameRegistry.get_class_type_from_string(data.get("class_type", ""))
```

## Implementation Plan

### Phase 1: Update MinigameRegistry

1. **Update `scripts/managers/minigame_registry.gd`**:
   - Change `register_class(class_type: String, ...)` to `register_class(class_type: GDScript, ...)`
   - Change `get_behavior(class_type: String)` to `get_behavior(class_type: GDScript)`
   - Change `get_minigame_scene_path(class_type: String)` to `get_minigame_scene_path(class_type: GDScript)`
   - Update dictionary key types in comments

2. **Update Registration Logic**:
   - Use GDScript type as key directly
   - No string conversion needed
   - Type is the key

3. **Update Lookup Logic**:
   - Direct dictionary lookup with GDScript type
   - No string matching needed
   - Type-safe lookups

### Phase 2: Create Helper Methods for Serialization

1. **Add Helper Methods to MinigameRegistry**:
   - `get_class_type_string(class_type: GDScript) -> String`: Convert GDScript type to string identifier for serialization/display
   - `get_class_type_from_string(class_string: String) -> GDScript`: Convert string identifier back to GDScript type for deserialization
   - Maintain reverse mapping dictionary for efficient lookups
   - Used for save/load compatibility (JSON doesn't support GDScript types)

2. **Implementation Pattern**:
   ```gdscript
   var class_type_to_string: Dictionary = {}  # GDScript -> String
   var string_to_class_type: Dictionary = {}  # String -> GDScript
   
   func register_class(class_type: GDScript, behavior_class: GDScript, scene_path: String) -> void:
       # ... existing registration ...
       # Also register string mapping
       var class_string = _derive_class_string(class_type)
       class_type_to_string[class_type] = class_string
       string_to_class_type[class_string] = class_type
   ```

### Phase 2b: Type Choice Clarification

**Decision**: Use behavior class directly as the key type (e.g., `BerserkerBehavior`)
- All behavior classes already have `class_name` declarations
- Simplest approach - no constants needed
- Direct type references provide compile-time safety
- Example: `register_class(BerserkerBehavior, BerserkerBehavior, scene_path)`

### Phase 3: Update CharacterBattleEntity.class_type

1. **Update `scripts/data/character_battle_entity.gd`**:
   - Change `var class_type: String` to `var class_type: GDScript`
   - Update `_init()` to accept `GDScript` instead of `String`
   - Update default value handling (use `null` or require non-null)

2. **Update Serialization/Deserialization**:
   - **serialize()**: Convert GDScript type to string using `MinigameRegistry.get_class_type_string(class_type)`
   - **deserialize()**: Convert string back to GDScript type using `MinigameRegistry.get_class_type_from_string(class_string)`
   - Handle null/empty strings gracefully (return null or default type)

3. **Update Character Creation**:
   - Pass class type reference instead of string
   - Example: `CharacterBattleEntity.new(BerserkerBehavior, ...)` instead of `CharacterBattleEntity.new("Berserker", ...)`
   - Update all character creation code:
     - `scripts/scenes/party_selection.gd` - Update character generation
     - Any other files that create characters

4. **Display Name Handling**:
   - Keep separate `display_name` parameter (already exists)
   - For display purposes, use helper method: `MinigameRegistry.get_class_type_string(character.class_type)`
   - Display names remain separate from class type (allows custom names)

### Phase 4: Update Registry Registration

1. **Update `scripts/managers/minigame_registry.gd._register_classes()`**:
   - Change registration calls to use GDScript types:
     ```gdscript
     register_class(BerserkerBehavior, BerserkerBehavior, "res://scenes/minigames/berserker_minigame.tscn")
     ```
   - Use class references instead of strings
   - Update all class registrations

2. **Registration Pattern**:
   - Use behavior class as the key type
   - Or use a separate class type constant
   - Ensure consistency across registrations

### Phase 5: Update All Registry Usage

1. **Update Combat System** (`scripts/scenes/combat.gd`):
   - Change `MinigameRegistry.get_behavior(character.class_type)` calls to use GDScript type
   - Update all registry lookups
   - **Fix string comparison**: Change `if attacker.class_type == "Berserker"` to `if attacker.class_type == BerserkerBehavior`
   - Remove all string-based lookups and comparisons

2. **Update Behavior Classes**:
   - Verify all behavior classes have `class_name` declarations (already confirmed: all have `class_name`)
   - No changes needed - classes already properly declared

3. **Update Other Systems**:
   - **run_state.gd**: Change `character.class_type.to_lower()` to `MinigameRegistry.get_class_type_string(character.class_type).to_lower()` for land generation
   - **land_screen.gd**: Use `MinigameRegistry.get_class_type_string(character.class_type)` for display
   - **party_selection.gd**: Update character creation to use GDScript types (e.g., `BerserkerBehavior` instead of `"Berserker"`)
   - **scene_manager.gd**: Update if it uses `class_type` parameter
   - Search codebase for all `character.class_type` usage and update accordingly

## Related Files

### Core Files to Modify
- `scripts/managers/minigame_registry.gd` - Update to use GDScript keys, add helper methods for serialization
- `scripts/data/character_battle_entity.gd` - Change class_type to GDScript, update serialize/deserialize

### Files That Use Registry
- `scripts/scenes/combat.gd` - Update registry lookups, fix string comparison on line 1065
- `scripts/data/run_state.gd` - Update to use helper method for string conversion (line 26)
- `scripts/scenes/party_selection.gd` - Update character creation to use GDScript types
- `scripts/scenes/land_screen.gd` - Update display to use helper method (line 45)
- `scripts/managers/scene_manager.gd` - Update if it uses class_type parameter
- `scripts/class_behaviors/base_class_behavior.gd` - No changes needed

### Behavior Files (may need class_name)
- `scripts/class_behaviors/berserker_behavior.gd` - Ensure has class_name
- `scripts/class_behaviors/monk_behavior.gd` - Ensure has class_name
- `scripts/class_behaviors/time_wizard_behavior.gd` - Ensure has class_name
- `scripts/class_behaviors/wild_mage_behavior.gd` - Ensure has class_name

## Testing Considerations

1. **Type Safety**: Verify GDScript types work as dictionary keys
2. **Registry Lookups**: Verify all lookups work correctly with GDScript types
3. **Character Creation**: Verify characters are created with GDScript types
4. **String Comparisons**: Verify all string comparisons are replaced with GDScript type comparisons
5. **Class Registration**: Verify all classes are registered correctly
6. **Serialization**: Verify save/load works correctly (GDScript → String → GDScript conversion)
7. **Helper Methods**: Verify `get_class_type_string()` and `get_class_type_from_string()` work correctly
8. **Display**: Verify display code uses helper methods correctly
9. **Edge Cases**: Test null/empty class_type handling in deserialization

## Migration Notes

### Breaking Changes
- `CharacterBattleEntity.class_type` type changes from `String` to `GDScript`
- `MinigameRegistry` method signatures change
- All character creation code must be updated
- All string comparisons with `class_type` must be updated to use GDScript type comparisons

### Backward Compatibility

**Save File Compatibility**:
- Save files contain `class_type` as string in JSON
- Deserialization must convert string back to GDScript type using helper method
- Serialization converts GDScript type to string for JSON compatibility
- **Migration Strategy**: 
  - Option A: Support both formats during transition (check if string or GDScript)
  - Option B: Require save file migration (simpler, cleaner)
  - **Recommendation**: Option B - require migration (alpha stage, breaking changes acceptable)

**Code Compatibility**:
- All code using `class_type` must be updated
- String comparisons must be replaced with GDScript type comparisons
- Display code must use helper methods to get string identifiers

### Character Creation Pattern

Before:
```gdscript
var character = CharacterBattleEntity.new("Berserker", attributes, "character_id", "Berserker Name")
```

After:
```gdscript
var character = CharacterBattleEntity.new(BerserkerBehavior, attributes, "character_id", "Berserker Name")
```

### String Comparison Pattern

Before:
```gdscript
if attacker.class_type == "Berserker":
    # ...
```

After:
```gdscript
if attacker.class_type == BerserkerBehavior:
    # ...
```

### Display/Serialization Pattern

For display or serialization, use helper methods:
```gdscript
# Get string identifier for display
var class_string = MinigameRegistry.get_class_type_string(character.class_type)
print("%s (%s)" % [character.display_name, class_string])

# Serialization (in CharacterBattleEntity.serialize())
data["class_type"] = MinigameRegistry.get_class_type_string(class_type)

# Deserialization (in CharacterBattleEntity.deserialize())
class_type = MinigameRegistry.get_class_type_from_string(data.get("class_type", ""))
```

## Alternative Approaches

### Option A: Use Behavior Class as Type (SELECTED)
- Character stores behavior class reference
- Registry uses behavior class as key
- Simplest approach
- **This is the recommended approach for this refactor**

### Option B: Separate Class Type Enum
- Create enum for class types
- Map enum to behavior classes
- More structured but adds indirection

### Option C: Keep Strings with Constants
- Define string constants
- Use constants instead of literals
- Less type-safe but easier migration

## Implementation Details

### Helper Methods Implementation

The `MinigameRegistry` needs helper methods for serialization/display purposes:

```gdscript
# In MinigameRegistry
var class_type_to_string: Dictionary = {}  # GDScript -> String
var string_to_class_type: Dictionary = {}  # String -> GDScript

func register_class(class_type: GDScript, behavior_class: GDScript, scene_path: String) -> void:
    # ... existing registration logic ...
    # Derive string identifier from class name (remove "Behavior" suffix)
    var class_string = _derive_class_string(class_type)
    class_type_to_string[class_type] = class_string
    string_to_class_type[class_string] = class_type

func _derive_class_string(class_type: GDScript) -> String:
    """Derive string identifier from GDScript class type."""
    # Example: BerserkerBehavior -> "Berserker"
    var script_path = class_type.resource_path
    var file_name = script_path.get_file().get_basename()
    # Remove "Behavior" suffix if present
    if file_name.ends_with("_behavior"):
        return file_name.substr(0, file_name.length() - 9).capitalize()
    elif file_name.ends_with("Behavior"):
        return file_name.substr(0, file_name.length() - 8)
    return file_name.capitalize()

func get_class_type_string(class_type: GDScript) -> String:
    """Get string identifier for a GDScript class type."""
    if class_type == null:
        return ""
    return class_type_to_string.get(class_type, "")

func get_class_type_from_string(class_string: String) -> GDScript:
    """Get GDScript type from string identifier."""
    if class_string.is_empty():
        return null
    return string_to_class_type.get(class_string, null)
```

### Specific Issues Addressed

1. **Class Name Mismatch**: Updated all references from `Character` to `CharacterBattleEntity` throughout the document
2. **String Comparison**: Documented the need to fix `if attacker.class_type == "Berserker"` in `combat.gd:1065`
3. **Serialization**: Added comprehensive serialization/deserialization strategy with helper methods
4. **Type Choice**: Clarified that behavior class directly should be used as the key type
5. **Additional String Usage**: Documented `run_state.gd` and `land_screen.gd` usage that needs updating
6. **Display Names**: Clarified that display names remain separate, helper methods used for string conversion

## Status

Completed

