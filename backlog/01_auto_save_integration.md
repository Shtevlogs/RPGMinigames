# Auto-Save Integration

**Priority**: 01 (Chunk 1: Core Systems)

## Description
Integrate SaveManager auto-save functionality into gameplay flow. SaveManager exists but is not currently called during gameplay. The main menu resume button exists but will not work correctly until auto-saves are created during gameplay.

## Dependencies

**⚠️ Important**: The following features should be completed or mostly finalized before implementing full auto-save serialization. Building serialization for systems that are still changing will require rework.

### Critical Dependencies (Must Complete First)
- **03_status_effect_system.md** - Status effects need to be finalized before serialization
- **13_effect_application_system.md** - Effect system structure affects how status effects are stored
- **23_item_effects_implementation.md** - Item effects dictionary structure needs to be finalized

### Recommended Dependencies (Should Complete First)
- **21_item_usage_system.md** - Item system should be stable before serializing item data
- **22_equipment_ui.md** - Equipment equipping/unequipping should be finalized
- **24_equipment_effects_system.md** - Equipment effects structure affects serialization
- **26_equipment_acquisition.md** - Equipment acquisition methods affect what needs to be saved

### Partial Implementation Option
If these dependencies are not complete, consider implementing auto-save in phases:
1. **Phase 1 (Minimal)**: Auto-save basic run state (party, land progress, inventory) without full serialization of equipment/status effects
2. **Phase 2 (Complete)**: Add full serialization once dependent systems are finalized

This allows testing auto-save integration points (when/where to save) while deferring complex serialization until data structures are stable.

## Current State

### SaveManager (`scripts/managers/save_manager.gd`)
- **Auto-save methods exist**: `auto_save()`, `load_auto_save()`, `has_auto_save()`, `delete_auto_save()`
- **Serialization incomplete**: Current serialization only saves basic character data (attributes, health) and basic item data (id, name, type)
- **Missing serialization**: Equipment, status effects, class_state dictionary, item effects dictionary

### Main Menu (`scripts/scenes/main_menu.gd`)
- **Resume button exists**: Checks for auto-save and loads it
- **Resume logic**: Always transitions to combat scene (may not be correct if player was on land screen)
- **Button state**: Disabled if no save exists

### Game Flow
- **No auto-save calls**: SaveManager.auto_save() is never called during gameplay
- **Run start**: `GameManager.start_new_run()` does not delete old save
- **Run end**: `GameManager.end_run()` does not delete save (should delete on completion/failure)
- **Encounter completion**: `Combat.complete_encounter()` does not save
- **Land screen transitions**: `LandScreen` does not save

## Requirements

### Core Functionality
1. **Auto-save at key points**:
   - After encounter completion (in `Combat.complete_encounter()`)
   - When transitioning to land screen (in `Combat.complete_encounter()` before scene transition)
   - When leaving land screen to combat (in `LandScreen._on_continue_pressed()` before scene transition)
   - When advancing to next land (in `LandScreen._advance_to_next_land()`)

2. **Save cleanup**:
   - Delete auto-save when starting new run (in `GameManager.start_new_run()`)
   - Delete auto-save when run completes successfully (in `GameManager.end_run()` when success=true)
   - Delete auto-save when run fails (in `GameManager.end_run()` when success=false, or in `Combat._handle_party_wipe()`)

3. **Prevent save-scumming**:
   - Only auto-save, no manual save option
   - Auto-save overwrites previous save (already implemented)
   - No save/load menu options

### Serialization Improvements

The current `SaveManager.serialize_run_state()` and `deserialize_run_state()` methods are incomplete. They need to handle:

1. **Character serialization** (currently missing):
   - Equipment (`EquipmentSlots`): rings, neck, armor, head, class_specific arrays
   - Status effects (`Array[StatusEffect]`): effect_type, duration, stacks, magnitude
   - Class state (`Dictionary`): class-specific state like berserk stacks, effect ranges, etc.
   - Character name (currently saved but verify)

2. **Item serialization** (currently incomplete):
   - Item effects dictionary (currently not saved)
   - Combat-only flag (currently not saved)

3. **Equipment serialization** (completely missing):
   - Each equipment piece needs: equipment_id, equipment_name, slot_type, attribute_bonuses
   - EquipmentSlots structure: rings array, neck, armor, head, class_specific array

4. **Status effect serialization** (completely missing):
   - EffectType enum value
   - Duration, stacks, magnitude

### Resume Functionality Improvements

1. **Resume location detection**:
   - Store last scene in `RunState.auto_save_data` dictionary (e.g., `{"last_scene": "land_screen"}` or `{"last_scene": "combat"}`)
   - On resume, check `auto_save_data["last_scene"]` and transition to appropriate scene
   - Default to land screen if not specified (safer than combat)

2. **Resume validation**:
   - Verify loaded run state is valid (party not empty, land sequence valid, etc.)
   - Handle corrupted saves gracefully (show error, delete save, return to main menu)

3. **Resume state restoration**:
   - Ensure all character state is restored (equipment, status effects, class_state)
   - Ensure inventory is restored correctly
   - Ensure encounter progress is correct

## Implementation Plan

### Phase 1: Complete Serialization
1. **Update `SaveManager.serialize_run_state()`**:
   - Add equipment serialization for each character
   - Add status effects serialization for each character
   - Add class_state serialization for each character
   - Add item effects and combat_only flag serialization
   - Add last_scene to auto_save_data

2. **Update `SaveManager.deserialize_run_state()`**:
   - Add equipment deserialization (create Equipment objects, populate EquipmentSlots)
   - Add status effects deserialization (create StatusEffect objects)
   - Add class_state deserialization
   - Add item effects and combat_only flag deserialization
   - Handle missing fields gracefully (backward compatibility)

### Phase 2: Integrate Auto-Save Calls
1. **Combat scene**:
   - Call `SaveManager.auto_save(GameManager.current_run)` in `Combat.complete_encounter()` before transitioning to land screen
   - Set `run_state.auto_save_data["last_scene"] = "land_screen"` before saving

2. **Land screen**:
   - Call `SaveManager.auto_save(GameManager.current_run)` in `LandScreen._on_continue_pressed()` before transitioning to combat
   - Set `run_state.auto_save_data["last_scene"] = "combat"` before saving
   - Call `SaveManager.auto_save()` in `LandScreen._advance_to_next_land()` after updating land state

3. **GameManager**:
   - Call `SaveManager.delete_auto_save()` in `GameManager.start_new_run()` before creating new run
   - Call `SaveManager.delete_auto_save()` in `GameManager.end_run()` regardless of success/failure

4. **Combat party wipe**:
   - Ensure `GameManager.end_run(false)` is called (already implemented in `_handle_party_wipe()`)
   - Save deletion will happen in `end_run()`

### Phase 3: Improve Resume Functionality
1. **Main menu resume**:
   - Update `MainMenu._on_resume_pressed()` to check `auto_save_data["last_scene"]`
   - Transition to land screen if `last_scene == "land_screen"` or not specified
   - Transition to combat if `last_scene == "combat"`
   - Add error handling for corrupted saves

2. **Resume validation**:
   - Add validation in `MainMenu._on_resume_pressed()` to check:
     - Run state is not null
     - Party is not empty
     - Land sequence is valid
     - Current land is within valid range (1-5)

## Related Files
- `scripts/managers/save_manager.gd` - Serialization/deserialization logic
- `scripts/managers/game_manager.gd` - Run lifecycle, save deletion on start/end
- `scripts/scenes/combat.gd` - Auto-save after encounter completion
- `scripts/scenes/land_screen.gd` - Auto-save on transitions and land advancement
- `scripts/scenes/main_menu.gd` - Resume functionality improvements
- `scripts/data/run_state.gd` - Run state structure, auto_save_data dictionary
- `scripts/data/character.gd` - Character structure (equipment, status_effects, class_state)
- `scripts/data/item.gd` - Item structure (effects, combat_only)
- `scripts/data/equipment.gd` - Equipment structure
- `scripts/data/equipment_slots.gd` - EquipmentSlots structure
- `scripts/data/status_effect.gd` - StatusEffect structure

## Testing & Debug Features

### Temporary Debug Features for Testing

1. **Manual Save Button** (temporary):
   - Add debug button to combat scene (visible only in debug mode)
   - Add debug button to land screen (visible only in debug mode)
   - Button calls `SaveManager.auto_save(GameManager.current_run)` directly
   - Allows testing save/load without completing encounters

2. **Save State Display** (temporary):
   - Add debug label to main menu showing:
     - Whether save exists (`SaveManager.has_auto_save()`)
     - Save file path
     - Last save timestamp (if stored in auto_save_data)
   - Add debug label to combat/land screen showing:
     - Last save time
     - Save count (increment counter in auto_save_data)

3. **Load Test Button** (temporary):
   - Add debug button to main menu to test loading without using resume button
   - Prints loaded run state details to console
   - Validates serialization/deserialization

4. **Save File Inspector** (temporary):
   - Add debug function to print save file contents to console
   - Useful for verifying serialization completeness
   - Can be called from debug menu or console command

5. **Force Save Deletion** (temporary):
   - Add debug button to main menu to manually delete save
   - Useful for testing save cleanup

6. **Serialization Test** (temporary):
   - Add debug function that:
     - Creates a test run state with all data types (equipment, status effects, class_state)
     - Serializes it
     - Deserializes it
     - Compares original and deserialized state
     - Reports any missing or incorrect data

### Debug Implementation Notes
- All debug features should be gated behind a debug flag (e.g., `const DEBUG_MODE = true`)
- Debug UI elements should be clearly marked and easy to remove
- Consider using Godot's built-in debug overlay or a separate debug panel
- Remove all debug features before release

## Status
Pending

