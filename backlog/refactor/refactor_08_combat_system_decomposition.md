# Combat System Decomposition

**Priority**: Refactor 08 (Code Organization - Depends on refactor_01, refactor_02, refactor_04)

## Description

Break down the monolithic `combat.gd` file (1451 lines) into focused, single-responsibility modules. Extract turn management, action handling, target selection, UI management, combat initialization, and state management into separate classes. This improves maintainability, testability, and makes the codebase more AI-friendly.

**Design Philosophy**: The combat system has grown too large and handles too many responsibilities. Following the Single Responsibility Principle, each module should have one clear purpose. This makes the code easier to understand, test, and modify. Smaller, focused files are also easier for AI to work with.

## Context from Architecture Documents

### From architecture_review_notes.md:
> "Once these refactors are done, we will look at at combat.gd again to see if we can break any functionality out of here for better organization. Specifically I'm thinking the end-of-combat logic, run management, scene setting, turn management, saving, blocking and unblocking input, highlighting, input handling, turn order ui, minigame initialization, - I could go on. It's a lot of things for one file to do."

### From ARCHITECTURE_PRIMER.md:
- `combat.gd` is 1451 lines
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

**Recommended Dependencies**:
- Other refactors should be complete to avoid rework

## Current State

### Current Architecture

1. **combat.gd** (1451 lines) handles:
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

var turn_order: Array[TurnOrderEntry] = []
var current_turn_index: int = 0

func calculate_initial_turn_order(party: Array[Character], enemies: Array[EnemyData]) -> void
func advance_turn() -> void
func get_current_turn_combatant() -> BattleEntity
func remove_combatant_from_turn_order(entity_id: String) -> void
```

**ActionHandler**:
```gdscript
class_name ActionHandler
extends RefCounted

func execute_attack(attacker: BattleEntity, target: BattleEntity) -> void
func execute_ability(character: Character, target: BattleEntity) -> void
func execute_item(character: Character, item: Item, target: BattleEntity) -> void
```

**TargetSelector**:
```gdscript
class_name TargetSelector
extends RefCounted

signal target_selected(target: BattleEntity)
signal selection_canceled

func start_target_selection(attacker: BattleEntity, target_type: TargetType) -> void
func cancel_target_selection() -> void
func is_selecting() -> bool
```

## Implementation Plan

### Phase 1: Extract TurnManager

1. **Create `scripts/combat/turn_manager.gd`**:
   - Move turn order calculation logic
   - Move turn advancement logic
   - Move current turn tracking
   - Move dead combatant removal
   - Keep interface simple and focused

2. **Update `scripts/scenes/combat.gd`**:
   - Create `TurnManager` instance
   - Delegate turn order operations to manager
   - Update references to use manager

### Phase 2: Extract ActionHandler

1. **Create `scripts/combat/action_handler.gd`**:
   - Move attack execution logic
   - Move ability execution logic (minigame integration)
   - Move item execution logic
   - Handle action results

2. **Update `scripts/scenes/combat.gd`**:
   - Create `ActionHandler` instance
   - Delegate action execution to handler
   - Update action button handlers

### Phase 3: Extract TargetSelector

1. **Create `scripts/combat/target_selector.gd`**:
   - Move target selection state
   - Move target selection UI logic
   - Move target validation
   - Emit signals for selection/cancel

2. **Update `scripts/scenes/combat.gd`**:
   - Create `TargetSelector` instance
   - Connect to selector signals
   - Delegate target selection to selector

### Phase 4: Extract CombatUI

1. **Create `scripts/combat/combat_ui.gd`**:
   - Move party display update logic
   - Move enemy display update logic
   - Move turn order display logic
   - Move action menu management
   - Move highlighting logic

2. **Update `scripts/scenes/combat.gd`**:
   - Create `CombatUI` instance
   - Delegate UI updates to UI manager
   - Pass UI node references to manager

### Phase 5: Extract CombatInitializer

1. **Create `scripts/combat/combat_initializer.gd`**:
   - Move encounter loading
   - Move battle state initialization
   - Move display setup
   - Move encounter message display

2. **Update `scripts/scenes/combat.gd`**:
   - Create `CombatInitializer` instance
   - Delegate initialization to initializer
   - Simplify `initialize_combat()`

### Phase 6: Extract CombatState

1. **Create `scripts/combat/combat_state.gd`**:
   - Move victory condition checking
   - Move defeat condition checking
   - Move end-of-combat logic
   - Move rewards handling

2. **Update `scripts/scenes/combat.gd`**:
   - Create `CombatState` instance
   - Delegate state checks to state manager
   - Handle state transitions

### Phase 7: Refactor Combat.gd

1. **Simplify `scripts/scenes/combat.gd`**:
   - Keep only orchestration logic
   - Coordinate between modules
   - Handle scene-level concerns
   - Keep input handling (or extract to InputManager)

2. **Update Module Integration**:
   - Ensure modules communicate correctly
   - Use signals for module communication
   - Keep combat.gd as coordinator

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

## Status

Pending (Depends on refactor_01, refactor_02, refactor_04)

