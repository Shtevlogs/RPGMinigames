# Item Carryover on Run Failure

**Priority**: 34 (Chunk 6: Meta-Progression & Run Completion)

## Description
Implement item carryover system. When party wipes, player can choose one item to save for the next run.

## Requirements
- Detect party wipe
- Display item selection UI
- Save selected item to persistent storage
- Load saved item at start of next run
- Only one item can be carried over per run failure

## Related Files
- `scripts/scenes/combat.gd`
- `scripts/managers/game_manager.gd`
- `scripts/managers/save_manager.gd`
- `scripts/scenes/party_selection.gd`

## Status
Pending

