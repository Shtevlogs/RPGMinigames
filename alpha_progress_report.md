# Alpha Build Progress Report

**Target**: Alpha build for external testing  
**Date**: Current Status Assessment  
**Game**: Roguelike JRPG with Minigame-Based Abilities

---

## Overview

This progress report breaks down the game's development status into 6 logical chunks, each representing a key area needed for an alpha build. Each chunk documents what's implemented, what's missing, and what's blocking alpha release.

---

## Chunk 1: Core Systems & Architecture Foundation

**Status**: ✅ Mostly Complete (85%)

### Implemented Features

#### Game State Management
- **GameManager** (`scripts/managers/game_manager.gd`): Central game state management
  - Run state tracking (`current_run: RunState`)
  - Persistent currency system (saves/loads between runs)
  - Run lifecycle signals (`run_started`, `run_ended`, `currency_changed`)
  - Currency earning on run success/failure (100/50 currency respectively)

#### Run State System
- **RunState** (`scripts/data/run_state.gd`): Complete run state tracking
  - Party management (3 characters)
  - Land progression (1-5 lands)
  - Land sequence generation (unique class lands + random + The Rift)
  - Encounter progress tracking
  - Inventory and currency tracking
  - Auto-save data dictionary
  - Full duplication support for save/load

#### Scene Management
- **SceneManager** (`scripts/managers/scene_manager.gd`): Scene transition system
  - Centralized scene paths
  - Transition data handling via StateManager
  - Convenience methods for all major scenes
  - Integration with MinigameRegistry (no match statements)

#### Class Behavior System (SOLID Architecture)
- **BaseClassBehavior** (`scripts/class_behaviors/base_class_behavior.gd`): Abstract interface
  - `needs_target_selection()` - Determines targeting requirements
  - `build_minigame_context()` - Builds class-specific context
  - `get_minigame_scene_path()` - Returns minigame scene path
  - `apply_attack_effects()` - Handles on-attack effects
  - `format_minigame_result()` - Formats result logging
  - `get_ability_target()` - Determines ability targeting

- **MinigameRegistry** (`scripts/managers/minigame_registry.gd`): Central registry pattern
  - Maps class types to behavior instances
  - Maps class types to minigame scene paths
  - All 4 classes registered (Berserker, TimeWizard, Monk, WildMage)
  - Eliminates need for match statements in combat system

- **Behavior Implementations**: All 4 classes have behavior classes
  - `BerserkerBehavior` - Handles berserk state, effect ranges
  - `TimeWizardBehavior` - Handles board state, event effects
  - `MonkBehavior` - Handles Strategy debuffs, RPS effects
  - `WildMageBehavior` - Handles pre-drawn cards

#### Turn Order System
- **Dynamic Turn Order** (`scripts/scenes/combat.gd`): Fully implemented
  - Roll-based system: `random(10-20) - speed`
  - Lower values act first
  - Turn order recalculated after each action
  - Dead combatants automatically removed
  - Visual turn order display with color coding (cyan=party, red=enemy)
  - Turn value transparency display

#### Data Structures
- **Character** (`scripts/data/character.gd`): Complete character system
  - Attributes system (Power, Skill, Strategy, Speed, Luck)
  - Health system with max HP calculation (10 + Power * 5)
  - Equipment slots integration
  - Status effects array with stacking support
  - Class-specific state dictionary
  - Effective attributes calculation (base + equipment)
  - Full duplication support

- **EnemyData** (`scripts/data/enemy_data.gd`): Enemy data structure
  - Same attribute system as characters
  - Health system
  - Enemy type categorization
  - Abilities array (structure ready)
  - Full duplication support

- **Attributes** (`scripts/data/attributes.gd`): Five-attribute system
- **Health** (`scripts/data/health.gd`): Health management
- **StatusEffect** (`scripts/data/status_effect.gd`): Status effect framework

### Missing/Incomplete Features

#### Save/Load Integration
- **Auto-save Integration**: SaveManager exists but not called during gameplay
  - `SaveManager.auto_save()` exists but never invoked
  - Should auto-save after each encounter completion
  - Should auto-save on land transitions
  - Main menu "Resume" button exists but needs testing

- **Complete State Serialization**: Save/load missing some data
  - Equipment not fully serialized/deserialized
  - Status effects not saved
  - Class-specific state (`class_state` dictionary) not saved
  - Character names may not persist correctly

#### State Management
- **StateManager**: Referenced in SceneManager but not reviewed
  - Need to verify StateManager implementation
  - Transition data handling needs validation

### Files Reviewed
- `scripts/managers/game_manager.gd` ✅
- `scripts/managers/save_manager.gd` ✅
- `scripts/managers/minigame_registry.gd` ✅
- `scripts/managers/scene_manager.gd` ✅
- `scripts/data/run_state.gd` ✅
- `scripts/data/character.gd` ✅
- `scripts/data/enemy_data.gd` ✅
- `scripts/data/attributes.gd` ✅
- `scripts/data/health.gd` ✅
- `scripts/data/status_effect.gd` ✅
- `scripts/scenes/combat.gd` (turn order system) ✅

### Blockers for Alpha
- Auto-save integration (critical for roguelike experience)
- Complete save/load state serialization (equipment, status effects, class states)

---

## Chunk 2: Combat System & Minigames

**Status**: ⚠️ Core Complete, Features Incomplete (70%)

### Implemented Features

#### Turn-Based Combat Flow
- **Combat Scene** (`scripts/scenes/combat.gd`): Complete combat loop
  - Turn order calculation and management
  - Action selection (Attack, Item, Ability)
  - Enemy turn automation
  - Encounter initialization from EncounterManager
  - Party and enemy display systems
  - Encounter completion handling
  - Land progression integration

#### All 4 Minigames Implemented
- **Berserker Minigame** (`scripts/minigames/berserker_minigame.gd`): Blackjack mechanics
  - Full 52-card deck system
  - Hand value calculation with ace handling
  - Hit/Stand mechanics
  - Blackjack detection
  - Bust detection
  - Hand value scaling for ability power

- **TimeWizard Minigame** (`scripts/minigames/time_wizard_minigame.gd`): Minesweeper analogue
  - Grid-based board system
  - Number system (minesweeper logic)
  - Event symbols (Square, Pentagon, Hexagon)
  - Time limit system
  - Board completion tracking
  - Event activation system
  - Time Burst and Mega Time Burst mechanics

- **Monk Minigame** (`scripts/minigames/monk_minigame.gd`): Rock Paper Scissors
  - Target selection before minigame
  - Enemy card generation (based on Strategy difference)
  - RPS card system (Strike/Grapple/Counter)
  - Win/Loss/Tie detection
  - Multiple card navigation
  - Redo system (Speed-based)

- **WildMage Minigame** (`scripts/minigames/wild_mage_minigame.gd`): Poker-like
  - 16-card deck (9-2, Ice/Fire suits)
  - Hand drawing system
  - Discard system (Skill/Strategy based)
  - Hand strength calculation
  - Hand type detection (High Card, Pair, Two Pair, Flush, etc.)
  - Multiplier system (1x to 5x)

#### Basic Attack System
- **Player Attacks**: Fully implemented
  - Power-based damage calculation
  - Target selection UI
  - Class-specific on-attack effects integration
  - Damage application and UI updates
  - Death handling

- **Enemy Attacks**: Fully implemented
  - Power-based damage calculation
  - AI target selection (prioritizes taunt, otherwise random)
  - Damage application and UI updates
  - Death handling
  - Party wipe detection

#### Enemy AI
- **Basic Targeting**: Implemented
  - Taunt prioritization
  - Random selection from alive party members
  - Automatic turn execution

#### Combat Log System
- **CombatLog** (`scripts/ui/combat_log.gd`): Complete logging system
  - Chronological event logging
  - Color-coded event types
  - Auto-scrolling
  - Event types: ATTACK, DAMAGE, HEALING, ABILITY, ITEM, TURN_START, DEATH

#### Turn Order Display UI
- **Visual Turn Order**: Fully implemented
  - Shows all combatants in order
  - Highlights current turn (yellow border)
  - Color coding (cyan=party, red=enemy)
  - Displays turn values
  - Updates dynamically

#### Minigame Modal System
- **MinigameModal** (`scripts/ui/minigame_modal.gd`): Modal wrapper
  - Loads minigame scenes dynamically
  - Passes context data
  - Handles result emission
  - Manages modal lifecycle

### Missing/Incomplete Features

#### Status Effect System
- **Status Effect Application**: Structure exists but not fully implemented
  - `_apply_effect()` in combat.gd is placeholder
  - Status effects not processed during combat
  - No status effect UI display
  - Status effect duration ticking not integrated into turn system
  - Burn damage not applied
  - Silence not preventing abilities
  - Taunt not fully integrated (enemy AI uses it, but application missing)

#### Berserker Minigame Features
- **Berserk State**: Tracked but not applied
  - TODO: Apply berserk state on blackjack/bust
  - TODO: HP regeneration on blackjack
  - TODO: Berserk stack management (up to 10 stacks)
  - TODO: Power/Speed bonuses from berserk stacks
  - TODO: Remove berserk stacks on basic attack (while berserking)

- **Hit Damage**: Not implemented
  - TODO: Deal damage to Berserker on each "hit"
  - TODO: Apply Luck-based damage reduction

- **Effect Ranges**: Tracked but not applied
  - TODO: Generate effect ranges from basic attacks (when not berserking)
  - TODO: Trigger effects when standing on range values
  - TODO: Target selection for effect range triggers

#### TimeWizard Minigame Features
- **Board State Persistence**: Not implemented
  - TODO: Load pre-cleared squares from basic attacks
  - TODO: Apply pre-cleared squares to board initialization
  - TODO: Track board state in class_state

- **Event Effects**: Structure exists but effects not applied
  - TODO: Apply effects based on event symbol type
  - TODO: Scale effects by board completion percentage
  - TODO: Implement different event effects (haste, slow, delay, damage)

#### Monk Minigame Features
- **Loss Damage**: Not implemented
  - TODO: Deal damage to Monk on RPS loss (reduced by Skill)
  - TODO: Apply half enemy attack damage on loss

- **Strategy Debuff**: Tracked but not applied
  - TODO: Apply temporary Strategy debuff to enemy on basic attack
  - TODO: Track debuff state on enemies

- **Equipment-Based Effects**: Stubbed
  - Win/Loss/Tie effects are empty dictionaries
  - TODO: Load effects from equipment
  - TODO: Apply effects based on equipment

#### WildMage Minigame Features
- **Pre-Drawn Card**: Tracked but not implemented
  - TODO: Store pre-drawn card from basic attacks
  - TODO: Apply pre-drawn card to next minigame
  - TODO: Reroll pre-drawn card on subsequent attacks

#### Effect Application System
- **Generic Effect Handler**: Placeholder implementation
  - `_apply_effect()` only logs, doesn't actually apply effects
  - TODO: Implement effect type routing
  - TODO: Apply attribute buffs/debuffs
  - TODO: Apply status effects
  - TODO: Apply healing/damage
  - TODO: Apply turn manipulation

#### Visual Feedback
- **Damage Feedback**: Placeholder
  - TODO: Floating damage numbers
  - TODO: Damage popup animations
  - TODO: Visual feedback for status effects
  - TODO: Ability effect animations

### Files Reviewed
- `scripts/scenes/combat.gd` ✅
- `scripts/minigames/berserker_minigame.gd` ✅
- `scripts/minigames/time_wizard_minigame.gd` ✅
- `scripts/minigames/monk_minigame.gd` ✅
- `scripts/minigames/wild_mage_minigame.gd` ✅
- `scripts/class_behaviors/berserker_behavior.gd` ✅
- `scripts/class_behaviors/time_wizard_behavior.gd` ✅
- `scripts/class_behaviors/monk_behavior.gd` ✅
- `scripts/class_behaviors/wild_mage_behavior.gd` ✅
- `scripts/data/status_effect.gd` ✅
- `scripts/ui/minigame_modal.gd` ✅
- `scripts/ui/combat_log.gd` ✅

### Blockers for Alpha
- Status effect application and processing (critical for gameplay depth)
- Complete minigame features (especially Berserker berserk state, TimeWizard events, Monk effects)
- Effect application system (abilities need to actually do things)

---

## Chunk 3: Content & Encounters

**Status**: ⚠️ Structure Complete, Content Missing (40%)

### Implemented Features

#### Encounter System Architecture
- **EncounterManager** (`scripts/managers/encounter_manager.gd`): Complete system
  - Encounter pool organization
  - Pool-based encounter selection
  - Land theme and difficulty-based pools
  - Boss encounter detection
  - Encounter duplication (prevents state mutation)

#### Encounter Data Structure
- **Encounter** (`scripts/data/encounter.gd`): Complete structure
  - Encounter types (STANDARD, BOSS, ELITE, SPECIAL, SHOP, MERCENARY)
  - Enemy composition array
  - Enemy formation (positioning)
  - Rewards system
  - Encounter pool tracking
  - Full duplication support

#### Land Sequence Generation
- **RunState.generate_land_sequence()**: Fully implemented
  - Generates sequence from party classes
  - One land per unique class
  - Fills remaining slots with random lands
  - Always ends with "The Rift"
  - Exactly 5 lands total

#### Encounter Pool System
- **Pool Organization**: Structure in place
  - Pools organized by land theme and difficulty
  - Boss pools separate from standard pools
  - Pool naming convention: `{theme}_{difficulty}` or `{theme}_boss`

#### Boss Encounter Structure
- **Boss Detection**: Implemented
  - Boss appears after 3 standard encounters per land
  - `_should_be_boss_encounter()` logic in place
  - Boss pool selection working

### Missing/Incomplete Features

#### Hand-Crafted Encounters
- **Current State**: Only placeholder encounters exist
  - Single placeholder encounter: "Two Rats" (2 rats with Power=0)
  - All encounter pools filled with placeholder encounters
  - Placeholder encounters have generic names and stats

- **Needed**: Hand-crafted encounter content
  - Unique enemy compositions per encounter
  - Themed encounters for each land type
  - Difficulty-appropriate enemy stats
  - Varied enemy formations
  - Encounter names and descriptions

#### Boss Encounters
- **Current State**: Placeholder bosses only
  - Boss encounters use same placeholder system
  - No unique boss mechanics
  - No boss-specific abilities
  - No multi-phase bosses

- **Needed**: Unique boss encounters
  - Boss-specific enemy types
  - Unique boss mechanics (per gamedoc)
  - Boss phases and health thresholds
  - Boss-specific abilities
  - 5 unique bosses (one per land, plus final boss)

#### Enemy Variety
- **Current State**: Generic placeholder enemies
  - All enemies use same stat distribution
  - No unique enemy types
  - No enemy-specific abilities
  - No enemy categorization beyond "placeholder"

- **Needed**: Diverse enemy roster
  - Multiple enemy types per land theme
  - Unique enemy abilities
  - Enemy-specific stat distributions
  - Enemy type categorization (beast, undead, etc.)
  - Themed enemies matching land themes

#### Encounter Variety
- **Current State**: All encounters are combat-only
  - No special encounter types
  - No shops
  - No mercenary outposts
  - No branching paths

- **Needed**: Encounter type variety
  - Shop encounters (purchase items/equipment)
  - Mercenary outpost encounters (swap/buy characters)
  - Special encounters (rewards, choices, events)
  - Elite encounters (harder than standard)

#### Rewards Implementation
- **Current State**: Rewards structure exists but not used
  - Rewards added to encounters but empty
  - Rewards applied in combat but no items/equipment given
  - No reward selection UI

- **Needed**: Complete rewards system
  - Item rewards from encounters
  - Equipment rewards from encounters
  - Currency rewards (working)
  - Reward selection UI (if multiple options)
  - Boss-specific rewards

#### Branching Path System
- **Current State**: Structure exists but not implemented
  - Land screen has route selection mentioned in gamedoc
  - No branching logic in EncounterManager
  - No path choice UI

- **Needed**: Branching path implementation
  - Multiple encounter options per land
  - Path selection UI on land screen
  - Path convergence logic
  - Path-specific encounters

#### Difficulty Scaling
- **Current State**: Basic difficulty tracking
  - Land number used for difficulty
  - Enemy stats scale with difficulty in placeholders
  - No fine-tuned difficulty curves

- **Needed**: Refined difficulty scaling
  - Per-encounter difficulty tuning
  - Enemy stat scaling formulas
  - Encounter difficulty ratings
  - Balanced progression curve

### Files Reviewed
- `scripts/managers/encounter_manager.gd` ✅
- `scripts/data/encounter.gd` ✅
- `scripts/data/enemy_data.gd` ✅
- `scripts/data/rewards.gd` ✅

### Blockers for Alpha
- Hand-crafted encounters (critical - players need content to test)
- At least 1-2 unique boss encounters (to test boss mechanics)
- Basic enemy variety (at least 3-5 enemy types)
- Rewards system implementation (players need progression)

---

## Chunk 4: Items, Equipment & Progression

**Status**: ⚠️ Data Structures Exist, Systems Incomplete (35%)

### Implemented Features

#### Item Data Structure
- **Item** (`scripts/data/item.gd`): Complete structure
  - Item types (HEALING, BUFF, DEBUFF, UTILITY)
  - Item ID and name
  - Combat-only flag
  - Effects dictionary (structure ready)
  - Full duplication support

#### Equipment Data Structure
- **Equipment** (`scripts/data/equipment.gd`): Complete structure
  - Equipment ID and name
  - Slot type system
  - Attribute bonuses (Attributes object)
  - Special effects dictionary (structure ready)
  - Full duplication support

#### Equipment Slots System
- **EquipmentSlots** (`scripts/data/equipment_slots.gd`): Complete system
  - Ring slots (2)
  - Neck slot (1)
  - Armor slot (1)
  - Head slot (1)
  - Class-specific slots (1-2, class-dependent)
  - Total attribute bonus calculation
  - Full duplication support

#### Inventory System
- **RunState.inventory**: Basic structure
  - Array of Items in RunState
  - Items added from rewards
  - Inventory persists between encounters

#### Equipment Integration
- **Character.equipment**: Integrated into characters
  - Equipment slots on each character
  - Effective attributes calculation includes equipment bonuses
  - Equipment duplication in character duplication

### Missing/Incomplete Features

#### Item Usage System
- **Combat Item Usage**: Placeholder only
  - Item button exists in combat UI
  - `_on_item_pressed()` only logs, doesn't actually use items
  - TODO: Item selection UI
  - TODO: Item targeting (self, ally, enemy)
  - TODO: Item effect application
  - TODO: Item consumption
  - TODO: Combat-only item restrictions

- **Between-Encounter Item Usage**: Not implemented
  - Land screen has no item usage UI
  - TODO: Item usage interface on land screen
  - TODO: Item selection and targeting
  - TODO: Item effect application outside combat
  - TODO: Combat-only item restrictions

#### Item Effects Implementation
- **Effect Application**: Structure exists but not implemented
  - Item.effects dictionary is empty
  - TODO: Healing item effects (single target, party-wide, percentage, fixed)
  - TODO: Buff item effects (attribute increases, temporary)
  - TODO: Debuff item effects (enemy attribute reduction)
  - TODO: Utility item effects (status cures, immunities)
  - TODO: Effect duration tracking

#### Equipment Equipping/Unequipping
- **Equipment Management**: Not implemented
  - No UI for equipping/unequipping
  - No logic for slot validation
  - No equipment swapping
  - TODO: Equipment UI on land screen
  - TODO: Equipment slot validation
  - TODO: Equipment swapping logic
  - TODO: Equipment removal

#### Equipment Effects on Minigames
- **Equipment Integration**: Not implemented
  - Equipment special_effects dictionary exists but unused
  - TODO: Equipment effects on Berserker (effect ranges, berserk modifications)
  - TODO: Equipment effects on TimeWizard (board size, event effects)
  - TODO: Equipment effects on Monk (RPS card effects)
  - TODO: Equipment effects on WildMage (hand modifications)
  - TODO: Equipment effect application in minigames

#### Equipment Acquisition
- **Rewards Integration**: Not implemented
  - Rewards.equipment array exists but not used
  - Equipment not added to inventory from encounters
  - TODO: Equipment rewards from encounters
  - TODO: Equipment rewards from bosses
  - TODO: Equipment selection UI (if multiple options)

#### Inventory Management
- **Inventory UI**: Not implemented
  - No inventory display
  - No inventory management
  - TODO: Inventory view on land screen
  - TODO: Item stacking logic
  - TODO: Inventory size limits
  - TODO: Item organization/sorting

#### Item Acquisition
- **Item Rewards**: Partially implemented
  - Items added to RunState.inventory from rewards
  - But rewards are currently empty
  - TODO: Item rewards from encounters
  - TODO: Item rewards from bosses
  - TODO: Item purchase from shops (when shops implemented)

### Files Reviewed
- `scripts/data/item.gd` ✅
- `scripts/data/equipment.gd` ✅
- `scripts/data/equipment_slots.gd` ✅
- `scripts/scenes/combat.gd` (item action) ✅
- `scripts/scenes/land_screen.gd` ✅

### Blockers for Alpha
- Basic item usage system (at least healing items for testing)
- Equipment equipping UI (players need to test equipment system)
- Item effects implementation (items need to actually work)
- Equipment acquisition from rewards (progression needs to work)

---

## Chunk 5: UI/UX & Land Screen Features

**Status**: ⚠️ Basic UI Complete, Advanced Features Missing (50%)

### Implemented Features

#### Main Menu
- **MainMenu** (`scripts/scenes/main_menu.gd`): Basic implementation
  - New Run button (functional)
  - Resume button (functional, checks for save)
  - Settings button (placeholder)
  - Save detection for resume button

#### Party Selection Screen
- **PartySelection** (`scripts/scenes/party_selection.gd`): Complete implementation
  - Random character generation (6 options)
  - Character selection (up to 3)
  - Selection UI with toggle buttons
  - Confirm button (disabled until 3 selected)
  - Reroll button (generates new selection)
  - All 4 classes available

#### Combat UI
- **Turn Order Display**: Fully implemented
  - Visual turn order at top of screen
  - Current turn highlighting
  - Color coding (cyan=party, red=enemy)
  - Turn value display
  - Dynamic updates

- **Combat Log**: Fully implemented
  - Scrolling text log
  - Color-coded event types
  - Auto-scrolling to latest
  - Chronological event tracking

- **Character Displays**: Implemented
  - **CharacterDisplay** (`scripts/ui/character_display.gd`): Party member UI
    - Name display
    - Health bar
    - Attributes display (P/S/St/Sp/L)
    - Real-time updates

- **Enemy Displays**: Implemented
  - **EnemyDisplay** (`scripts/ui/enemy_display.tscn`): Enemy UI
    - Enemy name
    - Health display
    - Clickable for target selection
    - Visual feedback for selection

- **Action Buttons**: Implemented
  - Attack button (functional)
  - Item button (placeholder)
  - Ability button (functional)
  - Win button (testing/debug)

#### Basic Land Screen
- **LandScreen** (`scripts/scenes/land_screen.gd`): Basic implementation
  - Land information display
  - Encounter progress display
  - Party information display (basic)
  - Continue button (functional)
  - Land progression logic

### Missing/Incomplete Features

#### Land Screen Features
- **Party Management UI**: Not implemented
  - TODO: Detailed party member view
  - TODO: Character stat display
  - TODO: Equipment view per character
  - TODO: Status effect display

- **Item Usage Interface**: Not implemented
  - TODO: Inventory display
  - TODO: Item selection UI
  - TODO: Item usage targeting
  - TODO: Item effect preview

- **Route/Encounter Selection**: Not implemented
  - TODO: Branching path display
  - TODO: Path selection UI
  - TODO: Encounter preview
  - TODO: Path information (rewards, difficulty hints)

- **Inventory Management**: Not implemented
  - TODO: Inventory list view
  - TODO: Item details display
  - TODO: Item organization
  - TODO: Item stacking display

#### Equipment Management UI
- **Equipment Interface**: Not implemented
  - TODO: Equipment slot display
  - TODO: Equipment list (available to equip)
  - TODO: Equipment comparison (current vs. new)
  - TODO: Equipment tooltips
  - TODO: Equip/unequip buttons

#### Visual Polish
- **Damage Feedback**: Not implemented
  - TODO: Floating damage numbers
  - TODO: Damage popup animations
  - TODO: Color-coded damage (physical, magical, etc.)

- **Animations**: Not implemented
  - TODO: Attack animations
  - TODO: Ability cast animations
  - TODO: Death animations
  - TODO: Status effect visual indicators

- **Visual Feedback**: Basic only
  - TODO: Better target selection highlighting
  - TODO: Ability range indicators
  - TODO: Status effect icons
  - TODO: Buff/debuff visual indicators

#### Special Encounter UIs
- **Shop UI**: Not implemented
  - TODO: Shop interface
  - TODO: Item/equipment purchase UI
  - TODO: Currency display
  - TODO: Purchase confirmation

- **Mercenary Outpost UI**: Not implemented
  - TODO: Available adventurers display
  - TODO: Character comparison UI
  - TODO: Swap/replace interface
  - TODO: Purchase with currency

#### Settings Menu
- **Settings**: Placeholder only
  - TODO: Settings screen
  - TODO: Audio settings
  - TODO: Graphics settings
  - TODO: Controls settings

### Files Reviewed
- `scripts/scenes/main_menu.gd` ✅
- `scripts/scenes/party_selection.gd` ✅
- `scripts/scenes/land_screen.gd` ✅
- `scripts/ui/character_display.gd` ✅
- `scripts/ui/enemy_display.gd` ✅
- `scripts/ui/combat_log.gd` ✅
- `scripts/ui/minigame_modal.gd` ✅

### Blockers for Alpha
- Land screen party management UI (players need to see/manage party)
- Item usage interface (at least basic healing item usage)
- Equipment management UI (players need to equip items)
- Basic visual feedback improvements (damage numbers, status indicators)

---

## Chunk 6: Meta-Progression & Run Completion

**Status**: ⚠️ Basic Structure Exists, Features Incomplete (45%)

### Implemented Features

#### Currency System
- **Persistent Currency**: Fully implemented
  - Currency persists between runs (saved to file)
  - Currency earned on run success (100) and failure (50)
  - Currency saved/loaded automatically
  - Currency changed signal emitted

#### Run Completion/Failure Handling
- **Run Lifecycle**: Implemented
  - `GameManager.start_new_run()` - Initializes run
  - `GameManager.end_run(success: bool)` - Ends run, awards currency
  - Run state cleared on completion
  - Signals emitted for run events

#### Party Wipe Detection
- **Wipe Handling**: Implemented
  - `_is_party_wipe()` checks all party members
  - `_handle_party_wipe()` triggers run failure
  - Transitions to main menu on wipe
  - Run ended with success=false

#### Save/Load Infrastructure
- **SaveManager**: Complete system exists
  - Auto-save functionality
  - Save file management
  - Serialization/deserialization
  - Save detection (`has_auto_save()`)

#### Main Menu Resume
- **Continue Run**: Implemented
  - Resume button checks for save
  - Loads auto-save on resume
  - Transitions to combat scene
  - Button disabled if no save exists

### Missing/Incomplete Features

#### Item Carryover on Run Failure
- **Item Selection**: Not implemented
  - TODO: Item selection UI on run failure
  - TODO: Choose one item to carry over
  - TODO: Save selected item to next run
  - TODO: Apply carried-over item to new run start

#### Currency Spending
- **Currency Usage**: Not implemented
  - TODO: Reroll character selection (spend currency)
  - TODO: Purchase characters at mercenary outposts
  - TODO: Currency display in relevant UIs
  - TODO: Currency cost validation

#### Mercenary Outpost Implementation
- **Outpost System**: Not implemented
  - TODO: Mercenary outpost encounter type
  - TODO: Available adventurers generation
  - TODO: Character pricing system (based on stats/equipment)
  - TODO: Swap character logic
  - TODO: Replace dead character logic
  - TODO: Zero-cost adventurer option (when currency low)

#### Run Completion Rewards
- **Completion Rewards**: Not implemented
  - TODO: Bonus currency on run completion
  - TODO: Completion statistics
  - TODO: Victory screen
  - TODO: Completion time tracking

#### Statistics Tracking
- **Statistics System**: Not implemented
  - TODO: Run statistics (encounters completed, enemies defeated)
  - TODO: Minigame success rates
  - TODO: Class usage statistics
  - TODO: Statistics persistence
  - TODO: Statistics display (future)

#### Auto-Save Integration
- **Auto-Save Calls**: Not implemented
  - TODO: Auto-save after each encounter
  - TODO: Auto-save on land transitions
  - TODO: Auto-save on party state changes
  - TODO: Auto-save deletion on run completion/failure

#### Run Failure Flow
- **Failure UI**: Not implemented
  - TODO: Failure screen
  - TODO: Item carryover selection UI
  - TODO: Statistics display on failure
  - TODO: Return to main menu flow

### Files Reviewed
- `scripts/managers/game_manager.gd` ✅
- `scripts/managers/save_manager.gd` ✅
- `scripts/scenes/main_menu.gd` ✅
- `scripts/scenes/combat.gd` (party wipe handling) ✅

### Blockers for Alpha
- Auto-save integration (critical for roguelike experience)
- Item carryover on failure (core roguelike feature)
- Basic currency spending (rerolls at minimum)
- Run completion/failure UI (players need feedback)

---

## Overall Alpha Readiness Assessment

### Completion Summary
- **Chunk 1 (Core Systems)**: 85% - Mostly complete, needs save integration
- **Chunk 2 (Combat & Minigames)**: 70% - Core works, features incomplete
- **Chunk 3 (Content)**: 40% - Structure ready, content missing
- **Chunk 4 (Items/Equipment)**: 35% - Data structures exist, systems missing
- **Chunk 5 (UI/UX)**: 50% - Basic UI works, advanced features missing
- **Chunk 6 (Meta-Progression)**: 45% - Basic structure, features incomplete

### Critical Blockers for Alpha
1. **Content Creation** (Chunk 3)
   - Need hand-crafted encounters (at least 10-15 unique encounters)
   - Need at least 2-3 unique boss encounters
   - Need basic enemy variety (5-10 enemy types)

2. **Minigame Feature Completion** (Chunk 2)
   - Status effect system must work
   - Core minigame features (berserk state, event effects, etc.)
   - Effect application system

3. **Save/Load Integration** (Chunk 1 & 6)
   - Auto-save must work during gameplay
   - Complete state serialization
   - Resume functionality must be reliable

4. **Basic Item/Equipment Systems** (Chunk 4)
   - At minimum: healing items must work
   - Equipment equipping UI needed
   - Basic equipment acquisition

5. **Land Screen Features** (Chunk 5)
   - Party management view
   - Item usage interface
   - Equipment management

### Recommended Alpha Scope
For a testable alpha build, focus on:
- **Core gameplay loop**: Combat → Land Screen → Combat (working)
- **All 4 classes playable**: Minigames functional (even if features incomplete)
- **Basic content**: 10-15 encounters, 2-3 bosses
- **Basic progression**: Items work, equipment can be equipped
- **Save/load**: Auto-save works, runs can be resumed
- **Polish**: Basic UI complete, visual feedback adequate

### Nice-to-Have (Can Skip for Alpha)
- Mercenary outposts
- Shops
- Branching paths
- Advanced statistics
- Settings menu
- Advanced visual polish

---

## Next Steps

1. **Priority 1**: Complete Chunk 3 (Content) - Create hand-crafted encounters
2. **Priority 2**: Complete Chunk 2 missing features (Status effects, minigame features)
3. **Priority 3**: Integrate save/load (Chunk 1 & 6)
4. **Priority 4**: Implement basic item/equipment systems (Chunk 4)
5. **Priority 5**: Complete land screen features (Chunk 5)

Each chunk can be worked on independently, making parallel development possible.

