# Berserker: Berserk State Implementation

**Priority**: 04 (Chunk 2: Combat & Minigames)

## Description
Implement Berserker berserk state mechanics including stacking, Power/Speed bonuses, and state management. The berserk state is triggered when the Berserker scores a blackjack (21) or busts in the blackjack minigame. While berserking, the Berserker gains Power and Speed bonuses that stack up to 10 times, but cannot generate effect ranges. Basic attacks while berserking deal enhanced damage, heal the Berserker, and clear all berserk stacks.

## Current State

### Existing Infrastructure
- **BerserkerBehavior** (`scripts/class_behaviors/berserker_behavior.gd`): 
  - Tracks berserk state in `class_state` dictionary (`is_berserking`, `berserk_stacks`)
  - Partially implements basic attack effects (1.5x damage implemented, heal and stack removal are TODO)
  - Builds minigame context with berserk state information
- **BerserkerMinigame** (`scripts/minigames/berserker_minigame.gd`):
  - Detects blackjack and bust conditions
  - Tracks berserk state in metadata but doesn't apply it
  - Has TODO comments for berserk state application
- **Character Class** (`scripts/data/character.gd`):
  - Has `class_state: Dictionary` for class-specific state storage
  - Has status effect system via `StatusEffectManager`
  - `get_effective_attributes()` applies status effect attribute modifications
- **AlterAttributeEffect** (`scripts/data/status_effects/alter_attribute_effect.gd`):
  - Can modify Power and Speed attributes
  - Stacks additively (alteration_amount accumulates)
  - Has duration system (but berserk state should persist until cleared)
  - Applied through status effect system

### Missing Implementation
1. Berserk state triggering on blackjack or bust
2. Power and Speed attribute bonuses via AlterAttributeEffect
3. Stacking logic (up to 10 stacks)
4. Clearing berserk stacks on basic attack
5. Preventing effect range generation while berserking (effect range generation itself can be stubbed - the key is ensuring it's disabled while berserking)
6. Visual indicators for berserk state
7. HP regeneration on blackjack (separate feature, but related)

## Requirements

### Core Functionality
- **Trigger Conditions**: Berserk state triggers when:
  - Berserker scores exactly 21 (blackjack) in minigame
  - Berserker busts (hand value > 21) in minigame
- **Stacking**: Berserk state can stack up to 10 times
  - Each time berserk triggers while already berserking, add 1 stack (up to 10)
  - Stacks are tracked in `character.class_state["berserk_stacks"]`
- **Attribute Bonuses**: Each berserk stack provides:
  - +1 Power (via AlterAttributeEffect)
  - +1 Speed (via AlterAttributeEffect)
  - Bonuses are applied through status effect system
- **State Persistence**: Berserk state persists until:
  - Berserker uses a basic attack while berserking (clears all stacks)
  - Character dies (status effects are cleared automatically)
- **Effect Range Prevention**: While berserking (`is_berserking == true`), basic attacks do NOT generate effect ranges
- **Visual Indicators**: Display berserk state and stack count in UI

### Design Decisions

#### Using AlterAttributeEffect for Bonuses
The berserk state Power and Speed bonuses will be implemented using `AlterAttributeEffect` status effects:
- **Benefits**:
  - Integrates with existing status effect system
  - Automatically applies through `get_effective_attributes()`
  - Provides visual indicators through status effect system
  - Stacks additively (each stack adds +1 to alteration_amount)
- **Implementation**:
  - Apply two `AlterAttributeEffect` instances: one for Power, one for Speed
  - Set `alteration_amount` equal to berserk stacks
  - Use very long duration (e.g., 999 turns) since berserk persists until cleared
  - Update `alteration_amount` when stacks change
  - Remove effects when berserk state is cleared

#### State Management
- **Dual Tracking**: Both `class_state` and status effects track berserk state:
  - `class_state["is_berserking"]`: Boolean flag for quick checks
  - `class_state["berserk_stacks"]`: Stack count for UI/logging
  - Status effects: Actual attribute modifications
- **Why Both**: 
  - `class_state` provides fast access for conditional logic (e.g., effect range generation)
  - Status effects provide automatic attribute calculation and visual indicators
  - Status effects integrate with existing systems (equipment, other effects)

## Implementation Details

### 1. Berserk State Triggering

**File**: `scripts/minigames/berserker_minigame.gd`

#### In `_deal_initial_cards()` (Natural Blackjack)
When natural blackjack is detected (line 134-137):
```gdscript
if hand_value == 21 and hand.size() == 2:
    is_blackjack = true
    # Apply berserk state and HP regeneration
    # TODO: Apply berserk state and HP regeneration
```

**Implementation**:
- Set `is_berserking = true` in minigame state
- Calculate new berserk stacks: `min(berserk_stacks + 1, 10)`
- Include berserk state in minigame result metadata

#### In `_calculate_hand_value()` (Bust)
When bust is detected (line 170-173):
```gdscript
if hand_value > 21:
    is_busted = true
    # Stub: Would trigger berserk state here
    # TODO: Apply berserk state on bust
```

**Implementation**:
- Set `is_berserking = true` in minigame state
- Calculate new berserk stacks: `min(berserk_stacks + 1, 10)`
- Include berserk state in minigame result metadata

#### In `_on_stand_button_pressed()` (Result Creation)
When creating minigame result (line 250-261):
- Include `is_berserking` and `berserk_stacks` in metadata
- These values will be used by combat system to apply berserk state

### 2. Applying Berserk State in Combat

**File**: `scripts/scenes/combat.gd`

#### In `_apply_minigame_result()`
After processing minigame result damage and effects, check for berserk state:
- Read `is_berserking` and `berserk_stacks` from `result.metadata`
- If `is_berserking == true`:
  - Update `character.class_state["is_berserking"] = true`
  - Update `character.class_state["berserk_stacks"] = berserk_stacks`
  - Apply or update Power and Speed AlterAttributeEffects

**Berserk State Application Logic**:
```gdscript
# Check if already berserking
var current_stacks: int = character.class_state.get("berserk_stacks", 0)
var new_stacks: int = result.metadata.get("berserk_stacks", 0)

# If new stacks > current, update (stacking)
if new_stacks > current_stacks:
    # Update class_state
    character.class_state["is_berserking"] = true
    character.class_state["berserk_stacks"] = new_stacks
    
    # Apply or update Power effect
    var power_effect = AlterAttributeEffect.new("power", new_stacks, 999)
    character.add_status_effect(power_effect)
    
    # Apply or update Speed effect
    var speed_effect = AlterAttributeEffect.new("speed", new_stacks, 999)
    character.add_status_effect(speed_effect)
```

**Note**: AlterAttributeEffect's `on_apply()` will handle stacking automatically (adds alteration_amount), but we need to ensure we're updating to the correct total stack count. May need to remove existing effects first or calculate delta.

### 3. Clearing Berserk State on Basic Attack

**File**: `scripts/class_behaviors/berserker_behavior.gd`

#### In `apply_attack_effects()`
Current implementation (line 20-38) has TODO comments for heal and stack removal.

**Implementation**:
```gdscript
if is_berserking:
    # 1.5x damage (already implemented)
    var modified_damage: int = int(base_damage * 1.5)
    
    # Heal percentage of HP (TODO)
    var heal_percentage: float = 0.1  # 10% of max HP
    var heal_amount: int = int(character.health.max_hp * heal_percentage)
    character.health.heal(heal_amount)
    
    # Remove all berserk stacks
    character.class_state["is_berserking"] = false
    character.class_state["berserk_stacks"] = 0
    
    # Remove Power and Speed AlterAttributeEffects
    # Find and remove Power effect
    for i in range(character.status_effects.size() - 1, -1, -1):
        var effect = character.status_effects[i]
        if effect is AlterAttributeEffect:
            var alter_effect = effect as AlterAttributeEffect
            if alter_effect.attribute_name == "power" or alter_effect.attribute_name == "speed":
                character.status_effects.remove_at(i)
    
    return modified_damage
```

**Alternative Approach**: Instead of removing effects, could set `alteration_amount = 0` and let them expire, but removal is cleaner.

### 4. Preventing Effect Range Generation

**File**: `scripts/class_behaviors/berserker_behavior.gd`

#### In `apply_attack_effects()`
Current implementation (line 34-38) has TODO for effect range tracking.

**Implementation**:
```gdscript
if is_berserking:
    # ... berserking attack effects ...
    return modified_damage
else:
    # Not berserking: add effect ranges to blackjack minigame
    # Only generate effect ranges if NOT berserking
    # NOTE: Effect range generation will be implemented in backlog item 06_berserker_effect_ranges.md
    # For now, this is stubbed - the key requirement is that effect ranges are NOT generated while berserking
    # TODO: Track effect ranges for next ability use (see backlog item 06)
    pass
    return base_damage
```

**Note**: 
- Effect range generation is a separate feature (backlog item 06) and can be stubbed for now
- The critical requirement is that effect ranges are **NOT** generated while `is_berserking == true`
- The actual effect range generation logic will be implemented later, but the berserk state check must be in place

### 5. Visual Indicators

**Files**: `ui/character_display.tscn` and its script

The status effect system already provides visual indicators through `get_visual_data()`. AlterAttributeEffect will show:
- Green color for Power/Speed buffs (positive alteration_amount)
- Stack count display (shows total alteration_amount, which equals berserk stacks)

**Additional UI Considerations**:
- Could add custom berserk state indicator (e.g., "BERSERK x5" badge)
- Status effect indicators should already show Power and Speed buffs
- Combat log should show berserk state entries (see logging section)

### 6. Combat Log Integration

**File**: `scripts/class_behaviors/berserker_behavior.gd`

#### In `format_minigame_result()`
Current implementation (line 60-66) has stubbed berserk state logging.

**Implementation**:
```gdscript
var is_berserking: bool = result.metadata.get("is_berserking", false)
var berserk_stacks: int = result.metadata.get("berserk_stacks", 0)
if is_berserking and berserk_stacks > 0:
    if berserk_stacks == 1:
        log_entries.append("%s enters Berserk state! (+1 Power, +1 Speed)" % character.name)
    else:
        log_entries.append("%s's Berserk state intensifies! (%d stacks: +%d Power, +%d Speed)" % [character.name, berserk_stacks, berserk_stacks, berserk_stacks])
```

**In Combat System**:
When berserk state is cleared on basic attack, log:
```gdscript
combat_log.add_entry("%s's Berserk state ends! (stacks cleared)" % character.name, combat_log.EventType.ABILITY)
```

## Status Effect Integration

### Using AlterAttributeEffect

The berserk state will use two `AlterAttributeEffect` instances:
1. **Power Effect**: `AlterAttributeEffect.new("power", berserk_stacks, 999)`
2. **Speed Effect**: `AlterAttributeEffect.new("speed", berserk_stacks, 999)`

**Key Properties**:
- `attribute_name`: "power" or "speed"
- `alteration_amount`: Equal to berserk stacks (1-10)
- `duration`: 999 (very long, since berserk persists until cleared)
- `stacks`: 1 (stacking handled by alteration_amount, not effect stacks)
- `magnitude`: 1.0 (not used)

**Stacking Behavior**:
- AlterAttributeEffect's `on_apply()` adds `alteration_amount` to existing effect
- When berserk stacks increase, need to update existing effects:
  - Option 1: Remove old effects, apply new ones with correct amount
  - Option 2: Calculate delta and apply delta effect (relies on stacking)
  - **Recommended**: Option 1 (cleaner, more predictable)

**Removal**:
- When berserk state is cleared, remove both Power and Speed effects
- Search `character.status_effects` for AlterAttributeEffect with matching attribute_name
- Remove both effects

## Related Features

### HP Regeneration on Blackjack
- **Separate Feature**: Backlog item 07_berserker_hp_regeneration.md
- **Integration Point**: When blackjack triggers berserk state, also trigger HP regeneration
- **Implementation**: Add HP regeneration logic in same location as berserk state application

### Effect Ranges
- **Separate Feature**: Backlog item 06_berserker_effect_ranges.md
- **Integration Point**: Effect range generation is disabled while berserking
- **Implementation**: Check `is_berserking` before generating effect ranges in `apply_attack_effects()`
- **Stubbing**: The actual effect range generation logic can be stubbed for now (see section 4 above). The critical requirement is ensuring effect ranges are NOT generated when `is_berserking == true`

## Testing Considerations

### Test Scenarios
1. **Blackjack Triggers Berserk**: Score 21, verify berserk state applied with 1 stack
2. **Bust Triggers Berserk**: Bust hand, verify berserk state applied with 1 stack
3. **Stacking**: Trigger berserk multiple times, verify stacks accumulate (max 10)
4. **Attribute Bonuses**: Verify Power and Speed increase by stack count
5. **Basic Attack Clears**: Use basic attack while berserking, verify stacks cleared and effects removed
6. **Effect Range Prevention**: Verify effect ranges not generated while berserking (effect range generation itself can be stubbed - the test verifies the berserk check prevents generation)
7. **Visual Indicators**: Verify berserk state visible in UI
8. **Combat Log**: Verify berserk state entries in combat log

### Edge Cases
- Berserk state on death (status effects auto-cleared)
- Stacking beyond 10 (should cap at 10)
- Multiple berserk triggers in same turn (should stack correctly)
- Berserk state with other attribute effects (should stack additively)

## Related Files
- `scripts/class_behaviors/berserker_behavior.gd` - Berserk state management and attack effects
- `scripts/minigames/berserker_minigame.gd` - Berserk state triggering (blackjack/bust detection)
- `scripts/scenes/combat.gd` - Berserk state application from minigame results
- `scripts/data/status_effects/alter_attribute_effect.gd` - Power/Speed attribute bonuses
- `scripts/data/character.gd` - Character state and status effect system
- `ui/character_display.tscn` - Visual indicators for berserk state

## Dependencies
- **Status Effect System** (backlog item 03): Must be complete (✅ DONE)
- **AlterAttributeEffect**: Must be implemented (✅ DONE)
- **Effect Ranges** (backlog item 06): Should be aware of berserk state (integration point)
- **HP Regeneration** (backlog item 07): Related feature, can be implemented together

## Status
Pending

