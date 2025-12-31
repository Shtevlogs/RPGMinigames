# BattleState as Source of Truth

**Priority**: Refactor 07 (Architecture Improvement)

## Description

Make `BattleState` the authoritative source of truth for battle state. Currently, entities (Character/EnemyData) are the source of truth, and BattleState is synced from entities. This refactor reverses that - BattleState becomes the source, and entities are synced from BattleState. This simplifies state restoration from auto-save and provides cleaner separation of concerns.

**Design Philosophy**: Battle state should be the single source of truth for combat state. Entities should be views/snapshots of the battle state, not the authoritative source. This makes state management clearer, serialization easier, and restoration more straightforward.

## Context from Architecture Documents

### From ARCHITECTURE_PRIMER.md:
> "Battle state is synced FROM entities, not TO entities. Should be: Battle state → Entities (for restoration)"

> "Current State: Battle state is initialized and updated, but not fully utilized as source of truth. Entities (Character/EnemyData) are still the primary source of truth. Battle state is synced from entities, not the other way around."

> "Battle State Refactor: Make BattleState the source of truth. Implement state restoration from BattleState. Sync entities FROM battle state, not TO battle state."

### From architecture_review_notes.md:
> "Going forward we'll also have to be cognisant of how these behaviors interact with the BattleState as a source of truth."

### From gamedoc.md:
- Auto-save system saves battle state after turn order is determined
- Battle state should be easily serializable
- State restoration should be straightforward
- Battle state contains: turn order, entity states, minigame state

## Dependencies

**Recommended Dependencies**:
- **refactor_01_battle_entity_base_class.md** - BattleEntity simplifies entity handling
- Battle state structure should be stable before this refactor

## Current State

### Current Architecture

1. **BattleState** (`scripts/data/battle_state.gd`):
   - Contains: `turn_order`, `party_states`, `enemy_states`, `minigame_state`
   - `party_states: Array[CharacterBattleState]` - Snapshots of characters
   - `enemy_states: Array[EnemyBattleState]` - Snapshots of enemies
   - Has serialization methods

2. **Current Flow**:
   - Entities (Character/EnemyData) are modified directly
   - BattleState is synced FROM entities (after changes)
   - Auto-save serializes BattleState
   - Restoration would need to sync entities FROM BattleState (not currently done)

3. **Sync Direction**:
   - Current: Entities → BattleState (one-way)
   - Desired: BattleState → Entities (one-way, or bidirectional)

### Problems with Current Approach

1. **State Management**: Entities and BattleState can get out of sync
2. **Restoration Complexity**: Restoring from save requires syncing entities from state
3. **No Single Source**: Two sources of truth (entities and state)
4. **Sync Timing**: When to sync? After every change? Risk of missing updates
5. **Complexity**: Maintaining sync is error-prone

### Existing BattleState Structure

- `turn_order: Array[TurnOrderEntry]` - Current turn order
- `current_turn_index: int` - Index of current turn
- `party_states: Array[CharacterBattleState]` - Party member snapshots
- `enemy_states: Array[EnemyBattleState]` - Enemy snapshots
- `minigame_state: MinigameBattleState` - Minigame-specific state
- `encounter_id: String` - Current encounter identifier
- `turn_count: int` - Turn counter

## Requirements

### Core Functionality

1. **BattleState as Authority**:
   - All state changes go through BattleState
   - BattleState methods modify state directly
   - Entities are synced from BattleState when needed

2. **State Mutation Methods**:
   - `apply_damage_to_entity(entity_id: String, amount: int) -> void`
   - `add_status_effect_to_entity(entity_id: String, effect: StatusEffect) -> void`
   - `modify_entity_attributes(entity_id: String, modifications: Dictionary) -> void`
   - `advance_turn() -> void`
   - `remove_entity_from_turn_order(entity_id: String) -> void`

3. **Entity Syncing**:
   - `sync_entities_from_state() -> void` - Updates all entities from BattleState
   - `sync_entity_from_state(entity_id: String) -> void` - Updates single entity
   - Entities become views of BattleState

4. **State Queries**:
   - `get_entity_state(entity_id: String) -> EntityBattleState`
   - `get_current_turn_entity() -> EntityBattleState`
   - `is_entity_alive(entity_id: String) -> bool`

### Interface Requirements

**BattleState**:
```gdscript
class_name BattleState
extends RefCounted

# State mutation methods
func apply_damage_to_entity(entity_id: String, amount: int) -> void:
    # Modify state directly
    # Update entity state in party_states or enemy_states
    pass

func add_status_effect_to_entity(entity_id: String, effect: StatusEffect) -> void:
    # Add effect to entity state
    # Update state directly
    pass

func sync_entities_from_state() -> void:
    # Update all Character/EnemyData from state
    # Entities become views of state
    pass
```

**Combat System**:
```gdscript
# Instead of: enemy.health.take_damage(amount)
battle_state.apply_damage_to_entity(enemy.entity_id, amount)
battle_state.sync_entities_from_state()  # Update UI entities
```

## Implementation Plan

### Phase 1: Add State Mutation Methods

1. **Update `scripts/data/battle_state.gd`**:
   - Add `apply_damage_to_entity(entity_id: String, amount: int) -> void`
   - Add `heal_entity(entity_id: String, amount: int) -> void`
   - Add `add_status_effect_to_entity(entity_id: String, effect: StatusEffect) -> void`
   - Add `remove_status_effect_from_entity(entity_id: String, effect: StatusEffect) -> void`
   - Add `modify_entity_attributes(entity_id: String, modifications: Dictionary) -> void`
   - Add `set_entity_health(entity_id: String, current: int, max: int) -> void`

2. **Update Entity State Classes**:
   - Ensure `CharacterBattleState` and `EnemyBattleState` support all needed operations
   - Add methods to modify state directly
   - Ensure state classes are mutable

### Phase 2: Add Entity Syncing Methods

1. **Update `scripts/data/battle_state.gd`**:
   - Add `sync_entities_from_state() -> void`
   - Add `sync_entity_from_state(entity_id: String) -> void`
   - Add `get_entity_reference(entity_id: String) -> BattleEntity` (helper for syncing)

2. **Sync Logic**:
   - Find entity by ID (in party or enemies)
   - Update entity properties from state
   - Sync health, attributes, status effects
   - Ensure bidirectional compatibility during transition

### Phase 3: Update Combat System

1. **Update `scripts/scenes/combat.gd`**:
   - Change damage application: Use `battle_state.apply_damage_to_entity()` instead of `entity.health.take_damage()`
   - Change status effect application: Use `battle_state.add_status_effect_to_entity()` instead of `entity.add_status_effect()`
   - Change healing: Use `battle_state.heal_entity()` instead of `entity.health.heal()`
   - After state changes: Call `battle_state.sync_entities_from_state()` to update UI entities

2. **Update Turn Processing**:
   - Use BattleState for turn order queries
   - Use BattleState for current turn information
   - Sync entities after each turn if needed

3. **Update State Queries**:
   - Query BattleState instead of entities directly
   - Use `battle_state.get_entity_state()` for entity information
   - Use `battle_state.is_entity_alive()` for alive checks

### Phase 4: Update State Initialization

1. **Update `scripts/scenes/combat.gd._initialize_battle_state()`**:
   - Initialize BattleState from entities (one-time, at start)
   - Create entity states from entities
   - Set BattleState as source of truth going forward

2. **Initial Sync**:
   - Entities → BattleState (one-time initialization)
   - After initialization: BattleState → Entities (ongoing)

### Phase 5: Update Auto-Save/Restore

1. **Auto-Save** (already works):
   - BattleState is serialized
   - No changes needed

2. **Restore**:
   - Deserialize BattleState
   - Call `sync_entities_from_state()` to restore entities
   - Entities are recreated from state
   - Combat resumes from restored state

### Phase 6: Gradual Migration

1. **Hybrid Approach** (during transition):
   - Some operations use BattleState
   - Some operations still use entities directly
   - Gradually migrate to BattleState

2. **Sync Points**:
   - Sync entities after state mutations
   - Or sync before queries
   - Ensure consistency

## Related Files

### Core Files to Modify
- `scripts/data/battle_state.gd` - Add mutation and sync methods
- `scripts/data/character_battle_state.gd` - Ensure supports all operations
- `scripts/data/enemy_battle_state.gd` - Ensure supports all operations
- `scripts/scenes/combat.gd` - Use BattleState for all state changes

### Entity Files
- `scripts/data/battle_entity.gd` - May need sync methods
- `scripts/data/character.gd` - May need sync from state method
- `scripts/data/enemy_data.gd` - May need sync from state method

### Manager Files
- `scripts/managers/save_manager.gd` - May need updates for restoration
- `scripts/managers/game_manager.gd` - May need updates for state management

## Testing Considerations

1. **State Mutations**: Verify all state mutations work correctly
2. **Entity Syncing**: Verify entities sync correctly from state
3. **State Queries**: Verify state queries return correct information
4. **Auto-Save/Restore**: Verify save and restore work correctly
5. **Consistency**: Verify entities and state stay in sync
6. **Performance**: Verify syncing doesn't cause performance issues

## Migration Notes

### Breaking Changes
- Combat system must use BattleState for state changes
- Entity modifications should go through BattleState
- Sync methods must be called appropriately

### Backward Compatibility
- During transition, hybrid approach may be needed
- Entities can still be accessed for reading (but not writing)
- Gradual migration is possible

### State Mutation Pattern

Before:
```gdscript
enemy.health.take_damage(amount)
character.add_status_effect(effect)
```

After:
```gdscript
battle_state.apply_damage_to_entity(enemy.entity_id, amount)
battle_state.add_status_effect_to_entity(character.entity_id, effect)
battle_state.sync_entities_from_state()  # Update UI
```

## Alternative Approaches

### Option A: Full BattleState Authority
- All operations go through BattleState
- Entities are read-only views
- Cleanest but requires more refactoring

### Option B: Bidirectional Sync
- Both entities and BattleState can be modified
- Sync in both directions
- More complex but allows gradual migration

### Option C: Keep Current (Not Recommended)
- Entities remain source of truth
- BattleState synced from entities
- Simpler but harder to restore

## Status

Completed

## Implementation Notes

- BattleState is now the exclusive access point for all entities during combat
- All `GameManager.current_run.party` accesses replaced with `battle_state.party_states`
- All `current_encounter.enemy_composition` accesses replaced with `battle_state.enemy_states` for combat logic
- Entities can be modified directly (e.g., `entity.take_damage()`) after accessing through BattleState
- No wrapper methods needed - direct entity modification is fine
- No sync methods needed - entities in BattleState are the source of truth
- Initialization still uses GameManager/Encounter sources to populate BattleState (appropriate)
- Display methods updated with fallback for initialization before BattleState is created
- Encounter completion checks BattleState instead of Encounter composition

