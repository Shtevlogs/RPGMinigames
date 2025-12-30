# Registry Pattern Improvements

**Priority**: Refactor 06 (Architecture Improvement)

## Description

Update `MinigameRegistry` to use GDScript types as dictionary keys instead of strings. This provides type safety and eliminates string-based lookups. `Character.class_type` should be changed from `String` to a GDScript reference.

**Design Philosophy**: Using types as keys provides compile-time safety and eliminates string matching. GDScript types can be used as dictionary keys, making the registry more robust and type-safe. This follows the principle of using types over strings wherever possible.

## Context from Architecture Documents

### From architecture_review_notes.md:
> "Overall a good design, my only note would be to just pass in the GDScript as that can be used as a key in these dictionaries instead of the String that's being passed around now."

> "We should avoid passing strings around where possible, it's just best practice."

### From ARCHITECTURE_PRIMER.md:
- `MinigameRegistry` uses `String` keys for class types: `class_behaviors: Dictionary = {}` (class_type -> BaseClassBehavior)
- `Character.class_type` is `String` (e.g., "Berserker", "Monk")
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

2. **Character.class_type**:
   - Type: `String`
   - Values: "Berserker", "TimeWizard", "Monk", "WildMage"
   - Used for registry lookups

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

2. **Character.class_type Updates**:
   - Change `class_type: String` to `class_type: GDScript`
   - Store class reference instead of string name
   - Update initialization to use class references

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

**Character**:
```gdscript
var class_type: GDScript  # Changed from String

func _init(p_class_type: GDScript, ...):
    class_type = p_class_type
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

### Phase 2: Create Class Type Constants (Optional)

1. **Option A: Use class_name directly**:
   - Classes with `class_name` can be used directly
   - Example: `BerserkerBehavior` (if it has class_name)
   - Or use the behavior class itself

2. **Option B: Create type constants**:
   - Define constants for each class type
   - Example: `const BERSERKER_TYPE = preload("res://scripts/class_behaviors/berserker_behavior.gd")`
   - Use constants for registration and lookups

3. **Recommended**: Use class_name types directly
   - Simplest approach
   - No constants needed
   - Direct type references

### Phase 3: Update Character.class_type

1. **Update `scripts/data/character.gd`**:
   - Change `var class_type: String` to `var class_type: GDScript`
   - Update `_init()` to accept `GDScript` instead of `String`
   - Update default value handling

2. **Update Character Creation**:
   - Pass class type reference instead of string
   - Example: `Character.new(BerserkerBehavior, ...)` instead of `Character.new("Berserker", ...)`
   - Update all character creation code

3. **Update Name Handling**:
   - May need to derive name from class type
   - Or keep separate name parameter
   - Ensure display names still work

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

1. **Update Combat System**:
   - Change `MinigameRegistry.get_behavior(character.class_type)` to use GDScript type
   - Update all registry lookups
   - Remove string-based lookups

2. **Update Behavior Classes**:
   - Ensure behavior classes have `class_name` declarations
   - Or use preload references
   - Update any string-based class type checks

3. **Update Other Systems**:
   - Search codebase for `character.class_type` usage
   - Update to use GDScript type
   - Update any string comparisons

## Related Files

### Core Files to Modify
- `scripts/managers/minigame_registry.gd` - Update to use GDScript keys
- `scripts/data/character.gd` - Change class_type to GDScript

### Files That Use Registry
- `scripts/scenes/combat.gd` - Update registry lookups
- `scripts/class_behaviors/base_class_behavior.gd` - May need updates
- Any files that create characters - Update to pass GDScript types

### Behavior Files (may need class_name)
- `scripts/class_behaviors/berserker_behavior.gd` - Ensure has class_name
- `scripts/class_behaviors/monk_behavior.gd` - Ensure has class_name
- `scripts/class_behaviors/time_wizard_behavior.gd` - Ensure has class_name
- `scripts/class_behaviors/wild_mage_behavior.gd` - Ensure has class_name

## Testing Considerations

1. **Type Safety**: Verify GDScript types work as dictionary keys
2. **Registry Lookups**: Verify all lookups work correctly
3. **Character Creation**: Verify characters are created with GDScript types
4. **Backward Compatibility**: Verify no string-based code remains
5. **Class Registration**: Verify all classes are registered correctly

## Migration Notes

### Breaking Changes
- `Character.class_type` type changes from `String` to `GDScript`
- `MinigameRegistry` method signatures change
- All character creation code must be updated

### Backward Compatibility
- Not needed - this is a refactor for type safety
- All code using `class_type` must be updated

### Character Creation Pattern

Before:
```gdscript
var character = Character.new("Berserker", attributes, "Berserker Name")
```

After:
```gdscript
var character = Character.new(BerserkerBehavior, attributes, "Berserker Name")
```

Or with constants:
```gdscript
const BERSERKER = preload("res://scripts/class_behaviors/berserker_behavior.gd")
var character = Character.new(BERSERKER, attributes, "Berserker Name")
```

## Alternative Approaches

### Option A: Use Behavior Class as Type
- Character stores behavior class reference
- Registry uses behavior class as key
- Simplest approach

### Option B: Separate Class Type Enum
- Create enum for class types
- Map enum to behavior classes
- More structured but adds indirection

### Option C: Keep Strings with Constants
- Define string constants
- Use constants instead of literals
- Less type-safe but easier migration

## Status

Pending

