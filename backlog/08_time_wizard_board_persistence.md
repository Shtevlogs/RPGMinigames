# Time Wizard: Board State Persistence

**Priority**: 08 (Chunk 2: Combat & Minigames)

## Description
Implement board state persistence from basic attacks. Basic attacks should partially clear the board for the next minigame cast.

Note: this should 'feel like' persistence, but actually the implementation will be to store a flag so next time the Time Wizard's minigame is generated, it automatically starts with one click from the center. To make this a useful state, we'll also need to add a slight delay (say, 3 seconds) to the beginning of the Time Wizard's minigame to let the player look it over when it is auto filled.

## Requirements
- Store revealed squares from previous minigame
- Apply partial board clear on next minigame start
- Persist between ability uses
- Reset on encounter start

## Related Files
- `scripts/minigames/time_wizard_minigame.gd`
- `scripts/class_behaviors/time_wizard_behavior.gd`
- `scripts/scenes/combat.gd`

## Status
Pending

