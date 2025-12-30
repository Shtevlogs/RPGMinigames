# MinigameContext Type Safety

**Priority**: Refactor 03 (Foundation)

## Description

Remove the dictionary conversion in `_build_minigame_context()` and pass typed `MinigameContext` objects directly throughout the system. This eliminates unnecessary type conversions and maintains type safety from behavior classes through to minigame instances.

**Design Philosophy**: Typed classes provide better type safety, IDE support, and code clarity than dictionaries. The minigame context classes already exist but are being converted to dictionaries unnecessarily. This refactor maintains type safety throughout the data flow.

## Context from Architecture Documents

### From architecture_review_notes.md:
> "I see now that the minigame context classes are being turned back into dictionaries in _build_minigame_context. They should just be passed on into the minigame modal load_minigame function as MinigameContexts. The goal is that the minigame instances themselves have these objects to reference."

> "In the subclasses will be where initializing effects will take place for my note above (line 40)." (referring to status effect initialization in minigame subclasses)

### From ARCHITECTURE_PRIMER.md:
- Typed context classes exist: `MinigameContext`, `BerserkerMinigameContext`, `MonkMinigameContext`, `TimeWizardMinigameContext`, `WildMageMinigameContext`
- Behavior classes build typed contexts via `build_minigame_context() -> MinigameContext`
- Combat system converts typed contexts to dictionaries in `_build_minigame_context()`
- MinigameModal accepts `Dictionary` for context
- BaseMinigame stores context as `Dictionary`

### From gamedoc.md:
- Minigame contexts contain class-specific data needed for minigame execution
- Contexts are built by behavior classes based on character state
- Contexts should be type-safe and provide clear structure

## Dependencies

**None** - This refactor is independent but should be done before:
- refactor_04_minigame_result_type_safety.md (Both improve type safety in minigame system)

## Current State

### Current Data Flow

1. **Behavior Classes** (`BaseClassBehavior.build_minigame_context()`):
   - Build and return typed `MinigameContext` objects
   - Example: `BerserkerBehavior` returns `BerserkerMinigameContext`

2. **Combat System** (`combat.gd._build_minigame_context()`):
   - Receives typed context from behavior
   - Converts typed context to dictionary via match statement
   - Returns dictionary to minigame modal

3. **MinigameModal** (`minigame_modal.gd.load_minigame()`):
   - Accepts `context: Dictionary` parameter
   - Passes dictionary to minigame instance

4. **BaseMinigame** (`base_minigame.gd`):
   - Stores context as `minigame_context: Dictionary`
   - Subclasses access dictionary values

### Problems with Current Approach

1. **Unnecessary Conversion**: Typed contexts are converted to dictionaries, losing type safety
2. **Type Checking**: Minigames must check dictionary keys and cast values
3. **No IDE Support**: Dictionary access lacks autocomplete and type checking
4. **Error-Prone**: Missing keys or wrong types cause runtime errors
5. **Code Duplication**: Conversion logic in combat system must be maintained

### Existing Context Classes

- `MinigameContext` (base class) - `scripts/data/minigame_context.gd`
- `BerserkerMinigameContext` - `scripts/data/berserker_minigame_context.gd`
- `MonkMinigameContext` - `scripts/data/monk_minigame_context.gd`
- `TimeWizardMinigameContext` - `scripts/data/time_wizard_minigame_context.gd`
- `WildMageMinigameContext` - `scripts/data/wild_mage_minigame_context.gd`

## Requirements

### Core Functionality

1. **Remove Dictionary Conversion**:
   - Remove `_build_minigame_context()` conversion logic
   - Pass typed `MinigameContext` directly from behavior to modal

2. **Update MinigameModal**:
   - Change `load_minigame()` to accept `context: MinigameContext` instead of `Dictionary`
   - Pass typed context to minigame instance

3. **Update BaseMinigame**:
   - Change `minigame_context: Dictionary` to `minigame_context: MinigameContext`
   - Update `_ready()` to handle typed context
   - Remove dictionary access patterns

4. **Update Minigame Subclasses**:
   - Cast `minigame_context` to specific context type
   - Access typed properties directly
   - Remove dictionary key checking

### Interface Requirements

**MinigameModal.load_minigame()**:
```gdscript
func load_minigame(minigame_scene_path: String, context: MinigameContext) -> void:
    # Pass typed context to minigame
    pass
```

**BaseMinigame**:
```gdscript
var minigame_context: MinigameContext = null

func _ready() -> void:
    # Receive typed context from modal or StateManager
    # Cast to specific type in subclasses
    pass
```

**Minigame Subclasses**:
```gdscript
func initialize_minigame() -> void:
    var context = minigame_context as BerserkerMinigameContext
    if context == null:
        push_error("Invalid context type")
        return
    # Use typed properties directly
    var effect_ranges = context.effect_ranges
```

## Implementation Plan

### Phase 1: Update MinigameModal

1. **Update `scripts/ui/minigame_modal.gd`**:
   - Change `load_minigame(minigame_scene_path: String, context: Dictionary)` to `load_minigame(minigame_scene_path: String, context: MinigameContext)`
   - Update minigame instance setup to pass typed context
   - Remove dictionary handling

2. **Update minigame instance creation**:
   - Set `minigame_instance.minigame_context = context` directly
   - Remove dictionary conversion

### Phase 2: Update BaseMinigame

1. **Update `scripts/minigames/base_minigame.gd`**:
   - Change `var minigame_context: Dictionary = {}` to `var minigame_context: MinigameContext = null`
   - Update `_ready()` to handle typed context
   - Remove dictionary access from `_ready()`
   - Update `build_context()` static method signature if needed

2. **Update context initialization**:
   - Check if context is set directly (from modal)
   - Fall back to StateManager if needed (for backward compatibility during transition)
   - Ensure context is typed

### Phase 3: Remove Dictionary Conversion

1. **Update `scripts/scenes/combat.gd`**:
   - Remove `_build_minigame_context()` method entirely
   - Update minigame opening logic to pass typed context directly:
     ```gdscript
     var behavior = MinigameRegistry.get_behavior(character.class_type)
     var context: MinigameContext = behavior.build_minigame_context(character, target)
     current_modal.load_minigame(scene_path, context)
     ```

2. **Remove conversion logic**:
   - Remove match statement for context type conversion
   - Remove dictionary building code
   - Pass typed context directly

### Phase 4: Update Minigame Subclasses

1. **Update `scripts/minigames/berserker_minigame.gd`**:
   - Cast `minigame_context` to `BerserkerMinigameContext`
   - Access typed properties: `context.effect_ranges`, `context.is_berserking`, etc.
   - Remove dictionary key checking

2. **Update `scripts/minigames/monk_minigame.gd`**:
   - Cast `minigame_context` to `MonkMinigameContext`
   - Access typed properties: `context.target_strategy`, `context.enemy_cards`, etc.
   - Remove dictionary key checking

3. **Update `scripts/minigames/time_wizard_minigame.gd`**:
   - Cast `minigame_context` to `TimeWizardMinigameContext`
   - Access typed properties: `context.board_state`, `context.board_size`, etc.
   - Remove dictionary key checking

4. **Update `scripts/minigames/wild_mage_minigame.gd`**:
   - Cast `minigame_context` to `WildMageMinigameContext`
   - Access typed properties: `context.pre_drawn_card`, `context.hand_size`, etc.
   - Remove dictionary key checking

### Phase 5: Update StateManager (if needed)

1. **Update `scripts/managers/state_manager.gd`**:
   - If StateManager stores minigame context, update to use typed context
   - Update `get_minigame_context()` to return `MinigameContext` instead of `Dictionary`
   - Update `set_minigame_context()` to accept `MinigameContext`

2. **Remove StateManager usage** (preferred):
   - Context should be passed directly from combat to modal to minigame
   - StateManager may not be needed for context storage

## Related Files

### Core Files to Modify
- `scripts/scenes/combat.gd` - Remove `_build_minigame_context()`, pass typed context directly
- `scripts/ui/minigame_modal.gd` - Accept `MinigameContext` instead of `Dictionary`
- `scripts/minigames/base_minigame.gd` - Store typed context, update initialization

### Minigame Files
- `scripts/minigames/berserker_minigame.gd` - Cast and use typed context
- `scripts/minigames/monk_minigame.gd` - Cast and use typed context
- `scripts/minigames/time_wizard_minigame.gd` - Cast and use typed context
- `scripts/minigames/wild_mage_minigame.gd` - Cast and use typed context

### Context Files (no changes needed)
- `scripts/data/minigame_context.gd` - Base class (already exists)
- `scripts/data/berserker_minigame_context.gd` - Already exists
- `scripts/data/monk_minigame_context.gd` - Already exists
- `scripts/data/time_wizard_minigame_context.gd` - Already exists
- `scripts/data/wild_mage_minigame_context.gd` - Already exists

### Manager Files (may need updates)
- `scripts/managers/state_manager.gd` - Update if context is stored here

## Testing Considerations

1. **Type Safety**: Verify all context access uses typed properties
2. **Context Passing**: Verify contexts are passed correctly through the chain
3. **Minigame Functionality**: Verify all minigames work correctly with typed contexts
4. **Error Handling**: Verify proper error handling for invalid context types
5. **Backward Compatibility**: If StateManager is used, ensure transition is smooth

## Migration Notes

### Breaking Changes
- `MinigameModal.load_minigame()` signature changes
- `BaseMinigame.minigame_context` type changes
- Minigame subclasses must cast context to specific type

### Backward Compatibility
- Not needed - this is a refactor for type safety
- All minigames must be updated to use typed contexts

## Status

Pending

