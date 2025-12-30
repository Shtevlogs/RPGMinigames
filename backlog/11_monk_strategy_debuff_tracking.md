# Monk: Strategy Debuff Tracking

**Priority**: 11 (Chunk 2: Combat & Minigames)

## Description
Implement Strategy debuff tracking from basic attacks. Basic attacks reduce enemy Strategy by 1 (stacking), affecting number of cards in next minigame.

## Requirements
- Track Strategy debuffs on enemies
- Apply debuff on basic attack (stacking)
- Use debuffed Strategy for card count calculation
- Reset debuffs appropriately (on encounter end or after minigame)

## Related Files
- `scripts/class_behaviors/monk_behavior.gd`
- `scripts/scenes/combat.gd`
- `scripts/data/enemy_data.gd`

## Status
Pending

