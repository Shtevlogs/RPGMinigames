# Complete Save/Load System

**Priority**: 02 (Chunk 1: Core Systems)

## Description
Implement complete save/load functionality for all game state including equipment, status effects, and class-specific states (e.g., Berserker berserk stacks).

## Requirements
- Save all character state (attributes, health, equipment)
- Save status effects and durations
- Save class-specific states (berserk stacks, pre-drawn cards, etc.)
- Save encounter progress and land state
- Load all state correctly on resume

## Related Files
- `scripts/managers/save_manager.gd`
- `scripts/data/run_state.gd`
- `scripts/data/character.gd`
- `scripts/data/status_effect.gd`
- `scripts/class_behaviors/*.gd`

## Status
Pending

