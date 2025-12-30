# Battle System Refactor - Feature Context

## Overview

This document provides the context needed to refactor the current battle system to align with the new architectural direction described in `battle_refactor.md`. The refactor focuses on **establishing the foundation** rather than implementing every feature - creating a flexible, extensible base that enables incremental development toward the full vision.

## Current State

### Existing Combat System

**File**: `scripts/scenes/combat.gd`

The current combat system is functional but lacks the timing, visual feedback, and state management structure needed for the new vision. Key characteristics:

- **Turn Order System**: Uses `Array[TurnOrderEntry]` with dynamic recalculation after each action
  - Turn values calculated as `random(10-20) - speed`
  - Lower values go first
  - Dead combatants removed from turn order
  - Turn order display updates after each action

- **Action Handling**: Direct execution without delays or sequential coordination
  - Player attacks execute immediately after target selection
  - Enemy attacks execute with a simple `await get_tree().create_timer(0.5).timeout`
  - Minigames open/close without animation coordination
  - No input blocking during state transitions

- **Target Selection**: Basic mouse-based selection
  - `is_selecting_target` flag tracks selection state
  - Enemy displays highlight when selectable
  - No visual arrow or consistent highlighting system
  - Cancel via `ui_cancel` input action

- **Status Effects**: Fully implemented via `StatusEffectManager`
  - Processed at start of each turn via `_process_combatant_status_effects()`
  - Effects applied from minigame results
  - Death cleanup removes all effects

- **Minigame Integration**: Uses `MinigameRegistry` and behavior system
  - Behavior classes handle class-specific logic (no match statements)
  - Minigame modal opens/closes programmatically
  - Results applied generically via `_apply_minigame_result()`

- **UI Updates**: Direct updates without animation coordination
  - Party/enemy displays update immediately
  - Turn order display updates after recalculation
  - No highlighting system for active turns
  - No visual feedback for actions (damage numbers, VFX, etc.)

### Existing Data Structures

**TurnOrderEntry** (`scripts/data/turn_order_entry.gd`):
- Contains: `combatant` (Character or EnemyData), `turn_value` (int), `is_party` (bool), `display_name` (String)
- Used for turn order tracking and display

**Encounter** (`scripts/data/encounter.gd`):
- Contains: `enemy_composition`, `enemy_formation`, `rewards`, `encounter_type`
- Loaded via `EncounterManager.get_next_encounter()`

**RunState** (`scripts/data/run_state.gd`):
- Contains: `party`, `current_land`, `encounter_progress`, `inventory`, `currency`
- Managed by `GameManager.current_run`

### Existing Managers

- **GameManager**: Run state, persistent currency
- **SceneManager**: Scene transitions
- **EncounterManager**: Encounter selection and pools
- **MinigameRegistry**: Class-to-minigame mapping (behavior system)
- **SaveManager**: Auto-save functionality (exists but may need battle state integration)

## Refactor Goals

Based on the "Refactor Approach" section of `battle_refactor.md`, the refactor should focus on:

1. **Battle State Structure**: Create clean, serializable data structure as source of truth
2. **Core Managers**: Implement VFX manager, Sound manager, Delay system
3. **Turn Flow**: Refactor turn order and progression to support delays and sequential logic
4. **Action System**: Refactor action handling to be flexible and support new flow
5. **UI Integration**: Update UI systems to work with delays, highlighting, and new flow

## Architectural Direction

### Core Principles

1. **Battle State as Source of Truth**: Clean, straightforward data structure representing complete battle state
   - Turn order and current turn
   - All entity states (HP, status effects, positions)
   - Minigame-specific state (if any)
   - Easily serializable for auto-save
   - Accessible to all systems

2. **Delay-Based Timing System**: Configurable delay durations with sequential logic flow
   - Some delays stored as constants (e.g., `ACTION_MENU_BEAT_DURATION`)
   - Other delays depend on animation length
   - Sequential events: minigame must fully open before input, attack animations must finish before next turn
   - Overlapping events: sound effects can play while animations complete

3. **Input Blocking**: Input blocked/ignored during delays and animations
   - No skipping or acceleration needed
   - Animations designed to be snappy

4. **Flexible, Extensible Systems**: Design for easy modification without major refactoring
   - Silence system that can modify minigame behavior per class
   - Reusable revive logic (works for items and abilities)
   - Action system that can log messages (for wind-up messages)
   - VFX and sound systems that can be extended

### Key Systems to Implement

#### Battle State Manager

**Purpose**: Maintain complete battle state snapshot as source of truth

**Responsibilities**:
- Maintain battle state data structure (turn order, entity states, HP, status effects, minigame-specific state)
- Handle turn order calculation and updates
- Manage entity lifecycle (death, revival, removal from turn order)
- Provide serialization for auto-save (full snapshot after turn order determined)
- Serve as accessible source of truth for all systems

**Data Structure** (to be designed):
```gdscript
# Battle state class (to be implemented)
class_name BattleState
extends RefCounted

var turn_order: Array[TurnOrderEntry] = []
var current_turn_index: int = 0
var party_states: Array[CharacterBattleState] = []  # Character states with HP, status effects
var enemy_states: Array[EnemyBattleState] = []       # Enemy states with HP, status effects
var minigame_state: MinigameBattleState = null      # Class-specific minigame state if any
var encounter_id: String = ""
var turn_count: int = 0

# Supporting classes for entity states
class_name CharacterBattleState
extends RefCounted

var character_id: String = ""
var current_hp: int = 0
var max_hp: int = 0
var status_effects: Array[StatusEffect] = []
var position: Vector2 = Vector2.ZERO

class_name EnemyBattleState
extends RefCounted

var enemy_id: String = ""
var current_hp: int = 0
var max_hp: int = 0
var status_effects: Array[StatusEffect] = []
var position: Vector2 = Vector2.ZERO

class_name MinigameBattleState
extends RefCounted

var class_type: String = ""
var state_data: Variant = null  # Class-specific state data (type depends on class)
```

**Integration Points**:
- Combat system queries battle state for current turn, entity states
- Auto-save system serializes battle state after turn order determined
- UI systems read from battle state for display updates
- Action system updates battle state when actions complete

#### Delay/Timing System

**Purpose**: Coordinate sequential and overlapping events with configurable delays

**Responsibilities**:
- Provide configurable delay durations (constants like `ACTION_MENU_DELAY_DURATION`)
- Coordinate sequential events (wait for completion before next step)
- Support overlapping events (sound + animation simultaneously)
- Track animation completion for sequential logic
- Block input during delays

**Constants to Define**:
- `ACTION_MENU_BEAT_DURATION`: Delay for action menu slide-in
- `MINIGAME_OPEN_BEAT_DURATION`: Delay for minigame modal opening
- `MINIGAME_CLOSE_BEAT_DURATION`: Delay for minigame modal closing
- `TARGET_SELECTION_ARROW_DELAY`: Delay for selection arrow movement
- `TURN_HIGHLIGHT_DURATION`: Duration for turn highlighting
- `ENEMY_ACTION_ANIMATION_DURATION`: Duration for enemy action animation
- `ATTACK_ANIMATION_DURATION`: Duration for attack animations
- `DEATH_ANIMATION_DURATION`: Duration for death animations
- `VICTORY_MESSAGE_DELAY`: Delay before showing victory message
- `DEFEAT_MESSAGE_DELAY`: Delay before showing defeat message

**Implementation Approach**:
- Create `DelayManager` or utility functions for delays
- Use `await get_tree().create_timer(duration).timeout` for delays
- Track animation completion via signals or completion callbacks
- Input blocking via `set_process_input(false)` or input handling flags

#### VFX Manager (Centralized)

**Purpose**: Centralized visual effects system using registry pattern

**Architecture**:
- Registry pattern with `EffectIds` enum (similar to `MinigameRegistry`)
- Pool of ~10 deactivated VFX nodes
- Greedy reuse if pool exhausted (reuse longest-active node)
- Effects are world-space, don't attach to entities

**EffectIds Enum** (to be defined):
```gdscript
enum EffectIds {
    FIRE_DAMAGE,
    ICE_DAMAGE,
    PHYSICAL_SLASH,
    HEAL_EFFECT,
    BUFF_EFFECT,
    DEBUFF_EFFECT,
    DEATH_EFFECT,
    # ... more effects as needed
}
```

**Interface**:
```gdscript
# VFXManager interface (to be implemented)
func play_effect(effect_id: EffectIds, position: Vector2, config: VFXConfig = null) -> void

# VFX configuration class
class_name VFXConfig
extends RefCounted

var scale: float = 1.0
var color: Color = Color.WHITE
var duration: float = 1.0
var rotation: float = 0.0
# Additional config properties as needed
```

**Integration Points**:
- Combat system triggers VFX when damage/healing/effects occur
- Action system triggers VFX for attack animations
- Death handling triggers death VFX
- Minigame result application triggers effect VFX

#### Sound Manager

**Purpose**: Centralized sound system for BGM and SFX

**Architecture**:
- Single background track and single SFX track (for alpha)
- Simple interface: call manager to play sound or change music
- SFX/VFX sync handled by design, not code (triggered at same time)

**Interface** (to be implemented):
```gdscript
# SoundManager interface
func play_sfx(sound_id: String) -> void
func change_bgm(music_id: String) -> void
func set_sfx_volume(volume: float) -> void
func set_bgm_volume(volume: float) -> void
```

**Sound IDs** (to be defined):
- Action menu sounds (hover, select)
- Target selection sounds (highlight, select)
- Attack sounds (player attack, enemy attack)
- Minigame sounds (open, close, actions)
- Death sounds (enemy death, party death)
- Victory/defeat sounds
- Status effect sounds

**Integration Points**:
- Action menu plays sounds on hover/select
- Target selection plays sounds on highlight
- Actions trigger sound effects
- Minigames trigger sound effects
- Death/victory/defeat trigger sound effects

#### Action System

**Purpose**: Flexible action handling supporting Attack, Spell/Ability, and Item actions

**Current State**: Actions execute directly without coordination

**Refactored State**: Actions coordinate with delays, animations, and visual feedback

**Action Flow** (to be implemented):
1. **Action Selection**: Player selects action (Attack, Spell/Ability, Item)
   - Action menu slides in (delay)
   - Sound cue on hover/select
   - Input blocked during menu animation

2. **Target Selection** (if needed):
   - Party member displays animate down (delay)
   - Action menu closes (delay)
   - Target selection mode activates
   - Selection arrow appears and animates between targets
   - Sound cues on highlight/select
   - Cancel option (for attacks, not abilities)

3. **Action Execution**:
   - **Attack**: Party member display shakes, target flashes, animation plays, damage applies
   - **Spell/Ability**: Minigame opens (with delays), minigame plays, minigame closes, effects apply
   - **Item**: Item effect applies immediately (with visual feedback)

4. **Action Completion**:
   - Animations complete (sequential requirement)
   - Turn advances (after delays)

**Message Logging**: Actions can log messages to battle screen (for wind-up messages)
- Interface: `action.log_message(message: String) -> void`
- Enables future enemy action indication
- Messages stored in typed `CombatMessage` class rather than dictionaries

**Revive Logic**: Reusable revive logic system
- Works for both item-based and ability-based revives
- Consistent behavior regardless of revive source
- Extensible for future revive mechanics

#### Turn Order System

**Purpose**: Dynamic turn order with visual feedback and animation

**Current State**: Turn order calculated and displayed, but no highlighting or animation

**Refactored State**: Turn order with highlighting, animation, and visual feedback

**Turn Flow** (to be implemented):
1. **Turn Start**:
   - Current combatant highlighted (enemy: glow behind sprite, party: border around display)
   - Highlight persists for party turns, temporary for enemy turns
   - Turn order display updates (animated if order changed)
   - Status effects processed

2. **Enemy Turn**:
   - Enemy highlighted and lightly animates (wiggle) for a beat
   - Enemy action executes (attack, spell, item)
   - Action animation plays
   - Effects apply
   - Turn advances

3. **Party Turn**:
   - Party member highlighted (border)
   - Action menu slides in (delay)
   - Player selects action
   - Action executes (with delays and animations)
   - Turn advances

**Turn Order Updates**:
- Animated updates when order changes
- Dead party members removed (display reflows)
- Revived members rejoin (with speed calculation: current active entity speed + roll)

#### Minigame Integration

**Purpose**: Seamless minigame integration with proper timing and state management

**Current State**: Minigames open/close programmatically without animation coordination

**Refactored State**: Minigames coordinate with delays, animations, and state management

**Minigame Flow** (to be implemented):
1. **Minigame Opening**:
   - Party member displays animate down (if not already)
   - Action menu closes (delay)
   - Minigame modal slides in on top of combat UI (delay)
   - Combat background remains same
   - Shadow element may be added to pull focus
   - Minigame must fully open before player actions accepted (sequential requirement)

2. **Minigame Execution**:
   - Combat effectively paused (no interruptions)
   - Minigame plays with action-specific timing, sound, motion
   - If target selection needed mid-minigame:
     - Minigame closes (but maintains state)
     - Target selection occurs (no cancel option)
     - Minigame may re-open (unlikely) or state cleaned up

3. **Minigame Closing**:
   - Minigame animates closed (if still open) (delay)
   - Minigame effect occurs (visual effect, sound effect, animation)
   - After beat, battle progresses to next turn

**State Maintenance**: Minigame state preserved during target selection if needed

**Minigame Context**: Minigame contexts should use typed classes instead of dictionaries
- Create `MinigameContext` base class extending `RefCounted`
- Each class can have its own context subclass (e.g., `BerserkerMinigameContext`, `MonkMinigameContext`)
- Context classes provide type safety and clear structure
- Example structure:
```gdscript
class_name MinigameContext
extends RefCounted

var character: Character = null
var target: Variant = null

class_name BerserkerMinigameContext
extends MinigameContext

var effect_ranges: Array[EffectRange] = []
var is_berserking: bool = false
var berserk_stacks: int = 0

class_name MonkMinigameContext
extends MinigameContext

var target_strategy: int = 0
var enemy_cards: Array[RPSCard] = []
var enemy_id: String = ""
var redos_available: int = 0
```

**Silence Integration**: Class-specific silence interactions
- Berserker: Nullifies effect range mechanic
- Time Wizard: Changes all event symbols to null symbols
- Monk: Removes special effects from enemy options
- Wild Mage: Disallows discards
- System designed to be flexible for future changes

#### UI Systems

**Purpose**: Visual feedback, highlighting, and animation coordination

**Highlighting System** (to be implemented):
- **Enemies**: Glow effect behind sprite (slightly larger than sprite)
- **Party Members**: Border around display
- **Selection Arrow**: Animated arrow that moves between selections (slightly above enemies or party UI)
  - Arrow movement takes a beat (travel time)
  - Arrow disappears once selection made
  - Provides secondary visual feedback for target selection

**Party Member Displays**:
- Grey out on death (remain visible)
- Return to normal on revival
- Animate down during target selection
- Shake lightly during action execution

**Turn Order Display**:
- Updates dynamically as turns progress
- Removes dead members (reflows display)
- Highlights current turn with visual indicator
- Animates when order changes

**Action Menu**:
- Slides in to fixed location (delay)
- Sound cues on hover/select
- Closes during target selection (delay)
- Reopens if target selection canceled (delay)

**Target Selection**:
- Mouse-based selection (for alpha)
- Consistent highlight/arrow feedback
- Dead enemies vanish (not selectable)
- Dead party members greyed out (selectable for revives only)
- Invalid targets greyed out and unselectable

**Minigame Result Previews** (class-specific UI):
- **Berserker**: Active effect ranges displayed in horizontal list above party UI
  - Visible when Berserker's turn active
  - Brief display when new effect added
  - Shows brief descriptions, full details when minigame opens
- **Wild Mage**: Effects listed under hand types (icons may change)
- **Time Wizard**: Equipment-driven effects displayed
- **Monk**: Effects listed under each opponent's card
- **Tooltip System**: Consistent tooltip UI across all classes (brief descriptions, hover for details)

## Implementation Priorities

### Phase 1: Foundation (Initial Refactor)

1. **Battle State Structure**
   - Design and implement battle state data structure
   - Create `BattleStateManager` or integrate into combat system
   - Make battle state serializable for auto-save
   - Update combat system to use battle state as source of truth

2. **Delay/Timing System**
   - Create delay constants
   - Implement delay utility functions or `DelayManager`
   - Add input blocking during delays
   - Integrate delays into turn flow

3. **VFX Manager**
   - Create `EffectIds` enum
   - Implement VFX node pooling system
   - Create `VFXManager` with registry pattern
   - Integrate VFX triggers into combat system

4. **Sound Manager**
   - Create `SoundManager` with BGM and SFX tracks
   - Define sound IDs
   - Integrate sound triggers into combat system

### Phase 2: Turn Flow Refactoring

5. **Turn Flow Coordination**
   - Refactor `_process_current_turn()` to support delays
   - Add turn highlighting system
   - Coordinate sequential events (animations must complete before next step)
   - Update turn order display with animations

6. **Action System Refactoring**
   - Refactor action selection with delays and animations
   - Update target selection with arrow and highlighting
   - Coordinate action execution with delays and animations
   - Add message logging capability

### Phase 3: UI Integration

7. **UI Systems**
   - Implement highlighting system (enemies, party, arrow)
   - Update party/enemy displays for animations
   - Add action menu slide-in/out animations
   - Implement minigame result previews (class-specific)

8. **Minigame Integration**
   - Coordinate minigame opening/closing with delays
   - Maintain minigame state during target selection
   - Integrate silence system with minigames

## Integration Points

### Auto-Save System

**Current State**: `SaveManager` exists but may need battle state integration

**Refactored State**: Auto-save occurs just after turn order is determined
- Full snapshot of current battle state
- Includes turn order, entity states, HP, status effects, minigame-specific state
- Failed saves print debug error and continue (don't block turn progression)

**Integration**:
- Battle state structure must be serializable
- `SaveManager` or combat system triggers save after turn order determined
- Save includes complete battle state snapshot

### Status Effect System

**Current State**: Fully implemented via `StatusEffectManager`

**Refactored State**: Status effects work with new timing and visual feedback
- Status effects processed at start of turn (with delays)
- Visual feedback for status effect application (VFX, sound)
- Status effect UI updates with highlighting system
- Status effect tick results should use typed classes instead of dictionaries

**Integration**:
- Status effect processing already happens at turn start
- Add visual feedback (VFX, sound) when effects applied
- Status effect UI integrates with highlighting system
- **Future Refactor**: Convert `tick_status_effects()` return value from `Dictionary` to `StatusEffectTickResult` class
  - Create `StatusEffectTickResult` class with `damage: int`, `healing: int`, `should_remove: bool` properties
  - Convert `on_tick()` return value from `Dictionary` to `StatusEffectTickResult` class
  - Provides type safety and clearer structure

### Minigame System

**Current State**: Uses `MinigameRegistry` and behavior system

**Refactored State**: Minigames coordinate with delays, animations, and state management
- Minigame opening/closing with delays
- State maintenance during target selection
- Silence integration with class-specific interactions

**Integration**:
- Minigame modal system already exists
- Add delay coordination for opening/closing
- Maintain state during target selection
- Integrate silence system with behavior classes

## Data Flow

### Battle Start Flow

1. `initialize_combat()` called
2. Encounter loaded from `EncounterManager`
3. Party and enemies displayed
4. **NEW**: Encounter message displayed (delay)
5. **NEW**: Sound cue plays (overlaps with message)
6. Initiative rolled for all combatants
7. Turn order calculated and displayed
8. **NEW**: Auto-save triggered (after turn order determined)
9. First turn processed

### Turn Flow

1. **Turn Start**:
   - Current combatant highlighted (delay)
   - Status effects processed
   - Turn order display updated (if needed)

2. **Action Selection** (party turn):
   - Action menu slides in (delay)
   - Player selects action
   - Target selection (if needed) with delays and animations
   - Action executes with delays and animations

3. **Action Execution** (enemy turn):
   - Enemy highlights and animates (delay)
   - Enemy action executes
   - Action animation plays (sequential requirement)
   - Effects apply

4. **Turn End**:
   - Turn order updated
   - **NEW**: Auto-save triggered (after turn order determined)
   - Next turn processed

### Action Execution Flow

1. **Action Selected**:
   - Action menu closes (delay)
   - Party displays animate down (if needed) (delay)

2. **Target Selection** (if needed):
   - Target selection mode activates
   - Selection arrow appears
   - Player selects target (with sound cues and arrow animation)
   - Target selection completes

3. **Action Executes**:
   - **Attack**: Display shakes, target flashes, animation plays, damage applies
   - **Spell/Ability**: Minigame opens (delays), plays, closes (delays), effects apply
   - **Item**: Effect applies immediately (with visual feedback)

4. **Action Completes**:
   - Animations complete (sequential requirement)
   - Turn advances

## Key Design Decisions

### Battle State Location

**Decision**: Battle state should be a separate data structure managed by combat system or dedicated manager

**Rationale**: 
- Clean separation of state from UI/logic
- Easy serialization for auto-save
- Accessible to all systems as source of truth

### Delay System Implementation

**Decision**: Use `await get_tree().create_timer(duration).timeout` with constants for delays

**Rationale**:
- Simple and straightforward
- No need for complex timing system for alpha
- Constants make delays configurable

### VFX Pooling

**Decision**: Pool of ~10 VFX nodes with greedy reuse if pool exhausted

**Rationale**:
- Efficient resource management
- Prevents node creation/destruction overhead
- Greedy reuse acceptable for alpha (may need more sophisticated system later)

### Input Blocking

**Decision**: Block input during delays and animations via flags or `set_process_input(false)`

**Rationale**:
- Prevents player interaction during critical state transitions
- Ensures proper sequencing of combat logic
- Simple implementation for alpha

### Animation Completion Detection

**Decision**: Use signals or completion callbacks for animation completion detection

**Rationale**:
- Enables sequential logic (animations must finish before next step)
- Flexible for different animation types
- Standard Godot pattern

## Testing Considerations

### Battle State Serialization

- Test battle state serialization/deserialization
- Verify all state preserved (turn order, entity states, status effects)
- Test auto-save/load functionality

### Delay Coordination

- Test sequential events (minigame must open before input)
- Test overlapping events (sound + animation)
- Test input blocking during delays

### VFX System

- Test VFX node pooling (pool exhaustion, greedy reuse)
- Test VFX positioning and parameters
- Test VFX cleanup

### Turn Flow

- Test turn highlighting (enemies vs party)
- Test turn order updates (dead member removal, revival rejoin)
- Test action execution with delays

### Minigame Integration

- Test minigame opening/closing with delays
- Test state maintenance during target selection
- Test silence system with each class

## Future Considerations

### Not in Initial Refactor

- Wind-up messages (system designed to support, but not implemented)
- Animation system improvements (basic wiggling/flashing for alpha)
- Full animation system (sprite swapping, complex animations)
- Advanced VFX (complex particle effects, shader effects)
- Advanced sound system (multiple SFX tracks, dynamic music)
- Keyboard/arrow key target selection (mouse-only for alpha)
- Animation skipping (not needed - animations designed to be snappy)

### Extensibility Points

- Action system designed for message logging (wind-up messages)
- Silence system designed for easy modification
- Revive logic designed for reuse (items and abilities)
- VFX and sound systems designed for extension
- Battle state structure designed for easy addition of new state

## References

- **Battle Refactor Document**: `battle_refactor.md` - Full vision and Q&A
- **Game Design Document**: `gamedoc.md` - Complete game design and mechanics
- **Current Combat System**: `scripts/scenes/combat.gd` - Existing implementation
- **Status Effect System**: `scripts/data/status_effect_manager.gd` - Status effect implementation
- **Class Behavior System**: `scripts/class_behaviors/` - Class-specific logic
- **Minigame Registry**: `scripts/managers/minigame_registry.gd` - Minigame registration
