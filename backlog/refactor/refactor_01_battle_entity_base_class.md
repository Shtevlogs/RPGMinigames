# BattleEntity Base Class

**Priority**: Refactor 01 (Foundation - Must be done first)

## Description

Create a unified `BattleEntity` base class that both `Character` and `EnemyData` extend. This eliminates the need for `Variant` type usage throughout the combat system and provides a single interface for all battle entities. This refactor is foundational - many other refactors depend on it.

**Design Philosophy**: The combat system should operate on a unified entity interface rather than checking types and handling `Character` and `EnemyData` separately. This follows the Liskov Substitution Principle - both party members and enemies should be substitutable through a common interface.

## Context from Architecture Documents

### From architecture_review_notes.md:
> "We'll need refactor slightly, I'd like to see a BattleEntity passed in instead of varient. The BattleEntity can be a base class of the party members and enemies, but the ideal solution would be a separate object that the whole battle system can interact with directly without needing to figure out if it's a Character or EnemyData (as they'll mostly be interacting with the battle system in the same way). We'll have to have a larger discussion on how to proceed here."

> "We should give some thought about how a BattleEntity (a shared class between both Character and EnemyData) would simplify the combat logic."

### From ARCHITECTURE_PRIMER.md:
- Both `Character` and `EnemyData` use `StatusEffectManager` with identical patterns
- Both have `attributes: Attributes`, `health: Health`, `status_manager: StatusEffectManager`
- Both implement `get_effective_attributes()`, `add_status_effect()`, `tick_status_effects()`, `has_status_effect()`
- Combat system currently uses `Variant` for combatants, requiring type checks throughout

### From gamedoc.md:
- Combat system handles both party members and enemies in similar ways
- Turn order system treats both as combatants
- Status effects apply to both types identically
- Both have attributes, health, and status effects

## Dependencies

**None** - This is the first foundation refactor. Other refactors depend on this one:
- refactor_02_status_effect_system_refactor.md (StatusEffectManager owner should be BattleEntity)
- refactor_08_combat_system_decomposition.md (Simplifies combat logic significantly)
- refactor_09_data_driven_reactive_architecture.md (Signals added to BattleEntity)

## Current State

### Problems with Current Architecture

1. **Type Checking Everywhere**: Combat system constantly checks `if target is Character` or `if target is EnemyData`
2. **Variant Usage**: Many methods accept `Variant` parameters, losing type safety
3. **Code Duplication**: Similar logic exists for both Character and EnemyData
4. **Maintenance Burden**: Changes to entity interface require updates in two places

### Existing Similarities

Both `Character` and `EnemyData` have:
- `attributes: Attributes`
- `health: Health`
- `status_manager: StatusEffectManager`
- `get_effective_attributes() -> Attributes`
- `add_status_effect(effect: StatusEffect) -> void`
- `tick_status_effects() -> Dictionary`
- `has_status_effect(effect_class: GDScript) -> bool`
- `duplicate()` method

### Current Combat System Usage

In `scripts/scenes/combat.gd`:
- `get_current_turn_combatant() -> Variant` returns Character or EnemyData
- `_apply_effect()` checks `if target is Character` vs `if target is EnemyData`
- `_select_enemy_target()` only works with Character
- Turn order entries store `combatant: Variant`
- Many methods accept `Variant` for combatants

## Requirements

### Core Functionality

1. **BattleEntity Base Class**:
   - Extends `RefCounted`
   - Contains common properties: `attributes`, `health`, `status_manager`
   - Defines common interface methods
   - Provides `entity_id: String` and `display_name: String` for unified identification

2. **Character Refactor**:
   - Extends `BattleEntity` instead of `RefCounted` directly
   - Adds class-specific properties: `class_type`, `equipment`, `class_state`
   - Maintains backward compatibility where possible

3. **EnemyData Refactor**:
   - Extends `BattleEntity` instead of `RefCounted` directly
   - Adds enemy-specific properties: `enemy_id`, `enemy_type`, `abilities`
   - Maintains backward compatibility where possible

4. **Combat System Updates**:
   - Replace all `Variant` combatant types with `BattleEntity`
   - Remove type checking (`is Character`, `is EnemyData`)
   - Use unified interface methods
   - Update turn order system to use `BattleEntity`

5. **Type Safety**:
   - All combat-related methods should accept `BattleEntity` instead of `Variant`
   - Remove need for type checking in combat logic
   - Maintain type safety throughout

### Interface Requirements

`BattleEntity` must provide:
- `entity_id: String` - Unique identifier
- `display_name: String` - Display name (character name or enemy name)
- `attributes: Attributes` - Entity attributes
- `health: Health` - Entity health
- `status_manager: StatusEffectManager` - Status effect manager
- `get_effective_attributes() -> Attributes` - Get attributes with modifications
- `add_status_effect(effect: StatusEffect) -> void` - Add status effect
- `tick_status_effects() -> Dictionary` - Process status effects
- `has_status_effect(effect_class: GDScript) -> bool` - Check for status effect
- `is_alive() -> bool` - Check if entity is alive
- `take_damage(amount: int) -> int` - Apply damage, return actual damage dealt
- `is_party_member() -> bool` - Determine if entity is party member (for UI/targeting)

## Implementation Plan

### Phase 1: Create BattleEntity Base Class

1. **Create `scripts/data/battle_entity.gd`**:
   ```gdscript
   class_name BattleEntity
   extends RefCounted
   
   var entity_id: String
   var display_name: String
   var attributes: Attributes
   var health: Health
   var status_manager: StatusEffectManager
   
   func _init(p_entity_id: String = "", p_display_name: String = ""):
       entity_id = p_entity_id
       display_name = p_display_name
       attributes = Attributes.new()
       status_manager = StatusEffectManager.new(self)
   
   func get_effective_attributes() -> Attributes:
       # Base implementation - subclasses can override
       var base = attributes.duplicate()
       for effect in status_manager.status_effects:
           effect.on_modify_attributes(base)
       return base
   
   func add_status_effect(effect: StatusEffect) -> void:
       status_manager.add_status_effect(effect)
   
   func tick_status_effects() -> Dictionary:
       return status_manager.tick_status_effects()
   
   func has_status_effect(effect_class: GDScript) -> bool:
       return status_manager.has_status_effect(effect_class)
   
   func is_alive() -> bool:
       return health.is_alive()
   
   func take_damage(amount: int) -> int:
       return health.take_damage(amount)
   
   func is_party_member() -> bool:
       return false  # Override in Character
   
   func duplicate() -> BattleEntity:
       push_error("duplicate() must be implemented in subclass")
       return null
   ```

2. **Update StatusEffectManager**:
   - Change `owner: Variant` to `owner: BattleEntity`
   - Update `_init()` parameter type

### Phase 2: Refactor Character

1. **Update `scripts/data/character.gd`**:
   - Change `extends RefCounted` to `extends BattleEntity`
   - Update `_init()` to call `super._init()` with entity_id and name
   - Move common properties to base class
   - Keep class-specific properties: `class_type`, `equipment`, `class_state`
   - Override `is_party_member()` to return `true`
   - Update `duplicate()` to return `Character` type

2. **Update health initialization**:
   - Move health calculation to `_init()` after calling `super._init()`
   - Set `health` property on base class

### Phase 3: Refactor EnemyData

1. **Update `scripts/data/enemy_data.gd`**:
   - Change `extends RefCounted` to `extends BattleEntity`
   - Update `_init()` to call `super._init()` with enemy_id and enemy_name
   - Move common properties to base class
   - Keep enemy-specific properties: `enemy_type`, `abilities`
   - Update `duplicate()` to return `EnemyData` type

2. **Update health initialization**:
   - Move health calculation to `_init()` after calling `super._init()`
   - Set `health` property on base class

### Phase 4: Update Combat System

1. **Update type signatures in `scripts/scenes/combat.gd`**:
   - Change `get_current_turn_combatant() -> Variant` to `-> BattleEntity`
   - Change `_apply_effect()` parameter from `target: Variant` to `target: BattleEntity`
   - Change `_select_enemy_target()` to work with `BattleEntity`
   - Update all combatant variables to `BattleEntity` type

2. **Remove type checking**:
   - Remove `if target is Character` checks
   - Remove `if target is EnemyData` checks
   - Use `target.is_party_member()` for party/enemy distinction
   - Use unified `target.display_name` instead of `character.name` or `enemy.enemy_name`

3. **Update turn order system**:
   - Change `TurnOrderEntry.combatant: Variant` to `combatant: BattleEntity`
   - Update turn order creation to use `BattleEntity`

4. **Update UI display methods**:
   - Update `_update_party_displays()` to work with `BattleEntity`
   - Update `_update_enemy_displays()` to work with `BattleEntity`
   - Use `is_party_member()` to determine which display to update

### Phase 5: Update Related Systems

1. **Update BaseClassBehavior**:
   - Change `build_minigame_context()` parameter from `_character: Character` to `_entity: BattleEntity`
   - Update behavior implementations to accept `BattleEntity`
   - Cast to `Character` when class-specific properties are needed

2. **Update MinigameResult**:
   - Update effect target references to use `BattleEntity`

3. **Update BattleState**:
   - Update `CharacterBattleState` and `EnemyBattleState` to reference `BattleEntity`
   - Or create unified `EntityBattleState` that works with `BattleEntity`

4. **Update other systems**:
   - Search codebase for `Variant` usage with combatants
   - Update to use `BattleEntity` where appropriate

## Related Files

### Core Files to Modify
- `scripts/data/battle_entity.gd` - **NEW FILE** - Base class definition
- `scripts/data/character.gd` - Refactor to extend BattleEntity
- `scripts/data/enemy_data.gd` - Refactor to extend BattleEntity
- `scripts/data/status_effect_manager.gd` - Update owner type to BattleEntity

### Combat System Files
- `scripts/scenes/combat.gd` - Major refactor to use BattleEntity
- `scripts/data/battle_state.gd` - Update to use BattleEntity
- `scripts/data/turn_order_entry.gd` - Update combatant type

### Behavior System Files
- `scripts/class_behaviors/base_class_behavior.gd` - Update to accept BattleEntity
- `scripts/class_behaviors/berserker_behavior.gd` - Update implementations
- `scripts/class_behaviors/monk_behavior.gd` - Update implementations
- `scripts/class_behaviors/time_wizard_behavior.gd` - Update implementations
- `scripts/class_behaviors/wild_mage_behavior.gd` - Update implementations

### Data Files
- `scripts/data/minigame_result.gd` - Update effect target types
- `scripts/data/character_battle_state.gd` - May need refactor
- `scripts/data/enemy_battle_state.gd` - May need refactor

### UI Files
- `scripts/ui/character_display.gd` - May need updates for BattleEntity
- `scripts/ui/enemy_display.gd` - May need updates for BattleEntity

## Testing Considerations

1. **Type Safety**: Verify all type errors are resolved
2. **Functionality**: Ensure combat still works correctly
3. **Status Effects**: Verify status effects work on both types
4. **Turn Order**: Verify turn order system works correctly
5. **UI Updates**: Verify party and enemy displays update correctly
6. **Minigames**: Verify minigames still receive correct context

## Status

✅ **Completed**

All requirements have been implemented:
- ✅ BattleEntity base class created with unified interface
- ✅ Character refactored to CharacterBattleEntity extending BattleEntity
- ✅ EnemyData refactored to EnemyBattleEntity extending BattleEntity
- ✅ Combat system updated to use BattleEntity instead of Variant
- ✅ Type checking removed, using unified interface methods
- ✅ GameStateSerializable base class added for serialization
- ✅ get_effective_attributes() functionality in base class
- ✅ All combat logic unified to work with BattleEntity interface

