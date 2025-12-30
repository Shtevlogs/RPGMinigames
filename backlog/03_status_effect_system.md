# Status Effect System

**Priority**: 03 (Chunk 2: Combat & Minigames)

## Description
Implement complete status effect application and processing system. Currently placeholder in combat system. Status effects are temporary conditions that modify combat behavior, applied by abilities, items, equipment, or enemy actions.

**Design Philosophy**: The status effect system uses an extensible base class architecture. All status effects extend a base `StatusEffect` class, allowing new status effects to be added easily without modifying existing code. This follows the Open/Closed Principle - open for extension, closed for modification.

## Current State

### Existing Infrastructure
- **StatusEffect Class** (`scripts/data/status_effect.gd`): Basic status effect data structure with:
  - `EffectType` enum (BURN, SILENCE, TAUNT) - **TO BE REPLACED** with class-based architecture
  - `duration` (turns remaining)
  - `stacks` (for stackable effects)
  - `magnitude` (for scaling effects like burn damage)
  - `tick()` method (decrements duration, returns true if should be removed)
  - `duplicate()` method (for copying)
  
  **Note**: This class should be refactored into a base class that can be extended. The enum-based approach should be replaced with a class-based polymorphic system.

- **Character Class** (`scripts/data/character.gd`): Has status effect support:
  - `status_effects: Array[StatusEffect]` property
  - `add_status_effect(effect: StatusEffect)` method (handles stacking logic - **TO BE REFACTORED** to use effect's own stacking logic)
  - `tick_status_effects()` method (processes all effects, removes expired)
  - `has_status_effect(effect_type: StatusEffect.EffectType)` method - **TO BE REFACTORED** to use class type checking

- **EnemyData Class** (`scripts/data/enemy_data.gd`): **DOES NOT** currently have status effect support - needs to be added

- **Combat System** (`scripts/scenes/combat.gd`): Has placeholder implementation:
  - `_apply_effect(effect_dict: Dictionary, source: Character)` method (line 743) - currently just logs, needs full implementation
  - `_select_enemy_target()` method (line 893) - already checks for TAUNT status effect
  - Status effects are NOT processed each turn (no call to `tick_status_effects()`)

- **MinigameResult** (`scripts/data/minigame_result.gd`): Has `effects: Array[Dictionary]` that can contain status effect data

### Missing Implementation
1. **Base StatusEffect class architecture** - Refactor to extensible base class pattern
2. Status effect processing at start of each turn (damage, duration decrement)
3. Full effect application logic in `_apply_effect()` method
4. Enemy status effect support (add to EnemyData)
5. Visual indicators for active status effects
6. Status effect removal on death
7. Status effect application from items and equipment
8. Status effect interactions with combat mechanics (Silence preventing abilities, etc.)

## Requirements

### Core Functionality
- **Extensible Architecture**: Base `StatusEffect` class that can be extended for new status effects
- Apply status effects from abilities (via MinigameResult), items, equipment, and enemy actions
- Process status effects at the start of each combatant's turn:
  - Decrement duration
  - Apply turn-based effects (e.g., Burn damage)
  - Remove expired effects
- Handle status effect stacking (each effect defines its own stacking behavior)
- Remove all status effects when a combatant dies
- Visual indicators showing active status effects on characters and enemies

### Extensibility Requirements
- New status effects can be added by creating a new class extending `StatusEffect`
- No modifications to existing code required when adding new status effects
- Each status effect class defines its own:
  - Stacking behavior (can stack, refreshes duration, etc.)
  - Turn processing logic (damage, debuffs, etc.)
  - Visual representation (icon, color, etc.)
  - Application rules (who can apply, when it can be applied, etc.)

### Status Effect Architecture

#### Base StatusEffect Class
**File**: `scripts/data/status_effect.gd`

The base class defines the interface that all status effects must implement:

```gdscript
class_name StatusEffect
extends RefCounted

var duration: int = 0  # turns remaining
var stacks: int = 1
var magnitude: float = 1.0  # For scaling effects

# Virtual methods to be overridden by subclasses
func get_effect_name() -> String:
    # Return display name of effect
    pass

func can_stack() -> bool:
    # Return true if this effect can stack with itself
    pass

func on_apply(existing_effect: StatusEffect) -> void:
    # Called when effect is applied to a target that already has this effect
    # Default: refresh duration if can't stack, add stacks if can stack
    pass

func on_tick(combatant: Variant) -> Dictionary:
    # Called at start of each turn
    # Returns Dictionary with effects to apply (damage, etc.)
    # Return {"remove": true} to remove effect after processing
    pass

func tick() -> bool:
    # Decrements duration, returns true if should be removed
    duration -= 1
    return duration <= 0

func get_visual_data() -> Dictionary:
    # Return visual representation data (icon path, color, etc.)
    pass

func duplicate() -> StatusEffect:
    # Create a copy of this effect
    pass
```

#### Status Effect Subclasses

Each status effect is a separate class extending `StatusEffect`:

**File**: `scripts/data/status_effects/burn_effect.gd`
```gdscript
class_name BurnEffect
extends StatusEffect

func _init(p_duration: int = 3, p_stacks: int = 1, p_magnitude: float = 1.0):
    duration = p_duration
    stacks = p_stacks
    magnitude = p_magnitude

func get_effect_name() -> String:
    return "Burn"

func can_stack() -> bool:
    return true

func on_apply(existing_effect: StatusEffect) -> void:
    if existing_effect is BurnEffect:
        existing_effect.stacks += stacks
        existing_effect.duration = max(existing_effect.duration, duration)

func on_tick(combatant: Variant) -> Dictionary:
    var damage: int = int(magnitude * stacks)
    return {"damage": damage}

func get_visual_data() -> Dictionary:
    return {
        "icon": "res://icons/burn.png",
        "color": Color.ORANGE,
        "show_stacks": true
    }
```

**File**: `scripts/data/status_effects/silence_effect.gd`
```gdscript
class_name SilenceEffect
extends StatusEffect

func _init(p_duration: int = 2):
    duration = p_duration
    stacks = 1
    magnitude = 1.0

func get_effect_name() -> String:
    return "Silence"

func can_stack() -> bool:
    return false

func on_apply(existing_effect: StatusEffect) -> void:
    if existing_effect is SilenceEffect:
        existing_effect.duration = max(existing_effect.duration, duration)

func on_tick(combatant: Variant) -> Dictionary:
    return {}  # No turn-based effects

func get_visual_data() -> Dictionary:
    return {
        "icon": "res://icons/silence.png",
        "color": Color.GRAY,
        "show_stacks": false
    }
```

**File**: `scripts/data/status_effects/taunt_effect.gd`
```gdscript
class_name TauntEffect
extends StatusEffect

func _init(p_duration: int = 2):
    duration = p_duration
    stacks = 1
    magnitude = 1.0

func get_effect_name() -> String:
    return "Taunt"

func can_stack() -> bool:
    return false

func on_apply(existing_effect: StatusEffect) -> void:
    if existing_effect is TauntEffect:
        existing_effect.duration = max(existing_effect.duration, duration)

func on_tick(combatant: Variant) -> Dictionary:
    return {}  # No turn-based effects

func get_visual_data() -> Dictionary:
    return {
        "icon": "res://icons/taunt.png",
        "color": Color.YELLOW,
        "show_stacks": false
    }
```

### Status Effect Types (Initial Implementation)

#### Burn
- **Class**: `BurnEffect`
- **Behavior**: Deals damage over time at the start of each turn
- **Stacking**: Yes - stacks additively (each stack deals damage)
- **Duration**: Number of turns the burn persists
- **Magnitude**: Damage per stack per turn
- **Application Sources**:
  - Wild Mage's Flame Sword equipment (red flushes have chance to apply burn)
- **Processing**: At start of turn, deal `magnitude * stacks` damage, then tick duration
- **Removal**: Expires after duration, removed on death

#### Silence
- **Class**: `SilenceEffect`
- **Behavior**: Prevents the affected character from using abilities (Spell/Ability action)
- **Stacking**: No - refreshes duration if already present
- **Duration**: Number of turns the silence persists
- **Magnitude**: Not used (binary effect)
- **Application Sources**:
  - Monk's minigame (e.g., Necromancer's Paper card on tie)
- **Processing**: Check before allowing ability action, tick duration at start of turn
- **Removal**: Expires after duration, removed on death
- **Combat Interaction**: When player tries to use ability, check `has_status_effect(SilenceEffect)` and block if present

#### Taunt
- **Class**: `TauntEffect`
- **Behavior**: Forces enemies to target the affected character
- **Stacking**: No - refreshes duration if already present
- **Duration**: Number of turns the taunt persists
- **Magnitude**: Not used (binary effect)
- **Application Sources**:
  - Berserker's effect ranges (standing on 18-20)
  - Monk's Duelist Gauntlets equipment (ties apply taunt)
- **Processing**: Tick duration at start of turn
- **Removal**: Expires after duration, removed on death
- **Combat Interaction**: Already implemented in `_select_enemy_target()` - prioritizes taunted characters (needs update to check for TauntEffect class)

## Implementation Details

### 1. Base StatusEffect Class Refactoring

**File**: `scripts/data/status_effect.gd`

Refactor the existing StatusEffect class into a base class:
- Remove `EffectType` enum (replaced with class-based polymorphism)
- Add virtual methods that subclasses must override:
  - `get_effect_name() -> String`
  - `can_stack() -> bool`
  - `on_apply(existing_effect: StatusEffect) -> void`
  - `on_tick(combatant: Variant) -> Dictionary`
  - `get_visual_data() -> Dictionary`
- Keep base properties: `duration`, `stacks`, `magnitude`
- Keep base `tick()` method (decrements duration)
- Update `duplicate()` to be virtual (subclasses override for proper copying)

### 2. Create Status Effect Subclasses

**Directory**: `scripts/data/status_effects/`

Create individual status effect classes:
- `burn_effect.gd` - Extends StatusEffect, implements burn behavior
- `silence_effect.gd` - Extends StatusEffect, implements silence behavior
- `taunt_effect.gd` - Extends StatusEffect, implements taunt behavior

Each subclass:
- Implements all virtual methods from base class
- Defines its own stacking logic in `on_apply()`
- Defines its own turn processing in `on_tick()`
- Defines its own visual representation in `get_visual_data()`

### 3. Update Character Class for Extensibility

**File**: `scripts/data/character.gd`

Refactor status effect methods to work with class-based system:
- `add_status_effect(effect: StatusEffect)`:
  - Check if target already has an effect of the same class type
  - If found, call `effect.on_apply(existing_effect)` instead of hardcoded stacking logic
  - If not found, add the effect
- `has_status_effect(effect_class: GDScript)` - Change parameter from enum to class type:
  - Use `is` operator to check if any status effect is an instance of the given class
  - Example: `has_status_effect(SilenceEffect)` instead of `has_status_effect(StatusEffect.EffectType.SILENCE)`
- `tick_status_effects()`:
  - Call `effect.on_tick(combatant)` for each effect
  - Process returned Dictionary (apply damage, etc.)
  - Call `effect.tick()` to decrement duration
  - Remove effects that return true from `tick()`

### 4. Enemy Status Effect Support

**File**: `scripts/data/enemy_data.gd`

Add status effect support to EnemyData class (using same pattern as Character):
- Add `status_effects: Array[StatusEffect] = []` property
- Add `add_status_effect(effect: StatusEffect)` method (same logic as Character)
- Add `tick_status_effects()` method (same logic as Character)
- Add `has_status_effect(effect_class: GDScript)` method (same logic as Character)
- Update `duplicate()` method to copy status effects

### 5. Status Effect Processing

**File**: `scripts/scenes/combat.gd`

Add status effect processing at the start of each turn in `_process_current_turn()`:
- Before executing the combatant's action, process their status effects:
  - Call `tick_status_effects()` on the combatant (handles `on_tick()` calls internally)
  - The `tick_status_effects()` method will:
    - Call `on_tick()` for each effect (returns Dictionary with effects to apply)
    - Apply returned effects (damage, etc.)
    - Call `tick()` to decrement duration
    - Remove expired effects
  - Log status effect processing in combat log
  - Update UI displays after processing

### 6. Effect Application

**File**: `scripts/scenes/combat.gd`

Implement `_apply_effect(effect_dict: Dictionary, source: Character)` method:
- Parse effect dictionary:
  - `type`: String (e.g., "burn", "silence", "taunt") or class name (e.g., "BurnEffect")
  - `target`: Variant (Character or EnemyData)
  - `magnitude`: float (for scaling effects)
  - `duration`: int (turns remaining)
  - `stacks`: int (optional, defaults to 1)
- Map string type to StatusEffect subclass:
  - Create a registry or factory function that maps string names to class types
  - Example: `{"burn": BurnEffect, "silence": SilenceEffect, "taunt": TauntEffect}`
  - Instantiate the appropriate StatusEffect subclass with parameters
- Call `add_status_effect()` on target (handles stacking via `on_apply()`)
- Log effect application in combat log
- Update UI displays

**Alternative**: Use class name directly in effect dictionary:
- `effect_dict["class"] = "BurnEffect"` or `effect_dict["class"] = BurnEffect`
- Instantiate using `ClassDB.instantiate()` or direct class reference

### 7. Status Effect Application from Minigame Results

**File**: `scripts/scenes/combat.gd`

The `_apply_minigame_result()` method already iterates through `result.effects` and calls `_apply_effect()`. Ensure effect dictionaries in MinigameResult use the correct format:
- `type` or `class`: String matching status effect class name (e.g., "BurnEffect", "SilenceEffect") or shorthand (e.g., "burn", "silence")
- `target`: Character or EnemyData reference
- `magnitude`: float (for effects that scale)
- `duration`: int (number of turns)
- `stacks`: int (optional, for stackable effects)

### 8. Silence Interaction with Ability System

**File**: `scripts/scenes/combat.gd`

Modify `_on_ability_pressed()` method:
- After validating it's a player character's turn
- Before opening minigame modal, check if character has Silence:
  - If `character.has_status_effect(SilenceEffect)`:
    - Log message: "%s is silenced and cannot use abilities!"
    - Return early (don't open minigame)
    - Use combat log EventType.STATUS_EFFECT

### 9. Status Effect Removal on Death

**File**: `scripts/scenes/combat.gd`

Modify death handling methods:
- `_handle_character_death(character: Character)`:
  - Clear `character.status_effects` array
  - Log status effect removal if any were present
- `_handle_enemy_death(enemy: EnemyData)`:
  - Clear `enemy.status_effects` array (after EnemyData support is added)
  - Log status effect removal if any were present

### 10. Visual Indicators

**Files**: `ui/character_display.tscn` and `ui/enemy_display.tscn` (or their script files)

Add visual indicators for active status effects:
- Display status effect icons/badges above or near character/enemy displays
- For each status effect, call `get_visual_data()` to get:
  - Icon path
  - Color
  - Whether to show stack count
- Show stack count for stackable effects (e.g., "Burn x3") if `show_stacks` is true
- Show duration remaining (optional, for debug/testing)
- Update indicators when status effects change (add, remove, tick)

**Extensibility**: New status effects automatically get visual representation through their `get_visual_data()` method - no UI code changes needed.

### 11. Item and Equipment Status Effect Application

**Files**: Item usage system (to be implemented in future backlog items)

When items or equipment apply status effects:
- Items: When item is used, create effect dictionary with class name and call `_apply_effect()` in combat
- Equipment: When equipment triggers effects (e.g., Wild Mage's Flame Sword on red flush), create effect dictionary in minigame result or class behavior
- Use class name in effect dictionary: `{"class": "BurnEffect", "duration": 3, "magnitude": 2.0, "stacks": 1}`

## Status Effect Processing Flow

```
Start of Turn (_process_current_turn)
  ↓
For current combatant:
  ↓
  Process Status Effects (tick_status_effects)
    ↓
    For each status effect:
      ↓
      Call effect.on_tick(combatant)
        ↓
        Returns Dictionary with effects (damage, etc.)
        ↓
        Apply returned effects
      ↓
      Call effect.tick() (decrements duration)
        ↓
        Returns true if should be removed
      ↓
      Remove if expired
  ↓
  Update UI displays
  ↓
  Execute combatant's action
    ↓
    (If ability, check SilenceEffect class first)
    ↓
    (If enemy attack, check TauntEffect class for targeting)
```

## Adding New Status Effects

To add a new status effect (e.g., "Poison"):

1. **Create new class file**: `scripts/data/status_effects/poison_effect.gd`
   ```gdscript
   class_name PoisonEffect
   extends StatusEffect
   
   func _init(p_duration: int = 3, p_stacks: int = 1, p_magnitude: float = 1.0):
       duration = p_duration
       stacks = p_stacks
       magnitude = p_magnitude
   
   func get_effect_name() -> String:
       return "Poison"
   
   func can_stack() -> bool:
       return true
   
   func on_apply(existing_effect: StatusEffect) -> void:
       if existing_effect is PoisonEffect:
           existing_effect.stacks += stacks
           existing_effect.duration = max(existing_effect.duration, duration)
   
   func on_tick(combatant: Variant) -> Dictionary:
       var damage: int = int(magnitude * stacks)
       return {"damage": damage}
   
   func get_visual_data() -> Dictionary:
       return {
           "icon": "res://icons/poison.png",
           "color": Color.PURPLE,
           "show_stacks": true
       }
   ```

2. **Register in effect factory** (if using string-based lookup):
   - Add to effect type mapping: `{"poison": PoisonEffect}`

3. **Use in game**:
   - Add to MinigameResult effects: `{"class": "PoisonEffect", "duration": 3, "magnitude": 1.5}`
   - Check for effect: `character.has_status_effect(PoisonEffect)`

**No other code changes required!** The system automatically handles the new effect through polymorphism.

## Debug Features for Testing

### Temporary Debug UI
Add debug panel/overlay in combat scene (can be toggled with debug key):
- **Status Effect List**: Show all active status effects on all combatants
  - Display: Combatant name, effect class name (from `get_effect_name()`), duration, stacks, magnitude
  - Update in real-time as effects are processed
  - Use visual data from `get_visual_data()` for icons and colors
- **Apply Effect Button**: Manually apply status effects for testing
  - Dropdown to select effect class (dynamically populated from available StatusEffect subclasses)
  - Input fields for duration, stacks, magnitude
  - Target selector (party member or enemy)
  - Apply button to trigger effect
  - **Extensibility**: Automatically includes any new StatusEffect subclasses without code changes
- **Clear Effects Button**: Remove all status effects from selected combatant
  - Useful for resetting test state
- **Force Tick Button**: Manually trigger status effect processing
  - Processes all effects on all combatants immediately
  - Useful for testing duration decrement and expiration
- **Effect Registry Display**: Show all registered status effect classes
  - Useful for verifying extensibility and discovering available effects

### Debug Console Commands
Add console commands (if console system exists) or keyboard shortcuts:
- `apply_effect <effect_class> <target_name> [duration] [stacks] [magnitude]`: Apply any status effect
  - Example: `apply_effect BurnEffect PartyMember1 3 2 1.5`
  - **Extensibility**: Works with any StatusEffect subclass automatically
- `apply_burn <target_name> <duration> <stacks>`: Apply burn effect (convenience command)
- `apply_silence <target_name> <duration>`: Apply silence effect (convenience command)
- `apply_taunt <target_name> <duration>`: Apply taunt effect (convenience command)
- `clear_effects <target_name>`: Clear all effects from target
- `tick_effects`: Process all status effects once
- `show_effects`: Print all active status effects to console (shows class names)
- `list_effect_classes`: Print all available status effect classes

### Debug Logging
Enhanced logging for status effect system:
- Log when effects are applied (source, target, type, duration, stacks)
- Log when effects are processed (damage dealt, duration remaining)
- Log when effects expire or are removed
- Log when effects are blocked (e.g., Silence preventing ability)
- Use distinct log entry types for easy filtering

### Test Scenarios
Create test scenarios to verify:
1. **Burn Stacking**: Apply multiple burn effects, verify stacks accumulate and damage scales
2. **Burn Duration**: Apply burn with 3 duration, verify it deals damage for 3 turns then expires
3. **Silence Blocking**: Apply silence, verify ability button is disabled/blocked
4. **Taunt Targeting**: Apply taunt to one party member, verify all enemies target that member
5. **Effect Removal on Death**: Apply effects, kill combatant, verify effects are cleared
6. **Effect Refresh**: Apply same effect twice, verify duration refreshes (for non-stacking effects)
7. **Multiple Effects**: Apply multiple different effects, verify all process correctly
8. **Enemy Status Effects**: Apply effects to enemies, verify they process correctly

## Related Files
- `scripts/data/status_effect.gd` - Base status effect class (to be refactored)
- `scripts/data/status_effects/burn_effect.gd` - Burn status effect subclass (to be created)
- `scripts/data/status_effects/silence_effect.gd` - Silence status effect subclass (to be created)
- `scripts/data/status_effects/taunt_effect.gd` - Taunt status effect subclass (to be created)
- `scripts/data/character.gd` - Character status effect support (needs refactoring for class-based system)
- `scripts/data/enemy_data.gd` - Enemy data (needs status effect support added)
- `scripts/scenes/combat.gd` - Combat system (main implementation location)
- `scripts/data/minigame_result.gd` - Minigame result effects array
- `scripts/class_behaviors/*.gd` - Class behaviors that may apply status effects
- `ui/character_display.tscn` - Character display UI (needs status effect indicators)
- `ui/enemy_display.tscn` - Enemy display UI (needs status effect indicators)

## Dependencies
- Status effect system should be implemented before:
  - **13_effect_application_system.md** - Effect application system builds on status effects
  - **23_item_effects_implementation.md** - Items may apply status effects
  - **24_equipment_effects_system.md** - Equipment may apply status effects

## Status
**DONE** ✅

The status effect system has been fully implemented with:
- ✅ Base StatusEffect class with extensible architecture
- ✅ StatusEffectManager composition pattern (eliminates duplication)
- ✅ BurnEffect, SilenceEffect, TauntEffect, and AlterAttributeEffect implementations
- ✅ Full integration with Character and EnemyData classes
- ✅ Status effect processing at start of each turn
- ✅ Effect application from minigame results
- ✅ Silence blocking ability usage
- ✅ Taunt affecting enemy targeting
- ✅ Status effect removal on death
- ✅ Visual indicators in UI displays
- ✅ Shared StatusEffectDisplayHelper for UI code
- ✅ on_modify_attributes() virtual method for attribute modifications
- ✅ Monk's Strategy debuff wired up via AlterAttributeEffect

