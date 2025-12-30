# Effect Application Registry Pattern

**Priority**: Refactor 05 (Architecture Improvement - Depends on refactor_04)

## Description

Create an `EffectRegistry` or factory pattern to replace the match statement in effect application. This follows the Open/Closed Principle - new effects can be added by registering them without modifying existing code. This refactor eliminates the last match statement in effect application (if items/equipment still use dictionaries).

**Design Philosophy**: Match statements indicate missing opportunities for polymorphism and extensibility. A registry pattern allows effects to be registered and instantiated dynamically without hardcoding type names. This makes the system more maintainable and easier to extend.

## Context from Architecture Documents

### From architecture_review_notes.md:
> "Match statements are a good sign that we're missing an opportunity to leverage classes and inheritance."

### From ARCHITECTURE_PRIMER.md:
- Effect application uses match statement in `combat.gd._apply_effect()`
- Match statement maps string types to effect classes
- Current implementation:
  ```gdscript
  match effect_identifier.to_lower():
      "burneffect", "burn":
          effect = BURN_EFFECT.new(...)
      "silenceeffect", "silence":
          effect = SILENCE_EFFECT.new(...)
  ```

### From gamedoc.md:
- Status effects are extensible - new effects can be added
- Effect system should support easy addition of new effects
- No modifications to existing code should be needed for new effects

## Dependencies

**Critical Dependencies**:
- **refactor_04_minigame_result_type_safety.md** - Effects should be StatusEffect instances (but registry can work with dictionaries too)

**Recommended Dependencies**:
- Effect system should be stable before this refactor

## Current State

### Current Architecture

1. **Effect Application** (`scripts/scenes/combat.gd._apply_effect()`):
   - Receives effect dictionary with `type` or `class` string
   - Uses match statement to map string to effect class
   - Creates effect instance with parameters
   - Applies effect to target

2. **Match Statement**:
   - Hardcoded string matching
   - Must be updated for each new effect type
   - Case-insensitive matching (`to_lower()`)
   - Multiple string aliases supported (e.g., "burn" and "burneffect")

### Problems with Current Approach

1. **Not Extensible**: New effects require modifying match statement
2. **String Matching**: Error-prone, no compile-time checks
3. **Maintenance Burden**: Match statement grows with each effect
4. **Violates Open/Closed**: System is not closed for modification

### Existing Effect Types

Effects currently in match statement:
- `BurnEffect` - "burneffect", "burn"
- `SilenceEffect` - "silenceeffect", "silence"
- `TauntEffect` - "taunteffect", "taunt"
- `AlterAttributeEffect` - "alterattributeeffect", "alterattribute", "alter_attribute"
- `BerserkEffect` - "berserkeffect", "berserk"

## Requirements

### Core Functionality

1. **EffectRegistry Class**:
   - Registry pattern for effect type registration
   - Maps string identifiers to effect classes
   - Supports multiple aliases per effect type
   - Provides factory method to create effect instances

2. **Effect Registration**:
   - Effects registered at initialization (autoload or _ready)
   - Registration includes class reference and aliases
   - Supports both string-based and class-based registration

3. **Effect Creation**:
   - Factory method creates effect instances from registry
   - Handles parameter passing to constructors
   - Returns null for unknown effect types

4. **Combat System Updates**:
   - Replace match statement with registry call
   - Use registry to create effect instances
   - Handle unknown effect types gracefully

### Interface Requirements

**EffectRegistry**:
```gdscript
class_name EffectRegistry
extends RefCounted

static var effect_types: Dictionary = {}  # String -> GDScript

static func register_effect(type_name: String, effect_class: GDScript, aliases: Array[String] = []) -> void:
    effect_types[type_name.to_lower()] = effect_class
    for alias in aliases:
        effect_types[alias.to_lower()] = effect_class

static func create_effect(type_name: String, params: Dictionary) -> StatusEffect:
    var effect_class = effect_types.get(type_name.to_lower())
    if effect_class == null:
        return null
    return effect_class.new(params)
```

**Registration** (in autoload or initialization):
```gdscript
EffectRegistry.register_effect("burn", BurnEffect, ["burneffect"])
EffectRegistry.register_effect("silence", SilenceEffect, ["silenceeffect"])
```

## Implementation Plan

### Phase 1: Create EffectRegistry

1. **Create `scripts/managers/effect_registry.gd`**:
   - Static registry dictionary
   - `register_effect()` method for registration
   - `create_effect()` factory method
   - Support for aliases
   - Error handling for unknown types

2. **Design Considerations**:
   - Static vs instance (static preferred for global access)
   - Parameter passing (Dictionary vs individual params)
   - Alias support (multiple strings map to same class)

### Phase 2: Register Effect Types

1. **Registration Location**:
   - Option A: Autoload singleton (like MinigameRegistry)
   - Option B: Initialize in GameManager or combat system
   - Option C: Auto-register via class_name (more complex)

2. **Register All Effects**:
   - Register `BurnEffect` with aliases
   - Register `SilenceEffect` with aliases
   - Register `TauntEffect` with aliases
   - Register `AlterAttributeEffect` with aliases
   - Register `BerserkEffect` with aliases

3. **Registration Code**:
   ```gdscript
   func _ready() -> void:
       EffectRegistry.register_effect("burn", BurnEffect, ["burneffect"])
       EffectRegistry.register_effect("silence", SilenceEffect, ["silenceeffect"])
       # ... etc
   ```

### Phase 3: Update Combat System

1. **Update `scripts/scenes/combat.gd._apply_effect()`**:
   - Remove match statement
   - Use `EffectRegistry.create_effect()` instead
   - Handle null return (unknown effect type)
   - Pass parameters correctly

2. **Parameter Handling**:
   - Extract parameters from dictionary
   - Pass to registry factory method
   - Ensure all effect constructors are compatible

3. **Error Handling**:
   - Log warning for unknown effect types
   - Return early if effect creation fails
   - Maintain existing error handling patterns

### Phase 4: Update Effect Constructors (if needed)

1. **Standardize Constructors**:
   - Ensure all effects can be created from parameter dictionary
   - Or use consistent constructor signatures
   - Document parameter requirements

2. **Parameter Dictionary Format**:
   - Define standard parameter keys
   - Document required vs optional parameters
   - Handle effect-specific parameters

### Phase 5: Update Item/Equipment Effects (if applicable)

1. **Item Effects**:
   - If items use `_apply_effect()`, they benefit from registry
   - No changes needed if items already use registry

2. **Equipment Effects**:
   - If equipment applies effects, update to use registry
   - Or keep separate system if needed

## Related Files

### Core Files to Create
- `scripts/managers/effect_registry.gd` - **NEW FILE** - Registry implementation

### Core Files to Modify
- `scripts/scenes/combat.gd` - Replace match statement with registry call

### Registration Files (choose one)
- `scripts/managers/game_manager.gd` - If registering in GameManager
- `scripts/scenes/combat.gd` - If registering in combat system
- Autoload singleton - If creating new autoload

### Status Effect Files (no changes needed)
- `scripts/data/status_effects/burn_effect.gd` - Already exists
- `scripts/data/status_effects/silence_effect.gd` - Already exists
- `scripts/data/status_effects/taunt_effect.gd` - Already exists
- `scripts/data/status_effects/alter_attribute_effect.gd` - Already exists
- `scripts/data/status_effects/berserk_effect.gd` - Already exists

## Testing Considerations

1. **Registration**: Verify all effects are registered correctly
2. **Effect Creation**: Verify effects are created correctly from registry
3. **Aliases**: Verify aliases work correctly
4. **Unknown Types**: Verify graceful handling of unknown effect types
5. **Parameters**: Verify parameters are passed correctly to constructors
6. **Backward Compatibility**: Verify existing effect application still works

## Migration Notes

### Breaking Changes
- `_apply_effect()` implementation changes (but interface may stay same)
- Effect creation now goes through registry

### Backward Compatibility
- Registry can support existing string identifiers
- Aliases maintain backward compatibility
- No changes needed to effect dictionaries (if still used)

### Adding New Effects

After this refactor, adding new effects is simple:
1. Create effect class extending `StatusEffect`
2. Register in EffectRegistry: `EffectRegistry.register_effect("neweffect", NewEffect)`
3. No changes to combat system needed

## Alternative Approaches

### Option A: Factory Pattern
- Create `EffectFactory` class instead of registry
- Factory methods for each effect type
- Still requires updates for new effects

### Option B: Class-Based Registration
- Use `class_name` for auto-registration
- More complex but automatic
- Requires reflection or metadata system

### Option C: Keep Match Statement
- Simplest but not extensible
- Violates Open/Closed Principle
- Not recommended

## Status

Pending (Depends on refactor_04)

