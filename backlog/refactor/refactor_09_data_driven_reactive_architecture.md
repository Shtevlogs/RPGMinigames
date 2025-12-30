# Data-Driven Reactive Architecture

**Priority**: Refactor 09 (Architecture Improvement - Depends on refactor_01, refactor_08)

## Description

Implement a data-driven reactive architecture where entities emit signals when their state changes, and UI components react to those signals automatically. This eliminates the need for manual UI update calls and creates a cleaner separation between data and presentation.

**Design Philosophy**: The battle system should operate in a data-driven manner where downstream objects react to data changes. Entities should emit events when they change, and UI should automatically update in response. This follows the Observer pattern and makes the system more maintainable and easier to reason about.

## Context from Architecture Documents

### From architecture_review_notes.md:
> "The battle system should operate in a data-driven manner and downstream objects should react as the data changes. (Like a battle entity taking damage and generating an event that either the Character display or EnemyData reacts to with animations whatever else is necessary)"

### From ARCHITECTURE_PRIMER.md:
- Combat system manually calls `_update_party_displays()` and `_update_enemy_displays()` after state changes
- UI updates are scattered throughout combat logic
- No automatic UI updates when entities change
- Manual update calls are error-prone (easy to forget)

### From gamedoc.md:
- Entities have health, attributes, status effects that change during combat
- UI should reflect entity state accurately
- Visual feedback is important for player experience

## Dependencies

**Critical Dependencies**:
- **refactor_01_battle_entity_base_class.md** - BattleEntity provides unified interface for signals
- **refactor_08_combat_system_decomposition.md** - Combat system should be decomposed first

**Recommended Dependencies**:
- Status effect system should be stable
- UI components should be stable

## Current State

### Current Architecture

1. **Manual UI Updates**:
   - Combat system calls `_update_party_displays()` after state changes
   - Combat system calls `_update_enemy_displays()` after state changes
   - Updates scattered throughout combat logic
   - Easy to forget update calls

2. **Update Call Locations**:
   - After damage application
   - After status effect application
   - After healing
   - After death
   - After turn processing
   - Many other locations

3. **Problems**:
   - Manual updates are error-prone
   - Updates may be missed
   - UI and logic are tightly coupled
   - Difficult to track what triggers updates

### Entity State Changes

Entities change in many ways:
- Health changes (damage, healing)
- Status effects added/removed
- Attributes modified
- Death state changes
- Turn state changes

## Requirements

### Core Functionality

1. **BattleEntity Signals**:
   - `health_changed(new_health: int, max_health: int)` - Emitted when health changes
   - `status_effect_added(effect: StatusEffect)` - Emitted when effect added
   - `status_effect_removed(effect: StatusEffect)` - Emitted when effect removed
   - `entity_died()` - Emitted when entity dies
   - `attributes_changed()` - Emitted when attributes change (optional)

2. **UI Component Connections**:
   - CharacterDisplay connects to character signals
   - EnemyDisplay connects to enemy signals
   - UI updates automatically when signals emitted
   - No manual update calls needed

3. **Combat System Updates**:
   - Remove manual `_update_party_displays()` calls
   - Remove manual `_update_enemy_displays()` calls
   - UI updates happen automatically via signals

### Interface Requirements

**BattleEntity**:
```gdscript
class_name BattleEntity
extends RefCounted

signal health_changed(new_health: int, max_health: int)
signal status_effect_added(effect: StatusEffect)
signal status_effect_removed(effect: StatusEffect)
signal entity_died()
signal attributes_changed()

func take_damage(amount: int) -> int:
    var actual = health.take_damage(amount)
    health_changed.emit(health.current_hp, health.max_hp)
    if not health.is_alive():
        entity_died.emit()
    return actual
```

**CharacterDisplay**:
```gdscript
func set_character(character: Character) -> void:
    # Connect to signals
    character.health_changed.connect(_on_health_changed)
    character.status_effect_added.connect(_on_status_effect_added)
    character.entity_died.connect(_on_entity_died)
    # Initial update
    _update_display()
```

## Implementation Plan

### Phase 1: Add Signals to BattleEntity

1. **Update `scripts/data/battle_entity.gd`**:
   - Add `health_changed` signal
   - Add `status_effect_added` signal
   - Add `status_effect_removed` signal
   - Add `entity_died` signal
   - Add `attributes_changed` signal (optional)

2. **Update Methods to Emit Signals**:
   - `take_damage()` - Emit `health_changed` and `entity_died` if needed
   - `heal()` - Emit `health_changed`
   - `add_status_effect()` - Emit `status_effect_added`
   - Status effect removal - Emit `status_effect_removed`
   - Attribute modifications - Emit `attributes_changed` if needed

### Phase 2: Update StatusEffectManager

1. **Update `scripts/data/status_effect_manager.gd`**:
   - Emit signals when effects added/removed
   - Or delegate to owner entity to emit signals
   - Ensure signals emitted at correct times

2. **Signal Emission**:
   - Emit `status_effect_added` when effect added
   - Emit `status_effect_removed` when effect removed
   - Connect to owner entity signals

### Phase 3: Update UI Components

1. **Update `scripts/ui/character_display.gd`**:
   - Connect to character signals in `set_character()`
   - Implement signal handlers: `_on_health_changed()`, `_on_status_effect_added()`, etc.
   - Remove manual update calls
   - Update display in signal handlers

2. **Update `scripts/ui/enemy_display.gd`**:
   - Connect to enemy signals in `set_enemy()`
   - Implement signal handlers
   - Remove manual update calls
   - Update display in signal handlers

3. **Initial Display**:
   - Update display once when character/enemy is set
   - Subsequent updates via signals

### Phase 4: Update Combat System

1. **Update `scripts/scenes/combat.gd`** (or combat modules after refactor_08):
   - Remove `_update_party_displays()` calls
   - Remove `_update_enemy_displays()` calls
   - UI updates happen automatically via signals

2. **Keep Essential Updates**:
   - May need to keep some manual updates for complex cases
   - Or emit additional signals for those cases
   - Minimize manual updates

### Phase 5: Update Turn Order Display

1. **Turn Order Updates**:
   - Turn order changes may need signals
   - Or keep manual updates for turn order (different concern)
   - Evaluate if signals help or add complexity

2. **Turn Order Signals** (optional):
   - `TurnManager` could emit signals for turn changes
   - Turn order display connects to signals
   - Automatic updates when turn order changes

### Phase 6: Testing and Refinement

1. **Verify Signal Emission**:
   - All state changes emit appropriate signals
   - Signals emitted at correct times
   - No missed updates

2. **Verify UI Updates**:
   - UI updates correctly on all state changes
   - No manual updates needed
   - Performance is acceptable

3. **Refine as Needed**:
   - Add signals for additional state changes if needed
   - Remove any remaining manual updates
   - Optimize signal connections

## Related Files

### Core Files to Modify
- `scripts/data/battle_entity.gd` - Add signals, emit in methods
- `scripts/data/status_effect_manager.gd` - Emit signals or delegate
- `scripts/data/character.gd` - Inherit signals from BattleEntity
- `scripts/data/enemy_data.gd` - Inherit signals from BattleEntity

### UI Files to Modify
- `scripts/ui/character_display.gd` - Connect to signals, implement handlers
- `scripts/ui/enemy_display.gd` - Connect to signals, implement handlers
- `scripts/ui/turn_order_display.gd` - May need updates (optional)

### Combat System Files
- `scripts/scenes/combat.gd` - Remove manual update calls
- `scripts/combat/combat_ui.gd` (after refactor_08) - May need updates

## Testing Considerations

1. **Signal Emission**: Verify all signals are emitted correctly
2. **UI Updates**: Verify UI updates automatically on all state changes
3. **Performance**: Verify signal system doesn't cause performance issues
4. **Memory**: Verify signal connections are cleaned up properly
5. **Edge Cases**: Verify signals work in all scenarios (death, revival, etc.)

## Migration Notes

### Breaking Changes
- UI components must connect to signals
- Manual update calls removed
- Signal-based architecture required

### Backward Compatibility
- Not needed - this is a refactor
- All UI components must be updated
- Gradual migration possible (add signals, keep manual updates during transition)

### Signal Connection Pattern

UI components should follow this pattern:
```gdscript
func set_entity(entity: BattleEntity) -> void:
    # Disconnect previous entity if any
    if current_entity != null:
        _disconnect_signals(current_entity)
    
    current_entity = entity
    
    # Connect to new entity
    entity.health_changed.connect(_on_health_changed)
    entity.status_effect_added.connect(_on_status_effect_added)
    entity.entity_died.connect(_on_entity_died)
    
    # Initial update
    _update_display()
```

## Alternative Approaches

### Option A: Full Signal-Based
- All updates via signals
- No manual updates
- Cleanest but requires all components to support signals

### Option B: Hybrid Approach
- Signals for common updates (health, status effects)
- Manual updates for complex cases
- Easier migration but less clean

### Option C: Event Bus
- Central event bus for all events
- Components subscribe to events
- More decoupled but more complex

## Status

Pending (Depends on refactor_01, refactor_08)

