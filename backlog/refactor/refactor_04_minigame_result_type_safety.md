# MinigameResult Type Safety

**Priority**: Refactor 04 (Foundation - Depends on refactor_02)

## Description

Change `MinigameResult.effects` from `Array[Dictionary]` to `Array[StatusEffect]`. This eliminates the need for match statements in effect application and allows direct status effect application. Effects are created in minigame subclasses and added directly to the result.

**Design Philosophy**: Status effects should be first-class objects, not dictionary data. This provides type safety, eliminates match statements, and makes the effect system more extensible. Minigames create effect instances directly, and the combat system applies them without type checking.

## Context from Architecture Documents

### From architecture_review_notes.md:
> "In _apply_minigame_result, that MinigameResult object should have an array of StatusEffect. That would be better than the array of dictionaries it currently has. Those status effects can be added directly to BattleEntities (or as it is now, Character and EnemyData) with the add_status_effect function."

> "In the subclasses will be where initializing effects will take place for my note above (line 40)." (referring to effect creation in minigame subclasses)

### From ARCHITECTURE_PRIMER.md:
- `MinigameResult.effects` is currently `Array[Dictionary]`
- Combat system uses match statement in `_apply_effect()` to create effect instances
- Effect dictionaries contain: `type`, `class`, `target`, `magnitude`, `duration`, `stacks`
- Current flow: Minigame creates dictionary → Combat system matches type → Creates effect instance

### From gamedoc.md:
- Minigame results contain damage and effects
- Effects are applied to targets after minigame completion
- Effects can target party members or enemies
- Effect application should be straightforward and type-safe

## Dependencies

**Critical Dependencies**:
- **refactor_02_status_effect_system_refactor.md** - Status effects must be stable before this refactor

**Recommended Dependencies**:
- **refactor_01_battle_entity_base_class.md** - Effects should target BattleEntity (but can work with current system)

## Current State

### Current Architecture

1. **MinigameResult** (`scripts/data/minigame_result.gd`):
   - `effects: Array[Dictionary]` - Contains effect dictionaries
   - `add_effect(effect_type: String, target: Variant, magnitude: float, duration: int) -> void` - Adds dictionary

2. **Minigame Subclasses**:
   - Create effect dictionaries with type strings
   - Add dictionaries to result via `result.add_effect()`
   - Example: `result.add_effect("burn", target, 2.0, 3)`

3. **Combat System** (`scripts/scenes/combat.gd._apply_effect()`):
   - Receives effect dictionary
   - Uses match statement to create effect instance:
     ```gdscript
     match effect_identifier.to_lower():
         "burneffect", "burn":
             effect = BURN_EFFECT.new(duration, stacks, magnitude)
         "silenceeffect", "silence":
             effect = SILENCE_EFFECT.new(duration)
         # ... etc
     ```
   - Applies effect to target

### Problems with Current Approach

1. **Type Safety**: Dictionaries lack type safety and IDE support
2. **Match Statements**: Match statement must be updated for each new effect type
3. **String Matching**: Effect types identified by strings (error-prone)
4. **Indirect Creation**: Effects created in combat system, not where they're needed
5. **No Compile-Time Checks**: Missing dictionary keys cause runtime errors

### Existing Effect Types

Effects that need to be created in minigames:
- `BurnEffect` - Applied by Wild Mage's Flame Sword
- `SilenceEffect` - Applied by Monk's minigame
- `TauntEffect` - Applied by Berserker and Monk
- `AlterAttributeEffect` - Applied by Monk's basic attacks
- `BerserkEffect` - Applied by Berserker's minigame

## Requirements

### Core Functionality

1. **MinigameResult Updates**:
   - Change `effects: Array[Dictionary]` to `effects: Array[StatusEffect]`
   - Remove `add_effect()` method (or update to accept StatusEffect)
   - Add `add_status_effect(effect: StatusEffect) -> void` method

2. **Minigame Subclass Updates**:
   - Create StatusEffect instances directly
   - Add effect instances to result
   - Set effect target, duration, stacks, magnitude on instances

3. **Combat System Updates**:
   - Remove match statement from `_apply_effect()`
   - Apply effects directly: `target.add_status_effect(effect)`
   - Remove dictionary processing

### Interface Requirements

**MinigameResult**:
```gdscript
class_name MinigameResult
extends RefCounted

var success: bool
var performance_score: float
var damage: int
var effects: Array[StatusEffect] = []  # Changed from Array[Dictionary]
var metadata: Dictionary = {}

func add_status_effect(effect: StatusEffect) -> void:
    effects.append(effect)
```

**Minigame Subclasses**:
```gdscript
# Create effect instance
var burn_effect = BurnEffect.new(3, 1, 2.0)
burn_effect.target = target_entity
result.add_status_effect(burn_effect)
```

**Combat System**:
```gdscript
# Apply effects directly
for effect in result.effects:
    if effect.target != null:
        effect.target.add_status_effect(effect)
```

## Implementation Plan

### Phase 1: Update MinigameResult

1. **Update `scripts/data/minigame_result.gd`**:
   - Change `effects: Array[Dictionary]` to `effects: Array[StatusEffect]`
   - Remove `add_effect(effect_type: String, ...)` method
   - Add `add_status_effect(effect: StatusEffect) -> void` method
   - Update `duplicate()` to duplicate StatusEffect array correctly

2. **Update initialization**:
   - Initialize `effects` as empty array
   - Remove dictionary-related code

### Phase 2: Update Minigame Subclasses

1. **Update `scripts/minigames/berserker_minigame.gd`**:
   - Import status effect classes
   - Create effect instances directly (e.g., `BerserkEffect.new(stacks)`)
   - Set effect properties (target, duration, etc.)
   - Add to result via `result.add_status_effect(effect)`
   - Remove dictionary creation

2. **Update `scripts/minigames/monk_minigame.gd`**:
   - Create `SilenceEffect`, `TauntEffect`, `AlterAttributeEffect` instances
   - Set targets and properties
   - Add to result
   - Remove dictionary creation

3. **Update `scripts/minigames/time_wizard_minigame.gd`**:
   - Create any effect instances needed
   - Add to result
   - Remove dictionary creation

4. **Update `scripts/minigames/wild_mage_minigame.gd`**:
   - Create `BurnEffect` instances for Flame Sword
   - Set targets and properties
   - Add to result
   - Remove dictionary creation

### Phase 3: Update Combat System

1. **Update `scripts/scenes/combat.gd._apply_minigame_result()`**:
   - Remove dictionary iteration
   - Iterate over `result.effects: Array[StatusEffect]`
   - Apply effects directly: `effect.target.add_status_effect(effect)`
   - Remove call to `_apply_effect()` for minigame results

2. **Update or Remove `_apply_effect()`**:
   - Option A: Remove entirely if only used for minigame results
   - Option B: Keep for item/equipment effects (update separately)
   - If keeping, update to accept `StatusEffect` instead of `Dictionary`

3. **Update effect application**:
   - Effects already have target set (from minigame)
   - Simply call `add_status_effect()` on target
   - Log effect application
   - Update UI displays

### Phase 4: Update Effect Target Setting

1. **Ensure targets are set**:
   - Minigames should set `effect.target` before adding to result
   - Targets should be `BattleEntity` (after refactor_01) or `Character`/`EnemyData` (current)

2. **Handle null targets**:
   - If target not set, determine from context (character, result, etc.)
   - Set target before applying effect

3. **Update behavior classes**:
   - Behavior classes may need to provide target information
   - Or minigames determine target from context

### Phase 5: Update Item/Equipment Effects (if applicable)

1. **Item effects**:
   - If items also use `_apply_effect()`, update separately
   - Or create effect instances in item usage code

2. **Equipment effects**:
   - If equipment applies effects, update to create instances
   - Or keep dictionary system for equipment (separate concern)

## Related Files

### Core Files to Modify
- `scripts/data/minigame_result.gd` - Change effects array type, update methods

### Minigame Files
- `scripts/minigames/berserker_minigame.gd` - Create effect instances
- `scripts/minigames/monk_minigame.gd` - Create effect instances
- `scripts/minigames/time_wizard_minigame.gd` - Create effect instances
- `scripts/minigames/wild_mage_minigame.gd` - Create effect instances
- `scripts/minigames/base_minigame.gd` - May need updates for effect creation

### Combat System Files
- `scripts/scenes/combat.gd` - Remove match statement, apply effects directly

### Status Effect Files (imports needed)
- `scripts/data/status_effects/burn_effect.gd` - Imported by minigames
- `scripts/data/status_effects/silence_effect.gd` - Imported by minigames
- `scripts/data/status_effects/taunt_effect.gd` - Imported by minigames
- `scripts/data/status_effects/alter_attribute_effect.gd` - Imported by minigames
- `scripts/data/status_effects/berserk_effect.gd` - Imported by minigames

## Testing Considerations

1. **Effect Creation**: Verify effects are created correctly in minigames
2. **Target Setting**: Verify effect targets are set correctly
3. **Effect Application**: Verify effects are applied correctly in combat system
4. **Type Safety**: Verify no dictionary access remains
5. **All Effect Types**: Verify all effect types work correctly
6. **Minigame Functionality**: Verify all minigames still work correctly

## Migration Notes

### Breaking Changes
- `MinigameResult.effects` type changes
- `MinigameResult.add_effect()` method removed or changed
- All minigames must create effect instances

### Backward Compatibility
- Not needed - this is a refactor for type safety
- All minigames must be updated

### Effect Creation Pattern

Minigames should follow this pattern:
```gdscript
# Create effect instance
var effect = EffectClass.new(params)
effect.target = target_entity
effect.duration = duration
effect.stacks = stacks
effect.magnitude = magnitude

# Add to result
result.add_status_effect(effect)
```

## Status

Pending (Depends on refactor_02)

