# Status Effect System Refactor

**Priority**: Refactor 02 (Foundation - Depends on refactor_01)

## Description

Refactor the status effect system so that effects apply their changes directly rather than returning dictionaries. Effects should have access to `BattleState` to perform their actions, and a new `on_remove()` method should be implemented for cleanup logic. This eliminates the dictionary accumulation pattern and makes effects more self-contained.

**Design Philosophy**: Status effects should be responsible for applying their own effects rather than returning data for external processing. This follows the Single Responsibility Principle - effects know what they do and how to do it. The `BattleState` provides the necessary context for effects to operate.

## Context from Architecture Documents

### From architecture_review_notes.md:
> "StatusEffect on_tick should be an object. The cumulative_effects Dictionary in status_effect_manager tick_status_effects can probably be the same class of object. That object can then be returned into whatever is calling this."

> "Actually, instead of returning a tick result object at all, ticks should just apply their effects in the effect code. Enough of the BattleState should be accessible from these functions to do what they need to do."

> "We should also implement an on_remove function for these, in case there is logic that needs to happen as a status is removed."

> "Owner should be a BattleEntity (see above)." (referring to refactor_01)

> "No need to collect on_tick return values, see notes in next section."

### From ARCHITECTURE_PRIMER.md:
- Current system: `on_tick()` returns `Dictionary`, `StatusEffectManager.tick_status_effects()` accumulates dictionaries
- Manager pattern: `tick_status_effects()` processes all effects and returns cumulative effects dictionary
- Current flow: Effects return data → Manager accumulates → Combat system applies
- Desired flow: Effects apply directly → Manager coordinates → No accumulation needed

### From gamedoc.md:
- Status effects are processed at the start of each turn
- Effects can deal damage, modify attributes, or have other turn-based effects
- Effects are removed when duration expires or entity dies
- Some effects need cleanup logic when removed (e.g., restoring attributes)

## Dependencies

**Critical Dependencies**:
- **refactor_01_battle_entity_base_class.md** - StatusEffectManager owner must be BattleEntity, effects need BattleEntity references

**Recommended Dependencies**:
- Status effect system should be stable before this refactor (effects already implemented)

## Current State

### Current Architecture

1. **StatusEffect.on_tick()**:
   - Returns `Dictionary` with effects to apply (e.g., `{"damage": 5}`)
   - Returns `{"remove": true}` to force removal
   - Does not apply effects directly

2. **StatusEffectManager.tick_status_effects()**:
   - Calls `on_tick()` on each effect
   - Accumulates return values into `cumulative_effects: Dictionary`
   - Returns accumulated dictionary to caller
   - Removes effects that return `{"remove": true}` or have expired duration

3. **Combat System Processing**:
   - Calls `tick_status_effects()` on entity
   - Receives cumulative effects dictionary
   - Applies damage, modifications, etc. from dictionary
   - Updates UI displays

### Problems with Current Approach

1. **Separation of Concerns**: Effects know what to do but don't do it - they return data
2. **Dictionary Accumulation**: Manager accumulates dictionaries, losing type safety
3. **No Cleanup Logic**: Effects can't perform cleanup when removed
4. **Limited Context**: Effects don't have access to battle state for complex operations
5. **Indirect Application**: Combat system must interpret effect dictionaries

### Existing Status Effects

Current effects that need refactoring:
- `BurnEffect` - Returns `{"damage": amount}` from `on_tick()`
- `SilenceEffect` - Returns empty dictionary (no turn-based effects)
- `TauntEffect` - Returns empty dictionary (no turn-based effects)
- `AlterAttributeEffect` - Modifies attributes via `on_modify_attributes()`
- `BerserkEffect` - May have turn-based logic

## Requirements

### Core Functionality

1. **Direct Effect Application**:
   - `on_tick()` should apply effects directly instead of returning dictionaries
   - Effects should have access to `BattleState` for context
   - Effects should have access to their target `BattleEntity`

2. **on_remove() Method**:
   - New virtual method `on_remove(battle_state: BattleState) -> void`
   - Called when effect is removed (expired, death, or forced removal)
   - Allows effects to perform cleanup logic

3. **StatusEffectManager Updates**:
   - Remove dictionary accumulation from `tick_status_effects()`
   - Pass `BattleState` to `on_tick()` and `on_remove()`
   - Return `void` instead of `Dictionary`

4. **Combat System Updates**:
   - Remove dictionary processing from status effect tick handling
   - Effects handle their own application
   - Update `_process_combatant_status_effects()` to work with new system

### Interface Requirements

**StatusEffect.on_tick()**:
```gdscript
func on_tick(battle_state: BattleState) -> void:
    # Apply effects directly
    # Access battle_state for context
    # Access target property for entity reference
    pass
```

**StatusEffect.on_remove()**:
```gdscript
func on_remove(battle_state: BattleState) -> void:
    # Perform cleanup logic
    # Restore modified values if needed
    pass
```

**StatusEffectManager.tick_status_effects()**:
```gdscript
func tick_status_effects(battle_state: BattleState) -> void:
    # Process all effects
    # Call on_tick() with battle_state
    # Call on_remove() for removed effects
    # No return value needed
```

### Effect Application Patterns

Effects should apply changes directly:
- **Damage Effects**: Call `target.take_damage(amount)` directly
- **Attribute Modifications**: Already handled via `on_modify_attributes()`
- **Complex Effects**: Use `battle_state` to access other entities, turn order, etc.

## Implementation Plan

### Phase 1: Update StatusEffect Base Class

1. **Update `scripts/data/status_effect.gd`**:
   - Change `on_tick(combatant: Variant) -> Dictionary` to `on_tick(battle_state: BattleState) -> void`
   - Add new method `on_remove(battle_state: BattleState) -> void`
   - Update default implementations
   - Update documentation

2. **Update target property**:
   - Change `target: Variant` to `target: BattleEntity` (after refactor_01)
   - Effects can access target directly for damage, modifications, etc.

### Phase 2: Update StatusEffectManager

1. **Update `scripts/data/status_effect_manager.gd`**:
   - Change `tick_status_effects() -> Dictionary` to `tick_status_effects(battle_state: BattleState) -> void`
   - Remove `cumulative_effects` dictionary
   - Remove accumulation logic
   - Call `on_tick(battle_state)` on each effect
   - Call `on_remove(battle_state)` on effects being removed
   - Update `owner` type to `BattleEntity` (from refactor_01)

2. **Update effect removal logic**:
   - Track effects to remove
   - Call `on_remove()` before removing
   - Remove effects after processing all ticks

### Phase 3: Update Concrete Status Effects

1. **Update `BurnEffect`** (`scripts/data/status_effects/burn_effect.gd`):
   - Change `on_tick()` to apply damage directly: `target.take_damage(damage_amount)`
   - Remove dictionary return
   - Add logging if needed (or let combat system handle)

2. **Update `SilenceEffect`** (`scripts/data/status_effects/silence_effect.gd`):
   - `on_tick()` can remain empty (no turn-based effects)
   - Add `on_remove()` if cleanup needed

3. **Update `TauntEffect`** (`scripts/data/status_effects/taunt_effect.gd`):
   - `on_tick()` can remain empty (no turn-based effects)
   - Add `on_remove()` if cleanup needed

4. **Update `AlterAttributeEffect`** (`scripts/data/status_effects/alter_attribute_effect.gd`):
   - `on_tick()` can remain empty (attributes modified via `on_modify_attributes()`)
   - Add `on_remove()` to restore attributes if needed (or handle via duration)

5. **Update `BerserkEffect`** (`scripts/data/status_effects/berserk_effect.gd`):
   - Update `on_tick()` to apply any turn-based effects directly
   - Add `on_remove()` for cleanup if needed

### Phase 4: Update Combat System

1. **Update `scripts/scenes/combat.gd`**:
   - Change `_process_combatant_status_effects()` to:
     - Call `tick_status_effects(battle_state)` (no return value)
     - Remove dictionary processing
     - Handle damage application within effects (or track separately if needed)
   - Update damage handling:
     - Effects apply damage directly via `target.take_damage()`
     - Combat system may need to track damage for logging/UI updates
     - Consider adding damage tracking to `BattleState` or effect system

2. **Update death handling**:
   - Ensure `on_remove()` is called when entity dies
   - Update `clear_effects()` to call `on_remove()` before clearing

3. **Update UI updates**:
   - Effects may trigger UI updates directly (via signals) or combat system handles
   - Ensure health changes from effect damage update UI correctly

### Phase 5: BattleState Integration

1. **Ensure BattleState is accessible**:
   - Combat system should pass `battle_state` to `tick_status_effects()`
   - Effects can access battle state for:
     - Other entities (for party-wide effects)
     - Turn order (for timing-based effects)
     - Encounter state (for encounter-specific effects)

2. **Update BattleState if needed**:
   - May need methods for effects to query state
   - May need methods for effects to modify state (carefully)

## Related Files

### Core Files to Modify
- `scripts/data/status_effect.gd` - Update `on_tick()` signature, add `on_remove()`
- `scripts/data/status_effect_manager.gd` - Remove dictionary accumulation, update method signatures

### Status Effect Files
- `scripts/data/status_effects/burn_effect.gd` - Apply damage directly
- `scripts/data/status_effects/silence_effect.gd` - Add `on_remove()` if needed
- `scripts/data/status_effects/taunt_effect.gd` - Add `on_remove()` if needed
- `scripts/data/status_effects/alter_attribute_effect.gd` - Add `on_remove()` for attribute restoration
- `scripts/data/status_effects/berserk_effect.gd` - Update turn-based logic

### Combat System Files
- `scripts/scenes/combat.gd` - Update status effect processing
- `scripts/data/battle_state.gd` - Ensure accessible to effects

### Entity Files (after refactor_01)
- `scripts/data/battle_entity.gd` - Update `tick_status_effects()` signature
- `scripts/data/character.gd` - Update method signature
- `scripts/data/enemy_data.gd` - Update method signature

## Testing Considerations

1. **Effect Application**: Verify effects apply correctly (damage, modifications)
2. **Cleanup Logic**: Verify `on_remove()` is called and works correctly
3. **BattleState Access**: Verify effects can access battle state when needed
4. **Turn Processing**: Verify status effects process correctly each turn
5. **Death Cleanup**: Verify effects are cleaned up on entity death
6. **UI Updates**: Verify UI updates correctly when effects apply changes

## Migration Notes

### Breaking Changes
- `StatusEffect.on_tick()` signature changes (return type and parameter)
- `StatusEffectManager.tick_status_effects()` signature changes (return type and parameter)
- Combat system must be updated to not process dictionaries

### Backward Compatibility
- Not needed - this is a refactor, not a feature addition
- All existing effects must be updated

## Status

✅ **Completed**

All requirements have been implemented:
- ✅ StatusEffect.on_tick() signature changed to accept BattleState and return void
- ✅ StatusEffect.on_remove() method added with BattleState parameter
- ✅ StatusEffectManager.tick_status_effects() updated to accept BattleState and return void
- ✅ Dictionary accumulation removed from StatusEffectManager
- ✅ StatusEffectManager.clear_effects() updated to accept BattleState and call on_remove()
- ✅ All concrete status effects updated (BurnEffect, SilenceEffect, TauntEffect, AlterAttributeEffect, BerserkEffect)
- ✅ BurnEffect applies damage directly and handles logging through BattleState
- ✅ BattleEntity.tick_status_effects() signature updated
- ✅ Combat system updated to pass battle_state and detect health changes for UI updates
- ✅ Death handling updated to pass battle_state to clear_effects()
- ✅ BattleState.combat_log property added for effects to use for logging
- ✅ BaseClassBehavior.battle_state property added for behaviors to access battle state
- ✅ BerserkerBehavior updated to use battle_state property for on_remove() calls

