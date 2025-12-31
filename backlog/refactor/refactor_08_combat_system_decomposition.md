# Combat System Decomposition

**Priority**: Refactor 08 (Code Organization - Depends on refactor_01, refactor_02, refactor_04)

## Description

Break down the monolithic `combat.gd` file (1315 lines) into focused, single-responsibility modules. Extract turn management, action handling, target selection, UI management, combat initialization, and state management into separate classes. This improves maintainability, testability, and makes the codebase more AI-friendly.

**Note**: After refactor_07, BattleState is now the source of truth for combat state. Entities are stored directly in BattleState (CharacterBattleEntity/EnemyBattleEntity), not as snapshots. Entities are modified directly after accessing through BattleState - no wrapper methods needed.

**Design Philosophy**: The combat system has grown too large and handles too many responsibilities. Following the Single Responsibility Principle, each module should have one clear purpose. This makes the code easier to understand, test, and modify. Smaller, focused files are also easier for AI to work with.

## Context from Architecture Documents

### From architecture_review_notes.md:
> "Once these refactors are done, we will look at at combat.gd again to see if we can break any functionality out of here for better organization. Specifically I'm thinking the end-of-combat logic, run management, scene setting, turn management, saving, blocking and unblocking input, highlighting, input handling, turn order ui, minigame initialization, - I could go on. It's a lot of things for one file to do."

### From ARCHITECTURE_PRIMER.md:
- `combat.gd` is 1315 lines
- Handles: turn order, actions, target selection, minigame integration, status effects, death handling, UI updates, input handling, animations, state management
- Too many responsibilities in one file
- Difficult to navigate and maintain

### From gamedoc.md:
- Combat system orchestrates many subsystems
- Clear separation of concerns would improve maintainability
- Each subsystem has distinct responsibilities

## Dependencies

**Critical Dependencies**:
- **refactor_01_battle_entity_base_class.md** - BattleEntity simplifies entity handling
- **refactor_02_status_effect_system_refactor.md** - Status effects should be stable
- **refactor_04_minigame_result_type_safety.md** - Minigame results should be stable
- **refactor_07_battle_state_source_of_truth.md** - BattleState is now the source of truth for combat state

**Recommended Dependencies**:
- Other refactors should be complete to avoid rework

## Current State

### Current Architecture

1. **combat.gd** (1315 lines) handles:
   - Combat initialization and setup
   - Turn order calculation and management
   - Turn processing (party and enemy turns)
   - Action handling (Attack, Ability, Item)
   - Target selection logic and UI
   - Minigame modal lifecycle
   - Status effect processing
   - Death handling (party and enemies)
   - UI updates (party displays, enemy displays, turn order)
   - Input handling and blocking
   - Victory/defeat conditions
   - Combat log integration
   - Battle state management
   - Auto-save integration
   - Scene transitions

2. **BattleState Architecture** (after refactor_07):
   - BattleState stores entities directly (CharacterBattleEntity/EnemyBattleEntity), not as snapshots
   - Entities are modified directly after accessing through `battle_state.party_states` or `battle_state.enemy_states`
   - No wrapper methods needed (e.g., `battle_state.party_states[0].take_damage(10)`)
   - BattleState is the exclusive access point for all entities during combat
   - Turn order is stored in `battle_state.turn_order` and managed directly

2. **Problems**:
   - Too many responsibilities
   - Difficult to find specific functionality
   - Hard to test individual components
   - Changes in one area risk breaking others
   - AI struggles with large files

### Identified Modules

Based on analysis, these modules should be extracted:

1. **TurnManager** - Turn order, turn processing
2. **ActionHandler** - Action execution (Attack, Ability, Item)
3. **TargetSelector** - Target selection logic and UI
4. **CombatUI** - UI updates, displays, animations
5. **CombatInitializer** - Encounter setup, initialization
6. **CombatState** - State management, victory/defeat
7. **InputManager** - Input handling, blocking (optional, may stay in combat)

## Requirements

### Core Functionality

1. **TurnManager** (`scripts/combat/turn_manager.gd`):
   - Turn order calculation
   - Turn order updates
   - Current turn tracking
   - Turn advancement logic
   - Dead combatant removal from turn order

2. **ActionHandler** (`scripts/combat/action_handler.gd`):
   - Attack action execution
   - Ability action execution (minigame integration)
   - Item action execution
   - Action result processing

3. **TargetSelector** (`scripts/combat/target_selector.gd`):
   - Target selection state management
   - Target selection UI (highlighting, arrow)
   - Target validation
   - Target selection completion

4. **CombatUI** (`scripts/combat/combat_ui.gd`):
   - Party display updates
   - Enemy display updates
   - Turn order display updates
   - Action menu management
   - Highlighting and visual feedback

5. **CombatInitializer** (`scripts/combat/combat_initializer.gd`):
   - Encounter loading
   - Battle state initialization
   - Party/enemy display setup
   - Encounter message display

6. **CombatState** (`scripts/combat/combat_state.gd`):
   - Victory condition checking
   - Defeat condition checking
   - End-of-combat logic
   - Rewards handling
   - Scene transitions

### Interface Requirements

**TurnManager**:
```gdscript
class_name TurnManager
extends RefCounted

var battle_state: BattleState

func _init(p_battle_state: BattleState):
    battle_state = p_battle_state

func calculate_initial_turn_order() -> void
func advance_turn() -> void
func get_current_turn_combatant() -> BattleEntity
func remove_dead_combatants() -> void
```

**Note**: TurnManager works directly with `battle_state.turn_order` - no local copy maintained. All turn order operations modify `battle_state.turn_order` directly.

**ActionHandler**:
```gdscript
class_name ActionHandler
extends RefCounted

var battle_state: BattleState

func _init(p_battle_state: BattleState):
    battle_state = p_battle_state

func execute_attack(attacker: BattleEntity, target: BattleEntity) -> void
func execute_ability(character: CharacterBattleEntity, target: BattleEntity) -> void
func execute_item(character: CharacterBattleEntity, item: Item, target: BattleEntity) -> void
```

**Note**: ActionHandler receives BattleState in constructor. Entities are accessed through BattleState and modified directly (e.g., `target.take_damage(amount)` after accessing through `battle_state.party_states` or `battle_state.enemy_states`).

**TargetSelector**:
```gdscript
class_name TargetSelector
extends RefCounted

var battle_state: BattleState
var party_container: HBoxContainer
var enemy_container: Control

signal target_selected(target: BattleEntity)
signal selection_canceled

func _init(p_battle_state: BattleState, p_party_container: HBoxContainer, p_enemy_container: Control):
    battle_state = p_battle_state
    party_container = p_party_container
    enemy_container = p_enemy_container

func start_target_selection(attacker: BattleEntity, target_type: TargetType) -> void
func cancel_target_selection() -> void
func is_selecting() -> bool
```

**CombatUI**:
```gdscript
class_name CombatUI
extends RefCounted

var battle_state: BattleState
var party_container: HBoxContainer
var enemy_container: Control
var turn_order_container: HBoxContainer

func _init(p_battle_state: BattleState, p_party_container: HBoxContainer, p_enemy_container: Control, p_turn_order_container: HBoxContainer):
    battle_state = p_battle_state
    party_container = p_party_container
    enemy_container = p_enemy_container
    turn_order_container = p_turn_order_container

func update_party_displays() -> void
func update_enemy_displays() -> void
func update_turn_order_display() -> void
func highlight_party_member(character: CharacterBattleEntity, highlight: bool) -> void
func highlight_enemy(enemy: EnemyBattleEntity, highlight: bool) -> void
```

**CombatInitializer**:
```gdscript
class_name CombatInitializer
extends RefCounted

func initialize_combat(encounter: Encounter, party: Array[CharacterBattleEntity]) -> BattleState
func setup_displays(combat_ui: CombatUI) -> void
func show_encounter_message(encounter: Encounter) -> void
```

**CombatState**:
```gdscript
class_name CombatState
extends RefCounted

var battle_state: BattleState

func _init(p_battle_state: BattleState):
    battle_state = p_battle_state

func check_victory() -> bool
func check_defeat() -> bool
func complete_encounter() -> void
func handle_party_wipe() -> void
```

## Implementation Plan

### Phase 1: Extract TurnManager + CombatUI

**Rationale**: These modules are relatively independent and have high impact on code organization. TurnManager handles core combat flow, while CombatUI handles all display updates.

1. **Create `scripts/combat/turn_manager.gd`**:
   - Receive `battle_state: BattleState` in constructor
   - Work directly with `battle_state.turn_order` (no local copy)
   - Move turn order calculation logic
   - Move turn advancement logic
   - Move current turn tracking (via `battle_state.current_turn_index`)
   - Move dead combatant removal
   - Keep interface simple and focused

2. **Create `scripts/combat/combat_ui.gd`**:
   - Receive UI node references and BattleState in constructor
   - Move party display update logic
   - Move enemy display update logic
   - Move turn order display logic
   - Move action menu management
   - Move highlighting logic

3. **Update `scripts/scenes/combat.gd`**:
   - Create `TurnManager` instance with `battle_state`
   - Create `CombatUI` instance with UI nodes and `battle_state`
   - Delegate turn order operations to TurnManager
   - Delegate UI updates to CombatUI
   - Update references to use managers

4. **Testing**:
   - Verify turn order management works correctly
   - Verify UI updates reflect state changes
   - Verify BattleState remains source of truth

### Phase 2: Extract ActionHandler + TargetSelector

**Rationale**: These modules work closely together - ActionHandler needs target selection for attacks and abilities.

1. **Create `scripts/combat/action_handler.gd`**:
   - Receive `battle_state: BattleState` in constructor
   - Move attack execution logic
   - Move ability execution logic (minigame integration)
   - Move item execution logic
   - Handle action results
   - Access entities through BattleState and modify directly

2. **Create `scripts/combat/target_selector.gd`**:
   - Receive UI node references and BattleState in constructor
   - Move target selection state
   - Move target selection UI logic
   - Move target validation
   - Emit signals for selection/cancel

3. **Update `scripts/scenes/combat.gd`**:
   - Create `ActionHandler` instance with `battle_state`
   - Create `TargetSelector` instance with UI nodes and `battle_state`
   - Connect TargetSelector signals to ActionHandler
   - Delegate action execution to ActionHandler
   - Delegate target selection to TargetSelector
   - Update action button handlers

4. **Testing**:
   - Verify attack actions work correctly
   - Verify ability actions work correctly
   - Verify target selection integrates with actions
   - Verify entities are accessed through BattleState

### Phase 3: Extract CombatInitializer + CombatState

**Rationale**: These modules handle combat lifecycle - initialization and completion.

1. **Create `scripts/combat/combat_initializer.gd`**:
   - Receive encounter data and party data
   - Move encounter loading
   - Move battle state initialization
   - Move display setup (delegates to CombatUI)
   - Move encounter message display

2. **Create `scripts/combat/combat_state.gd`**:
   - Receive `battle_state: BattleState` in constructor
   - Move victory condition checking
   - Move defeat condition checking
   - Move end-of-combat logic
   - Move rewards handling
   - Handle scene transitions (via signals or callbacks)

3. **Update `scripts/scenes/combat.gd`**:
   - Create `CombatInitializer` instance
   - Create `CombatState` instance with `battle_state`
   - Delegate initialization to CombatInitializer
   - Delegate state checks to CombatState
   - Simplify `initialize_combat()`
   - Handle state transitions

4. **Testing**:
   - Verify combat initializes correctly
   - Verify victory conditions are detected
   - Verify defeat conditions are detected
   - Verify rewards are applied correctly

### Final Phase: Refactor Combat.gd to Orchestrator

1. **Simplify `scripts/scenes/combat.gd`**:
   - **Keep scene management responsibilities**:
     - Scene node references (@onready vars for UI elements)
     - Signal connections (button presses, UI events)
     - Module instantiation and wiring
     - Scene-level orchestration (coordinating modules)
     - Input handling (scene-level input blocking/unblocking)
     - Scene transitions (to land screen, main menu)
   - **Delegate to modules**:
     - Turn order management → TurnManager
     - Action execution → ActionHandler
     - Target selection → TargetSelector
     - UI updates → CombatUI
     - Combat initialization → CombatInitializer
     - Victory/defeat logic → CombatState

2. **Update Module Integration**:
   - Ensure modules communicate correctly
   - Use signals for module communication
   - Keep combat.gd as scene-level coordinator
   - Verify all scene-level concerns are handled

3. **Testing**:
   - Verify all combat functionality still works
   - Verify modules communicate correctly
   - Verify scene transitions work
   - Verify input blocking/unblocking works

## Related Files

### New Files to Create
- `scripts/combat/turn_manager.gd` - Turn order management
- `scripts/combat/action_handler.gd` - Action execution
- `scripts/combat/target_selector.gd` - Target selection
- `scripts/combat/combat_ui.gd` - UI management
- `scripts/combat/combat_initializer.gd` - Combat initialization
- `scripts/combat/combat_state.gd` - State management

### Core Files to Modify
- `scripts/scenes/combat.gd` - Major refactor, becomes orchestrator

### Supporting Files (may need updates)
- `scripts/data/battle_state.gd` - May need updates for module access
- `scripts/ui/character_display.gd` - May need updates for UI manager
- `scripts/ui/enemy_display.gd` - May need updates for UI manager

## Testing Considerations

1. **Module Isolation**: Verify each module works independently
2. **Integration**: Verify modules work together correctly
3. **Functionality**: Verify all combat functionality still works
4. **Performance**: Verify decomposition doesn't cause performance issues
5. **Signals**: Verify module communication via signals works

## Migration Notes

### Breaking Changes
- Combat system structure changes significantly
- Some methods move to different classes
- Module interfaces need to be stable

### Backward Compatibility
- Not needed - this is a refactor
- All combat functionality must be preserved
- Gradual migration possible (extract one module at a time)

### Module Communication

Modules should communicate via:
- **Signals**: For events (target selected, turn advanced, etc.)
- **Method Calls**: For direct operations (execute action, update UI)
- **Shared State**: BattleState for shared data

### BattleState Integration Pattern

After refactor_07, BattleState is the source of truth for all combat state. Modules must access entities through BattleState:

**Entity Access Pattern**:
```gdscript
# Access entities through BattleState
var character: CharacterBattleEntity = battle_state.party_states[0]
var enemy: EnemyBattleEntity = battle_state.enemy_states[0]

# Modify entities directly (no wrapper methods needed)
character.take_damage(10)
enemy.add_status_effect(effect)
```

**Turn Order Management**:
- TurnManager works directly with `battle_state.turn_order`
- No local copy of turn order is maintained
- All turn order operations modify `battle_state.turn_order` directly
- Current turn index is tracked via `battle_state.current_turn_index`

**Key Principles**:
- BattleState is the exclusive access point for all entities during combat
- Entities are stored directly in BattleState (not as snapshots)
- Entities are modified directly after accessing through BattleState
- No sync methods needed - entities in BattleState are the source of truth
- Modules receive BattleState in constructor for entity access

## Alternative Approaches

### Option A: Full Decomposition
- Extract all modules as described
- Combat.gd becomes thin orchestrator
- Most maintainable but most work

### Option B: Partial Decomposition
- Extract only largest/most independent modules
- Keep some logic in combat.gd
- Less work but less benefit

### Option C: Keep Current (Not Recommended)
- Leave combat.gd as monolithic file
- Easier short-term but harder long-term

## Combat.gd Role and Responsibilities

**Combat.gd is the root script for combat.tscn** and retains scene management and wiring responsibilities:

### Scene Management
- **Node References**: Manages @onready node references (party_container, enemy_container, buttons, turn_order_container, etc.)
- **Signal Connections**: Handles signal connections from UI elements (button presses, enemy clicks, etc.)
- **Scene Lifecycle**: Manages scene lifecycle methods (_ready, _input, etc.)

### Module Orchestration
- **Module Instantiation**: Creates module instances with required dependencies (BattleState, UI node references)
- **Module Wiring**: Connects module signals to combat.gd handlers
- **Operation Delegation**: Delegates operations to appropriate modules:
  - Turn order management → TurnManager
  - Action execution → ActionHandler
  - Target selection → TargetSelector
  - UI updates → CombatUI
  - Combat initialization → CombatInitializer
  - Victory/defeat logic → CombatState
- **High-Level Flow**: Maintains high-level combat flow and coordinates between modules

### Scene-Level Concerns
- **Input Handling**: Manages scene-level input blocking/unblocking (is_input_blocked flag)
- **Scene Transitions**: Handles scene transitions via SceneManager (to land screen, main menu)
- **Auto-Save Coordination**: Coordinates auto-save calls to SaveManager
- **Combat Log Integration**: Passes combat log reference to modules that need it

### What Combat.gd Does NOT Do
- Turn order calculation (delegated to TurnManager)
- Action execution logic (delegated to ActionHandler)
- Target selection UI (delegated to TargetSelector)
- Display updates (delegated to CombatUI)
- Combat initialization logic (delegated to CombatInitializer)
- Victory/defeat checking (delegated to CombatState)

**Design Philosophy**: Combat.gd is a thin orchestrator that wires modules together and handles scene-specific concerns. All combat logic is delegated to focused, single-responsibility modules.

## Status

Pending (Depends on refactor_01, refactor_02, refactor_04, refactor_07)

