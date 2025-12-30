# Architecture Primer

## Overview

This document provides a comprehensive overview of the current architecture of the roguelike JRPG project. The game features turn-based combat where character abilities are resolved through themed minigames (blackjack, minesweeper, rock-paper-scissors, poker).

## Core Architecture Patterns

### 1. Registry Pattern (MinigameRegistry)

The project uses a registry pattern to decouple the combat system from specific character classes. This follows the Open/Closed Principle - new classes can be added without modifying existing combat code.

**Location**: `scripts/managers/minigame_registry.gd`

**Key Components**:
- `class_behaviors: Dictionary` - Maps class types to behavior instances
- `minigame_scenes: Dictionary` - Maps class types to scene paths

**Benefits**:
- Combat system doesn't need to know about all classes
- Adding new classes doesn't require modifying combat code
- Single source of truth for class-to-minigame mappings

### 2. Behavior Pattern (BaseClassBehavior)

Class-specific logic is encapsulated in behavior classes that extend `BaseClassBehavior`. This eliminates match statements in the combat system.

**Location**: `scripts/class_behaviors/base_class_behavior.gd`

**Key Methods**:
- `needs_target_selection() -> bool` - Determines if target selection is required
- `build_minigame_context(character, target) -> MinigameContext` - Builds class-specific context
- `apply_attack_effects(attacker, target, base_damage) -> int` - Applies on-attack effects
- `format_minigame_result(character, result) -> Array[String]` - Formats logging
- `get_ability_target(character, result) -> Variant` - Determines ability target

**Current Implementations**:
- `BerserkerBehavior` - Handles berserk state, effect ranges
- `MonkBehavior` - Handles RPS card effects
- `TimeWizardBehavior` - Handles timeline events
- `WildMageBehavior` - Handles poker hand effects

### 3. Composition Pattern (StatusEffectManager)

Status effects use composition to eliminate code duplication between `Character` and `EnemyData`.

**Location**: `scripts/data/status_effect_manager.gd`

**Key Features**:
- Encapsulates all status effect management logic
- Single source of truth for status effect operations
- Backward compatible (entities expose `status_effects` property that delegates to manager)

### 4. Polymorphism Pattern (StatusEffect)

Status effects use polymorphism with a base class and virtual methods.

**Location**: `scripts/data/status_effect.gd`

**Key Virtual Methods**:
- `on_apply(target, status_effects_array)` - Handles application logic (matching, stacking)
- `on_tick(combatant) -> Dictionary` - Processes turn-based effects
- `on_modify_attributes(attributes)` - Modifies attributes when calculating effective attributes
- `_matches_existing_effect(existing)` - Custom matching logic (e.g., by attribute name)

**Current Implementations**:
- `BurnEffect` - Stackable damage over time
- `SilenceEffect` - Prevents ability usage (class-specific interactions)
- `TauntEffect` - Forces enemy targeting
- `AlterAttributeEffect` - Modifies attributes (stackable, matches by attribute name)
- `BerserkEffect` - Berserker-specific state effect

## System Architecture

### Combat System

**Location**: `scripts/scenes/combat.gd`

The combat system is the central orchestrator for battle flow. It manages:

1. **Turn Order System**:
   - Dynamic turn order using roll system: `random(10-20) - speed`
   - Lower turn values act first
   - After each action, new roll is added to previous turn value
   - Dead combatants are removed from turn order
   - Turn order is synced to `BattleState` for auto-save

2. **Action System**:
   - **Attack**: Basic physical attack with class-specific on-attack effects
   - **Spell/Ability**: Triggers minigame modal with class-specific context
   - **Item**: Placeholder (not fully implemented)

3. **Target Selection**:
   - Mouse-based selection (click on entities)
   - Visual feedback (highlighting, selection arrow)
   - Cancel support for attacks (not for abilities)

4. **Minigame Integration**:
   - Modal system (`MinigameModal`) overlays combat scene
   - Context built by behavior classes
   - Results applied generically (damage, effects)
   - Class-specific logging via behavior classes

5. **Status Effect Processing**:
   - Processed at start of each turn
   - Damage from effects (e.g., burn)
   - Attribute modifications (e.g., AlterAttributeEffect)
   - Death handling from status effect damage

6. **Death Handling**:
   - Enemies: Removed from encounter, vanish from UI
   - Party members: Greyed out, remain visible, removed from turn order
   - Status effects cleared on death

### Battle State Management

**Location**: `scripts/data/battle_state.gd`

The `BattleState` class serves as the source of truth for battle state:

**Key Properties**:
- `turn_order: Array[TurnOrderEntry]` - Current turn order
- `current_turn_index: int` - Index of current turn
- `party_states: Array[CharacterBattleState]` - Party member snapshots
- `enemy_states: Array[EnemyBattleState]` - Enemy snapshots
- `minigame_state: MinigameBattleState` - Minigame-specific state (if any)

**Auto-Save Integration**:
- Auto-saves occur after turn order is determined (every turn)
- Full state snapshot serialized to `GameManager.current_run.auto_save_data`
- Failed saves print debug error and continue (non-blocking)

**Current State**:
- Battle state is initialized and updated, but not fully utilized as source of truth
- Entities (Character/EnemyData) are still the primary source of truth
- Battle state is synced from entities, not the other way around

### Delay/Timing System

**Location**: `scripts/managers/delay_manager.gd`

Centralized delay system with configurable constants:

**Key Constants**:
- `ACTION_MENU_BEAT_DURATION: 0.3`
- `MINIGAME_OPEN_BEAT_DURATION: 0.4`
- `MINIGAME_CLOSE_BEAT_DURATION: 0.4`
- `TURN_HIGHLIGHT_DURATION: 0.3`
- `ENEMY_ACTION_ANIMATION_DURATION: 0.5`
- `ATTACK_ANIMATION_DURATION: 0.6`
- `DEATH_ANIMATION_DURATION: 0.8`

**Usage**:
- `await DelayManager.wait(duration)` - Async wait for duration
- Used throughout combat for sequential event coordination

**Current State**:
- Delays are implemented but many animations are placeholders
- Input blocking is implemented (`is_input_blocked` flag)
- Sequential logic is enforced (minigame must open before input, animations must finish)

### VFX Manager

**Location**: `scripts/managers/vfx_manager.gd`

Centralized VFX system using registry pattern:

**Key Features**:
- Pool of ~10 VFX nodes (greedy reuse if pool exhausted)
- Registry pattern with `EffectIds` enum
- Takes position and `VFXConfig` object
- Effects are world-space (don't attach to entities)

**Current State**:
- Pool system implemented
- Placeholder nodes (actual VFX not implemented)
- `play_effect()` method exists but doesn't play actual effects yet

### Sound Manager

**Location**: `scripts/managers/sound_manager.gd`

Centralized sound system for BGM and SFX:

**Key Features**:
- Single BGM track and single SFX track (for alpha)
- Simple interface: `play_sfx(sound_id)`, `change_bgm(music_id)`
- Volume control methods

**Current State**:
- Audio players created
- Placeholder methods (actual sound loading not implemented)
- Sound ID constants defined

### Minigame System

**Base Class**: `scripts/minigames/base_minigame.gd`

All minigames extend `BaseMinigame`:

**Key Features**:
- Emits `minigame_completed` signal with `MinigameResult`
- Receives context (character, target, class-specific data)
- Modal integration via `MinigameModal`

**MinigameResult Structure**:
- `success: bool` - Whether minigame succeeded
- `performance_score: float` - Performance metric (0.0-1.0)
- `damage: int` - Damage to apply
- `effects: Array[Dictionary]` - Status effects and other effects
- `metadata: Dictionary` - Class-specific data

**Current Minigames**:
- Berserker: Blackjack minigame
- Monk: Rock-paper-scissors minigame
- Time Wizard: Minesweeper minigame
- Wild Mage: Poker minigame

### Status Effect System

**Architecture**: Polymorphism with composition

**Base Class**: `scripts/data/status_effect.gd`

**Manager**: `scripts/data/status_effect_manager.gd`

**Key Features**:
- Self-managing application logic (`on_apply()` handles matching and stacking)
- Turn-based processing (`on_tick()` returns effects dictionary)
- Attribute modification (`on_modify_attributes()`)
- Custom matching logic (`_matches_existing_effect()`)

**Lifecycle**:
1. Effect created and added via `add_status_effect()`
2. Manager calls `effect.on_apply()` which handles matching/stacking
3. At turn start, `tick_status_effects()` processes all effects
4. Each effect's `on_tick()` called, then `tick()` decrements duration
5. Effects removed when duration reaches 0 or `on_tick()` returns `{"remove": true}`

**Integration Points**:
- Minigame results include effects in `effects` array
- Combat system applies effects via `_apply_effect()` match statement
- Entities use `StatusEffectManager` for all status effect operations

### Data Structures

**Character**: `scripts/data/character.gd`
- Attributes, health, equipment, status effects
- `get_effective_attributes()` - Calculates attributes with equipment and status effects
- `class_state: Dictionary` - Class-specific state (effect ranges, berserk stacks, etc.)

**EnemyData**: `scripts/data/enemy_data.gd`
- Similar structure to Character but for enemies
- Uses same status effect system

**Attributes**: `scripts/data/attributes.gd`
- Five attributes: Power, Skill, Strategy, Speed, Luck
- Duplication support

**Health**: `scripts/data/health.gd`
- Current HP, max HP
- `take_damage()`, `heal()`, `is_alive()`

**EquipmentSlots**: `scripts/data/equipment_slots.gd`
- Ring slots (2), Neck slot (1), Armor slot (1), Head slot (1), Class-specific slots (1-2)
- `get_total_attribute_bonuses()` - Sums all equipment bonuses

### Manager Systems

**GameManager**: `scripts/managers/game_manager.gd`
- Manages `current_run: RunState`
- Persistent currency system
- Run lifecycle (start, end)

**StateManager**: `scripts/managers/state_manager.gd`
- Temporary state storage for scene transitions
- Encounter state, combat state, minigame context

**EncounterManager**: `scripts/managers/encounter_manager.gd`
- Encounter pools by land theme and difficulty
- `get_next_encounter()` - Selects encounter based on run progress
- Placeholder encounter system (creates simple encounters)

**SceneManager**: `scripts/managers/scene_manager.gd`
- Scene transitions
- Land screen, combat, main menu

**SaveManager**: `scripts/managers/save_manager.gd`
- Auto-save system
- Run state persistence

## Data Flow

### Combat Flow

```
1. Combat Initialization
   ├─ Load encounter from EncounterManager
   ├─ Display party and enemies
   ├─ Initialize BattleState
   └─ Show encounter message (delay)

2. Turn Order Calculation
   ├─ Roll turn values for all combatants
   ├─ Sort by turn value (lower first)
   ├─ Sync to BattleState
   └─ Auto-save

3. Turn Processing
   ├─ Highlight current turn combatant
   ├─ Process status effects
   ├─ If enemy: Execute attack automatically
   └─ If party: Show action menu

4. Action Execution
   ├─ Attack: Target selection → Execute → Advance turn
   ├─ Ability: Target selection (if needed) → Minigame → Apply results → Advance turn
   └─ Item: Apply effect → Advance turn

5. Turn Advancement
   ├─ Remove current turn entry
   ├─ Add new turn entry (if alive)
   ├─ Remove dead combatants
   ├─ Re-sort turn order
   ├─ Sync to BattleState
   └─ Auto-save
```

### Minigame Flow

```
1. Ability Selected
   ├─ Check if target selection needed (via behavior)
   ├─ If needed: Start target selection
   └─ If not: Open minigame modal

2. Minigame Opening
   ├─ Block input
   ├─ Build context (via behavior)
   ├─ Create MinigameModal
   ├─ Load minigame scene
   ├─ Set context on minigame instance
   ├─ Wait for open delay
   └─ Unblock input

3. Minigame Execution
   ├─ Player plays minigame
   ├─ Minigame emits result when complete
   └─ Modal receives result

4. Minigame Closing
   ├─ Block input
   ├─ Close modal (with delay)
   ├─ Apply results (damage, effects)
   ├─ Unblock input
   └─ Advance turn
```

### Status Effect Flow

```
1. Effect Application
   ├─ Effect created from minigame result or item
   ├─ `add_status_effect()` called on target
   ├─ Manager calls `effect.on_apply()`
   ├─ Effect finds matching existing effect
   ├─ Updates existing (stack/refresh) or appends self
   └─ Logs application

2. Effect Processing (Turn Start)
   ├─ `tick_status_effects()` called on combatant
   ├─ Manager processes all effects
   ├─ Each effect's `on_tick()` called
   ├─ Accumulate effects (damage, etc.)
   ├─ Each effect's `tick()` decrements duration
   ├─ Remove expired effects
   └─ Apply accumulated effects (damage, etc.)

3. Attribute Modification
   ├─ `get_effective_attributes()` called
   ├─ Base attributes + equipment bonuses
   ├─ Each status effect's `on_modify_attributes()` called
   └─ Return modified attributes
```

## Current State vs Battle Refactor Goals

### Implemented Features

✅ **Turn Order System**
- Dynamic turn order with roll system
- Dead combatant removal
- Turn order display (basic UI)
- Battle state sync

✅ **Delay/Timing System**
- Configurable delay constants
- Async wait system
- Input blocking

✅ **Status Effect System**
- Polymorphic effect system
- Composition pattern (StatusEffectManager)
- Turn-based processing
- Attribute modification

✅ **Minigame Integration**
- Modal system
- Behavior-based context building
- Generic result application

✅ **Battle State**
- BattleState class exists
- Auto-save integration
- Serialization support

✅ **VFX/Sound Managers**
- Manager structure exists
- Pool system (VFX)
- Placeholder implementations

### Missing/Incomplete Features

❌ **Visual Feedback**
- Turn highlighting (enemy glow, party border) - partially implemented
- Selection arrow animation - not implemented
- Party display animations (down/up) - placeholders
- Action menu slide-in animation - placeholder
- Attack animations (shake, flash) - placeholders
- Death animations - not implemented

❌ **Enemy Turn Behavior**
- Enemy highlight animation (wiggle) - not implemented
- Enemy action indication - not implemented
- Wind-up messages - system exists but not used

❌ **Action Menu**
- Slide-in animation - placeholder
- Sound cues on hover/select - partially implemented
- Menu positioning - fixed location (not near active character)

❌ **Target Selection**
- Selection arrow animation - not implemented
- Arrow movement between targets - not implemented
- Sound cues on highlight - not implemented

❌ **Minigame Modal**
- Slide-in/out animation - not implemented
- Shadow element for focus - not implemented
- Full opening before input - delay exists but animation doesn't

❌ **Battle State as Source of Truth**
- Currently entities are source of truth
- Battle state is synced FROM entities, not TO entities
- Should be: Battle state → Entities (for restoration)

❌ **Animation System**
- No centralized animation manager
- Animation completion detection - placeholder
- Sprite animations - not implemented

❌ **VFX/Sound Implementation**
- VFX nodes are placeholders
- Sound loading not implemented
- Effect registry not fully utilized

## Next Development Points

### High Priority (Battle Refactor Goals)

1. **Visual Feedback System**
   - Implement turn highlighting (enemy glow, party border)
   - Implement selection arrow with animation
   - Implement party display animations (down/up)
   - Implement action menu slide-in animation
   - Implement attack animations (shake, flash)

2. **Enemy Turn Enhancements**
   - Implement enemy highlight animation (wiggle)
   - Add enemy action indication system
   - Implement wind-up messages (if needed)

3. **Animation System**
   - Create centralized animation manager (or use Godot's AnimationPlayer)
   - Implement animation completion detection
   - Replace placeholder animations with actual implementations

4. **Battle State Refactor**
   - Make BattleState the source of truth
   - Implement state restoration from BattleState
   - Sync entities FROM battle state, not TO battle state

5. **VFX/Sound Implementation**
   - Implement actual VFX nodes and effects
   - Implement sound loading and playback
   - Complete effect registry

### Medium Priority

6. **Item System**
   - Complete item action implementation
   - Item usage UI
   - Item effects application

7. **Revive System**
   - Implement revive logic (reusable)
   - Dead party member targeting for revives
   - Visual feedback for revive targeting

8. **Combat Log Enhancements**
   - Color-coded entries (partially implemented)
   - Better formatting
   - Scroll to most recent

9. **Victory/Defeat Screens**
   - Victory message animation
   - Rewards display
   - Defeat statistics display

### Low Priority (Polish)

10. **UI Polish**
    - Better turn order display animation
    - Floating damage numbers
    - Status effect icons
    - Better party/enemy display layouts

11. **Performance Optimization**
    - Optimize auto-save (if needed)
    - VFX pool optimization
    - Animation performance

## Refactor Opportunities

### 1. Battle State as Source of Truth

**Current Issue**: Entities (Character/EnemyData) are the source of truth, BattleState is synced from entities.

**Refactor Goal**: Make BattleState the authoritative source, sync entities from BattleState.

**Benefits**:
- Easier state restoration from auto-save
- Cleaner separation of concerns
- Better serialization support

**Implementation**:
- Create methods to sync entities FROM battle state
- Update battle state directly (not from entities)
- Use battle state for all state queries

### 2. Animation System Centralization

**Current Issue**: Animations are scattered, no completion detection, placeholders everywhere.

**Refactor Goal**: Centralized animation system with completion detection.

**Options**:
- Use Godot's AnimationPlayer nodes
- Create custom animation manager
- Use Tween nodes for simple animations

**Benefits**:
- Consistent animation timing
- Proper completion detection
- Easier to maintain

### 3. Action System Refactor

**Current Issue**: Action handling is mixed into combat system, no clear action abstraction.

**Refactor Goal**: Create action classes/objects that encapsulate action logic.

**Benefits**:
- Cleaner combat system
- Easier to add new action types
- Better support for wind-up messages

**Implementation**:
- Create `Action` base class
- Subclasses: `AttackAction`, `AbilityAction`, `ItemAction`
- Actions handle their own execution, logging, effects

### 4. Target Selection System Refactor

**Current Issue**: Target selection logic is mixed into combat system, no clear abstraction.

**Refactor Goal**: Create target selection system with visual feedback.

**Benefits**:
- Cleaner combat system
- Reusable target selection logic
- Better visual feedback

**Implementation**:
- Create `TargetSelection` class
- Handles highlighting, arrow animation, selection
- Returns selected target or null (canceled)

### 5. Minigame Context Type Safety

**Current Issue**: Minigame context is converted to Dictionary for backward compatibility with modal.

**Refactor Goal**: Use typed contexts throughout, remove Dictionary conversion.

**Benefits**:
- Type safety
- Better IDE support
- Clearer code

**Implementation**:
- Update `MinigameModal` to accept typed contexts
- Remove Dictionary conversion in `_build_minigame_context()`
- Update minigames to use typed contexts directly

### 6. Effect Application Refactor

**Current Issue**: Effect application uses match statement in combat system.

**Refactor Goal**: Use registry pattern or factory pattern for effects.

**Benefits**:
- Easier to add new effects
- No match statement needed
- Better extensibility

**Implementation**:
- Create `EffectRegistry` or `EffectFactory`
- Register effect types with instantiation logic
- Combat system calls registry/factory

### 7. Turn Order Display Refactor

**Current Issue**: Turn order display is created programmatically in combat system.

**Refactor Goal**: Create dedicated `TurnOrderDisplay` class.

**Benefits**:
- Cleaner combat system
- Better animation support
- Easier to maintain

**Implementation**:
- Create `TurnOrderDisplay` class
- Handles UI creation, updates, animations
- Combat system just calls update methods

## Code Quality Notes

### Strengths

✅ **SOLID Principles**: Good use of Open/Closed Principle (registry pattern), Single Responsibility (behavior classes), Dependency Inversion (behavior interface)

✅ **Type Safety**: Good use of typed classes, `class_name` declarations, type annotations

✅ **Separation of Concerns**: Clear separation between combat, minigames, behaviors, status effects

✅ **Extensibility**: Easy to add new classes, effects, minigames

### Areas for Improvement

⚠️ **Dictionary Usage**: Some places still use dictionaries where typed classes would be better (minigame context conversion, effect dictionaries)

⚠️ **Placeholder Code**: Many TODOs and placeholder implementations (animations, VFX, sound)

⚠️ **State Management**: Battle state not fully utilized as source of truth

⚠️ **Error Handling**: Some error cases not fully handled (e.g., failed minigame loads)

⚠️ **Code Duplication**: Some duplication in UI update methods, display creation

## Testing Considerations

### Current State
- No automated tests visible
- Manual testing required

### Recommended Testing Areas
1. **Turn Order System**: Test roll calculations, sorting, dead combatant removal
2. **Status Effect System**: Test stacking, matching, attribute modification
3. **Behavior System**: Test context building, attack effects, result formatting
4. **Battle State**: Test serialization, restoration
5. **Minigame Integration**: Test context passing, result application

## Conclusion

The project has a solid architectural foundation with good use of design patterns (registry, behavior, composition, polymorphism). The main gaps are in visual feedback, animations, and making BattleState the true source of truth. The battle refactor goals are well-aligned with the current architecture, requiring mostly implementation work rather than major refactoring.

The codebase follows SOLID principles and is extensible, making it relatively easy to add new classes, effects, and features. The main work needed is completing the visual/audio systems and refining the state management approach.

