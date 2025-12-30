# Game Design Document

## 1. Game Overview

### High-Level Concept
A roguelike JRPG where players control a party of three adventurers through hand-crafted encounters. The core twist is that each character class has unique abilities that are resolved through themed minigames based on classic games (poker, minesweeper, rock paper scissors, etc.).

### Genre
- **Primary**: Roguelike
- **Secondary**: Turn-based JRPG
- **Unique Mechanic**: Minigame-based ability resolution

### Core Gameplay Loop
1. **Party Selection**: Choose three characters from available classes (Final Fantasy 1 style)
2. **Encounter Flow**: Progress through a series of hand-crafted encounters along a lightly branching path
3. **Combat**: Engage in turn-based JRPG combat with standard actions (Attack, Item, Spell/Ability)
4. **Ability Resolution**: When using abilities, play the character's unique minigame to determine effectiveness
5. **Progression**: Advance through encounters, managing resources and party health
6. **Run Completion/Failure**: Either complete the run or restart on failure (roguelike permadeath)

### Target Experience
- Strategic party composition and resource management
- Skill-based ability execution through minigames
- Replayability through hand-crafted encounters and branching paths
- Nostalgic connection to classic games through minigame theming

---

## 2. Core Mechanics

### Party System
- **Party Size**: Starts at 3 characters, but can be less if a character dies mid-run
- **Character Selection**: Choose classes from a random rerollable selection at the start of each run
  - Players can reroll the selection to see different class options
  - Same rerollable system used at mercenary outposts
  - Purchased characters will be more expensive based on their default stats and equipment
  - Characters chosen will scale throughout a run:
    - Initial party creation: Low stats and sparse equipment
    - Mercenary outposts: Scaling stats and equipment (better characters available as run progresses)
- **Party Management**: All party members participate in every encounter
- **Character Swapping/Replacement**: Players may encounter mercenary outposts that allow them to:
  - Swap characters (replace a living party member with a different class)
  - Replace party members that died earlier in the run
  - Choose from a random rerollable selection of available adventurers
- **Character Roles**: Different classes will favor different roles (damage, support, utility, etc.)
  - Equipment may/will greatly change how each class fits into the party
  - A class that typically fills one role may be built differently through equipment to fill another role

### Encounter Structure
- **No Overworld**: The game consists entirely of encounters - no exploration or movement between areas
- **Run Structure**: Each run is divided into 5 "lands"
  - One land themed after each unique class chosen in the party
  - The last land is always "The Rift" (final boss section)
  - Remaining lands are randomly chosen from other available lands
  - Example: Party with 3 unique classes = 3 class-themed lands + 1 random land + The Rift
  - Bosses appear at the end of each land

**Land System Details:**
- **Land Themes**: Each land is themed after a character class
  - Class-themed lands feature encounters that emphasize that class's mechanics
  - Enemy types and compositions in class-themed lands relate to the class theme
  - Encounter pools for class-themed lands are curated to showcase that class's strengths and challenges
- **Land Progression**: Lands progress in difficulty and complexity
  - Early lands: Introduce basic mechanics and lower difficulty
  - Mid lands: Increase difficulty and introduce more complex encounters
  - Final land (The Rift): Highest difficulty with the final boss
- **Land and Party Composition**: Class-themed lands relate directly to party composition
  - If a party member's class matches a land theme, that land's encounters may be easier or more rewarding
  - Class-themed lands provide opportunities to showcase that class's unique abilities
  - Players may need to adapt strategies based on which class-themed lands appear in their run
- **Land and Encounter Pools**: Each land has its own encounter pool
  - Encounter pools are organized by land theme and difficulty level
  - Class-themed lands draw from pools specific to that class theme
  - Random lands draw from general encounter pools
  - The Rift has its own unique encounter pool with final boss encounters
- **Land Screen**: Between encounters, players access a "Land" screen that provides party management, item usage, and route/encounter selection
  - **Party Management**: Players can view party status, swap equipment, and manage character loadouts
  - **Item Usage**: Players can use items from their inventory to heal, buff, or prepare for upcoming encounters
  - **Route/Encounter Selection**: Players choose which path to take when branching options are available, selecting the next encounter from available routes
  - **Strategic Planning**: The Land screen serves as the primary hub for preparation and decision-making between encounters

- **Hand-Crafted Encounters**: Encounters are selected from a pool of hand-crafted encounters, providing variety in enemy composition, difficulty, and rewards
- **Branching Path**: Light branching structure - players may choose between different encounter paths at certain points
- **Encounter Types**: 
  - Standard combat encounters
  - Boss encounters (at path milestones)
  - Special encounters (rewards, choices, etc.)
  - Shops (purchase items, equipment, etc.)
  - Mercenary outposts (buy/swap characters)

### Progression Model
- **Linear with Branching**: Follow a path of encounters with occasional choice points
- **Encounter-to-Encounter**: Direct transition between encounters via the Land screen
- **Land Screen**: Between encounters, players access the Land screen for party management, item usage, and route/encounter selection
- **Resource Persistence**: Health, items, and party state carry between encounters
- **Run-Based**: Each playthrough is a complete run from start to finish

### Attributes
- **Five Attributes**: All characters have five attributes that affect gameplay
  - **Power**: Increases health and basic attack damage
  - **Skill**: Affects class-specific minigame performance
  - **Strategy**: Affects class-specific minigame performance
  - **Speed**: Reduces time between turns
  - **Luck**: Affects class-specific minigame performance
- **Attribute Range**: Attributes can range from 0 to 10
- **Default Values**: All attributes default to 1 at the start of a run
- **Class-Specific Interactions**: Different classes interact with attributes differently
  - Some classes may heavily rely on certain attributes (e.g., Skill for Monk, Strategy for Time Wizard)
  - Some classes may not care about certain attributes at all
  - Each class's minigame mechanics determine which attributes matter
- **Universal Attributes**: Power and Speed are the only attributes with effects outside of class-specific minigames
  - **Power**: Directly affects all characters' health and basic attack damage
  - **Speed**: Directly affects all characters' turn frequency

---

## 3. Combat System

### Turn-Based Foundation
- **Turn Order**: Determined by a random roll (10-20) minus the combatant's Speed stat
  - Lower numbers go first
  - After each turn, a new roll is added to determine when that combatant's next turn will be
  - Creates dynamic turn order where faster characters act more frequently
- **Action Selection**: Each character selects an action on their turn
- **Action Resolution**: Actions execute in turn order

### Battle Start and Initialization
- **Encounter Introduction**: When battle starts, there is a beat (configurable delay) to set the scene
  - Encounter message is displayed (thematic string from encounter data, e.g., "A gaggle of rats" or "An evil priest and his buddies")
  - Sound cue plays to signal battle start
  - Visual setup of combat scene occurs during this beat
- **Initiative Roll**: After the initial beat, initiatives are rolled for all combatants
  - Turn order is calculated and displayed
  - For alpha, turn order is shown directly (animation for initiative roll is a nice-to-have for future)
  - Turn order display shows all combatants in order of their next action
- **Battle Progression**: After turn order is determined, battle proceeds turn-by-turn

### Turn Highlighting and Visual Feedback
- **Enemy Highlighting**: When an enemy's turn starts, they are highlighted with a glow effect behind their sprite
  - Glow is slightly larger than the sprite size
  - Highlighting is temporary (fades out once action begins)
- **Party Member Highlighting**: When a party member's turn starts, they are highlighted with a border around their display
  - Highlighting persists for the entire turn (until action is completed)
  - Provides clear visual indication of whose turn it is
- **Selection Arrow**: When target selection is needed, an animated arrow appears
  - Arrow animates between selections (slightly above enemies or party member UI)
  - Arrow movement takes a beat (small travel time between selections)
  - Arrow disappears once selection is made
  - Provides secondary visual feedback for target selection state

### Basic Actions
All characters have access to these standard actions:
- **Attack**: Basic physical attack, no minigame required
- **Item**: Use consumable items (healing, buffs, etc.)
- **Spell/Ability**: Class-specific abilities that trigger minigames

### Enemy Turn Behavior
- **Turn Start**: When an enemy's turn begins, they are highlighted and lightly animate (wiggle animation) for a beat
  - Animation signifies the enemy is taking action
  - Provides visual feedback before action resolution
- **Action Execution**: After the animation beat, the enemy's action (attack, spell, item, etc.) occurs
  - Action system is flexible enough to support wind-up messages (future feature)
  - For alpha, enemies use a single 'action' animation (light wiggle)
  - Equipment-based VFX variations: Certain party equipment may change visual effects (e.g., Wild Mage's Flame Sword creates fire splash instead of physical damage slash)
- **Action Resolution**: After action completes, battle progresses to the next turn
  - Attack animations must finish before next turn can begin (sequential logic requirement)

### Party Member Action Selection
- **Action Menu Appearance**: When a party member's turn starts, an action menu slides in to a fixed location
  - Menu appears after the turn highlighting beat
  - Slide-in animation provides smooth UI transition
- **Action Options**: Menu displays three standard actions:
  - **Attack**: Basic physical attack
  - **Spell/Ability**: Class-specific ability (triggers minigame)
  - **Item**: Use consumable items
- **Menu Interaction**: 
  - Highlighting different options plays sound cues
  - Changing selected option takes a beat (small delay for feedback)
  - Sound cues provide audio feedback for menu navigation
- **Silence Interaction**: If a party member is silenced, the Spell/Ability option remains available
  - Minigame will be harder in class-specific ways (see Status Effects section for details)
  - Option is not disabled or hidden, maintaining consistent UI
- **Item Option**: Shows empty list if character has no items (no special disabled state needed)

### Target Selection Mechanics
- **Attack Target Selection**: When Attack is selected:
  - Other party member displays animate down
  - Action menu closes
  - Player can highlight enemies to attack
  - Each time a new enemy is highlighted:
    - Light sound cue plays
    - Selection arrow moves to target the selected entity (movement takes a beat)
  - If attack is canceled (right-click or cancel button):
    - Party member displays return to normal (over a small beat)
    - Action menu reopens
- **Ability Target Selection**: When Spell/Ability is selected and target selection is required:
  - Similar process to attack target selection
  - Party member displays animate down, action menu closes
  - Target selection occurs before minigame opens (for classes that require it)
  - No cancel option during ability target selection (must complete selection)
- **Target Selection Method**: For alpha, focus on mouse-based selection
  - Click directly on entities to select them
  - Keyboard/arrow key selection is a future consideration
- **Dead Entity Handling**:
  - Dead enemies vanish (not selectable)
  - Dead party members remain visible but greyed out
  - Dead party members can be selected for revive actions (items or abilities)
  - Invalid targets (dead party members for non-revive actions) are greyed out and unselectable
- **Visual Feedback**: Consistent highlighting and arrow system for all target selection
  - Selected entity receives highlight (enemy glow or party border)
  - Selection arrow animates to target position
  - Dead party members maintain greyed state even when selected for revives

### Ability Resolution Through Minigames
- **Trigger**: When a character uses a Spell/Ability action, their unique minigame launches
- **Targeting**: Different classes handle targeting differently:
  - **Monk**: Must choose target BEFORE starting minigame
  - **Time Wizard**: Choose primary target BEFORE starting minigame
    - Some effects will hit all enemies
    - Some effects will hit all allies
    - No re-targeting required after minigame completion
  - **Wild Mage**: Effects always impact all enemies and/or all allies
    - No targeting selection needed
  - **Berserker**: No targeting needed unless they "stand"
    - When standing, targeting strategy is chosen based on what effect (if any) is triggered at that score
- **Minigame Opening**: When minigame is triggered:
  - Party member displays animate down (if not already)
  - Action menu closes
  - Minigame modal slides in on top of all combat UI elements
  - Combat background remains the same
  - Combat UI elements stay in place (may add shadow element to pull focus)
  - Minigame must fully open before any player actions are accepted (sequential logic requirement)
- **Minigame State Maintenance**: 
  - If target selection is needed mid-minigame, minigame closes (but maintains state)
  - Target selection process occurs (similar to attack target selection, no cancel option)
  - Minigame may re-open after target selection (though this is fairly unlikely)
  - If minigame doesn't need to re-open, state is cleaned up while animation plays
- **Minigame Execution**: 
  - Each action taken in minigames has action-specific timing, sound, and possibly motion
  - Combat is effectively paused for the duration (no interruptions during player's turn)
  - Minigames are not timed by combat (unless the minigame itself has timing)
- **Minigame Closing**: After minigame is fully resolved:
  - Minigame animates closed (if still open)
  - Minigame effect occurs (visual effect, sound effect, animation)
  - After a beat, battle progresses to the next turn
- **Performance Impact**: Minigame performance directly affects ability effectiveness
  - Better performance = stronger effect (more damage, better healing, longer duration, etc.)
  - Poor performance = weaker effect or potential failure
- **Result Previews**: Class-specific UI elements show minigame effects before they occur:
  - **Berserker**: Active effect ranges displayed in horizontal list above party UI
    - Visible when Berserker's turn is active
    - Brief display when new effect is added (if not already visible)
    - Shows brief descriptions (e.g., 'fire damage' or 'silence')
    - When minigame opens, shows full details including actual target score ranges
    - Separate element tied to Berserker's party UI
  - **Wild Mage**: Effects added to different hand types by equipment
    - Icons may change (e.g., fire sword changes suit symbol to fire symbols)
    - Effects listed under hand types
    - Brief descriptions with tooltip support for details
  - **Time Wizard**: Equipment-driven effects displayed
    - Effects shown based on event symbols and equipment
    - All effects visible, actual effects change based on equipment
  - **Monk**: Effects listed in brief under each opponent's card
    - Shows condition (win/loss/tie) alongside effect description
    - Tooltip support for detailed descriptions
  - **Tooltip System**: Consistent tooltip UI across all classes for detailed effect descriptions
    - Brief descriptions visible by default
    - Hover reveals more detailed information

### Death and State Transitions
- **Enemy Death**: When an enemy reaches 0 HP or below:
  - Death animation plays
  - Sound effect plays
  - Visual effect may occur (VFX)
  - After a beat, combat resumes if enemies remain
  - Dead enemies vanish (removed from combat)
- **Party Member Death**: When a party member reaches 0 HP or below:
  - Death animation plays
  - Sound effect plays
  - Party member display greys out (remains visible)
  - After a beat, combat resumes if party members remain
  - Dead party members remain visible but greyed out for remainder of combat (unless revived)
- **Simultaneous Deaths**: If multiple entities die in quick succession (e.g., from AoE attack):
  - Death animations play simultaneously (not sequentially)
  - All death effects occur in parallel
- **Turn Order Impact**: 
  - Dead party members are removed from turn order (after death animation)
  - Turn order display reflows to show current order
  - Dead enemies are removed from turn order immediately
- **UI Persistence**: Dead party member displays remain visible and greyed out
  - Can be selected for revive actions (items or abilities)
  - Visual state persists until revival or combat end

### Victory and Defeat
- **Victory Condition**: When all enemies are defeated:
  - Victory message animates in
  - After a beat, rewards are displayed in a list
  - Rewards sorted by type: Equipment (rare first), then consumables
  - Rewards include: items, equipment, currency (experience not applicable)
  - After player confirms rewards, screen fades back to land screen
- **Defeat Condition**: When all party members are defeated:
  - Defeat message animates in
  - After a beat, run statistics are shown
  - Statistics display combat performance and run details
  - After player confirms statistics, screen fades back to main menu
  - Run conclusion logic takes place (item carryover, currency rewards, etc.)

### Turn Order and Initiative
- **Dynamic Turn Order**: Turn order is recalculated after each action using the roll system
  - After new speed roll determines turn order, display animates to show updated order
  - Turn order updates dynamically as turns progress
- **Speed Impact**: Higher Speed stat means lower roll results (faster turns) and more frequent actions
- **Ability Timing**: Minigames occur during the character's turn, pausing the combat flow
- **No Time Pressure**: Minigames are not timed by combat (unless the minigame itself has timing)
- **Dead Party Member Removal**: Dead party members are removed from turn order
  - Turn order display reflows to show current order after removal
  - Removal occurs after death animation completes
- **Revived Member Rejoin**: When a party member is revived:
  - Starting speed is calculated as: current active entity speed + typical turn speed roll
  - Revived member is added back to turn order
  - Turn order display animates to show updated order

### Combat UI and Feedback
- **Turn Order Display**: Visual representation of upcoming turns at the top of the combat screen
  - Shows all combatants in order of their next action
  - Highlights current turn with visual indicator
  - Color-coded by party (cyan) vs enemy (red) for quick identification
  - Displays turn values for transparency in turn order calculation
  - Updates dynamically as turns progress and new actions are taken
- **Combat Log**: Scrolling text log of combat events
  - Chronological record of all combat actions during the encounter
  - Includes damage dealt, healing received, status effect applications, deaths, ability usage, and item usage
  - Helps players track complex combat sequences and understand what happened
  - Auto-scrolls to show most recent events
  - Color-coded entries for different event types (damage, healing, status effects, etc.)
  - Provides detailed feedback beyond visual indicators like health bars and floating damage numbers

### Basic Attack Synergy
- **Core Principle**: Basic attacks enhance class-specific abilities rather than being separate from them
- **Design Goal**: Encourages mixing basic attacks with abilities rather than spamming abilities
- **Class-Specific Mechanics**: Each class has unique ways that basic attacks interact with their minigame
  - These interactions are detailed in each class's "On-Attack Effects" section
- **Strategic Depth**: Players must balance when to use basic attacks vs. abilities for optimal performance

### Timing and Pacing System
- **Beat System**: Configurable delay durations used throughout combat
  - Some beats stored as constants (e.g., `ACTION_MENU_BEAT_DURATION`, `MINIGAME_OPEN_BEAT_DURATION`)
  - Other beats depend on animation length (animation-driven timing)
  - Provides consistent pacing and visual rhythm to combat
- **Sequential vs Overlapping Events**: 
  - Some events are sequential (must complete before next begins):
    - Minigame must fully open before player actions are accepted
    - Attack animations must finish before next turn can start
    - Turn order must be determined before turn can begin
  - Some events can overlap:
    - Sound effects can play while animations are completing
    - Visual effects can occur simultaneously with animations
    - Multiple death animations can play simultaneously
- **Input Blocking**: Input is blocked/ignored during delays and animations
  - No skipping or acceleration needed (animations designed to be snappy)
  - Prevents player interaction during critical state transitions
  - Ensures proper sequencing of combat logic
- **Animation Completion Detection**: System tracks when animations complete
  - Used to coordinate sequential events
  - Ensures proper timing of state transitions
  - Supports delay-based timing system architecture

### Technical Systems

#### Battle State Manager
- **Purpose**: Maintains complete battle state snapshot as source of truth
- **Data Structure**: Clean, straightforward data structure representing:
  - Current turn order and whose turn it is
  - All entity states (HP, status effects, positions)
  - Minigame-specific state (if any)
  - Initiative values and turn calculations
- **Serialization**: Battle state is easily serializable for auto-save
  - Full snapshot saved after turn order is determined
  - Accessible to all systems as authoritative state
- **Entity Lifecycle**: Manages entity lifecycle events:
  - Death and removal from turn order
  - Revival and rejoin to turn order
  - Status effect application and removal
- **Accessibility**: Battle state structure is simple and accessible
  - Used as source of truth by all combat systems
  - Enables consistent state management across systems

#### VFX Manager
- **Architecture**: Centralized VFX system using registry pattern
- **Effect Registry**: Effects registered by ID using `EffectIds` enum
  - Effect IDs passed to manager when requesting effects
  - Similar pattern to MinigameRegistry for consistency
- **Node Pooling**: Maintains pool of ~10 deactivated VFX nodes
  - Nodes accessed as needed from pool
  - If pool is exhausted, greedily reuses longest-active VFX node
  - Efficient resource management for visual effects
- **Effect Parameters**: Effects take position and config object
  - Position: Location to center the effect at (world-space)
  - Config object: Additional parameters (scale, color, etc.)
  - Keeps parameter passing tidy and extensible
- **World-Space Effects**: Effects are world-space, don't attach to entities
  - Effects placed at specific positions
  - No need for entity following or attachment
  - Simplifies effect lifecycle management

#### Sound Manager
- **Architecture**: Centralized sound system for BGM and SFX
- **Track Management**: For alpha, single background track and single SFX track
  - Simple implementation suitable for alpha release
  - May remain single-track for full release
- **Interface**: Simple interface for playing sounds
  - Call manager to play sound effect
  - Call manager to change background music
  - Clean separation from combat logic
- **Synchronization**: SFX and VFX synchronization handled by design, not code
  - Effects and sounds triggered at same time
  - Visual/audio design ensures proper sync
  - No complex timing coordination needed in code

#### Auto-Save System
- **Timing**: Auto-saves occur just after turn order is determined
  - Happens at every player and enemy turn
  - Ensures battle state is preserved at safe points
- **Save Content**: Full snapshot of current battle state
  - Includes turn order, entity states, HP, status effects
  - Includes minigame-specific state if any
  - Complete state preservation for resuming combat
- **Error Handling**: Failed saves print debug error and continue
  - Saves don't block turn progression
  - Performance impact is pre-release polish concern
  - Alpha focuses on functionality over optimization

#### Action System Architecture
- **Flexible Design**: Action system supports Attack, Spell/Ability, and Item actions
  - Extensible to support future action types
  - Consistent interface for all action types
- **Message Logging**: Actions can log messages to battle screen
  - Enables wind-up messages (e.g., "Dragon A takes a deep breath")
  - Flexible enough for future enemy action indication
  - Supports narrative and feedback during combat
- **Target Selection Integration**: Seamless integration with target selection system
  - Consistent visual feedback across all actions
  - Reusable target selection logic
- **Revive Logic**: Reusable revive logic system
  - Works for both item-based and ability-based revives
  - Consistent behavior regardless of revive source
  - Extensible for future revive mechanics

### Status Effects System
- **Framework**: Status effects are temporary conditions that modify combat behavior
- **Application**: Status effects can be applied by abilities, items, equipment, or enemy actions
- **Duration**: Status effects have specific durations (number of turns or until removed)
- **Stacking**: Some status effects can stack (e.g., multiple burn stacks), while others cannot
- **Removal**: Status effects can be removed by:
  - Expiring after their duration
  - Items that cure specific status effects
  - Certain abilities or equipment effects
  - Death of the affected character

**Key Status Effects:**
- **Burn**: Deals damage over time to the affected target
  - Applied by Wild Mage's Flame Sword equipment (red flushes have a chance to apply burn)
  - Typically deals damage at the start of each turn
  - Can stack multiple times for increased damage
- **Silence**: Prevents the affected character from using abilities
  - Applied by Monk's minigame (e.g., Necromancer's Paper card on tie)
  - Character can still use basic attacks and items
  - Does not prevent minigame triggers, but modifies minigame behavior
  - **Class-Specific Silence Interactions**: Silence affects each class's minigame differently:
    - **Berserker**: Silence nullifies the effect range mechanic (no effect ranges available)
    - **Time Wizard**: Silence changes all event symbols to null symbols, ending minigame as if time expired (no special effects)
    - **Monk**: Silence removes special effects from enemy options (only basic win/loss/tie effects remain)
    - **Wild Mage**: Silence disallows discards (cannot discard cards during minigame)
  - **Flexible System Design**: Silence system is designed to be easily modifiable
    - Allows changes to class-specific interactions without major refactoring
    - Supports future balance adjustments and new class additions
- **Taunt**: Forces enemies to target the affected character
  - Applied by Berserker's effect ranges (standing on 18-20) and Monk's Duelist Gauntlets (ties)
  - Redirects enemy attacks and abilities to the taunting character
  - Useful for protecting other party members

**Status Effect Interactions:**
- **With Minigames**: Some status effects modify minigame performance or outcomes
  - Silence has class-specific interactions that make minigames harder
  - Other status effects may modify minigame parameters or outcomes
- **With Combat**: Status effects affect turn order, damage, targeting, and other combat mechanics
- **With Equipment**: Equipment can modify status effect application, duration, or effectiveness

### Revive Mechanics
- **Revive Sources**: Revives can come from multiple sources:
  - **Items**: At least one single-target revive item and one full-party revive item
  - **Abilities**: Some class effects may provide revive effects (future consideration)
  - **Reusable Logic**: Revive logic is designed to be reusable across all sources
    - Same system handles item-based and ability-based revives
    - Consistent behavior regardless of revive source
    - Extensible for future revive mechanics
- **Target Selection for Revives**: 
  - Dead party members can be selected as targets for revive actions
  - Visual feedback is consistent with other target selection:
    - Highlight and arrow appear (maintains greyed out state)
    - Dead party members remain visible and selectable
  - Dead enemies cannot be revived (vanish on death)
- **Revival Process**: When a party member is revived:
  - Health is restored (amount depends on revive source)
  - Status effects may be cleared (depends on revive type)
  - Party member display returns to normal (no longer greyed out)
  - Party member rejoins turn order
- **Turn Order Rejoin**: When a party member is revived:
  - Starting speed calculated as: current active entity speed + typical turn speed roll
  - Revived member added to turn order at appropriate position
  - Turn order display animates to show updated order
  - Member can act on their next turn

---

## 4. Character Classes

### Class Selection System
- **Rerollable Selection**: Choose three classes from a random rerollable selection at the start of each run
- **No Restrictions**: Can choose duplicate classes if desired
- **Class Identity**: Each class has distinct abilities and minigame mechanics
- **Balanced Roles**: Classes are designed to complement each other
- **Character Scaling**: Characters chosen at initial party creation have low stats and sparse equipment
- **Pricing**: Purchased characters (at mercenary outposts) will be more expensive based on their default stats and equipment

### Three Initial Classes

#### Berserker
- **Theme**: Rage and reckless abandon
- **Minigame**: Blackjack
- **Mechanic**: "Hit me" mechanic conflated with Berserk enrage - taking cards builds rage, ability power scales with hand value
- **Abilities**: Physical attacks, rage-based effects, berserker buffs
- **Playstyle**: High risk/reward, leans more towards simply attacking than other classes, rewards pushing limits and managing rage

**Attribute Effects:**
- **Strategy**: Gives a number of random effect ranges when effect ranges are cleared (after ability use and at the start of combat)
  - 0 at Strategy 0, 1 at Strategy 2, 2 at Strategy 4, 3 at Strategy 7, 4 at Strategy 10
- **Luck**: Grants a small amount of damage reduction from all sources (including 'hit me' damage)

**Detailed Minigame Mechanics:**
- **Setup**: Standard blackjack game against the dealer (enemy)
- **Objective**: Build a hand value as close to 21 as possible without going over
- **Hit Damage**: Each time the Berserker "hits" (takes another card), they take some damage from the enemy
  - Represents the reckless nature of going deeper into berserk state
- **Berserk State Triggers**: Berserker enters "Berserk" state upon:
  - **Blackjack**: Scoring exactly 21 (natural blackjack or built to 21)
  - **Bust**: Going over 21
- **Blackjack Bonus**: If a blackjack is scored, the Berserker regenerates a percentage of their max HP
- **Effect Ranges**: While NOT berserking, basic attacks add "effect ranges" to the blackjack minigame
  - These ranges add special effects when "standing" on scores within the range
  - Makes it more likely to land the effect you're looking for (e.g., range 6-8 instead of exactly 7)
  - Examples: Standing on 6-8 = increase party's Luck by 1, Standing on 18-20 = taunt effect on selected enemy
  - Equipment may provide additional effect ranges for different scores
  - Effect ranges are cleared after each ability use
- **Standing Mechanics**: When "standing" in the minigame, the Berserker can choose the target of their attack/ability
- **Scoring**:
  - Hand value scales ability damage/effectiveness
  - Higher hand values (closer to 21) = stronger effects
  - Score of 21: Always deals damage to all enemies
  - Both blackjack and bust trigger berserk state with different effects

**Impact Mechanics:**
- **Hand Value Scaling**: Ability power scales with final hand value
  - Lower values: Base damage/effect
  - Values closer to 21: Increased multipliers
  - Blackjack (21): Maximum power + berserk state + HP regeneration + damage to all enemies
  - Bust: Triggers berserk state (may have different effects than blackjack berserk)
- **Berserk State**: Triggered by blackjack or bust
  - Stacks up to 10 times
  - If the Berserker enters berserk while already in berserk, the effect will stack (up to 10 total stacks)
  - Each stack increases Power and Speed by 1 stage
  - Equipment can augment berserk state effects
  - While berserking, effect ranges are not generated (only while not berserking)
- **Effect Ranges**: Special effects triggered when standing on scores within specific ranges
  - Different ranges trigger different effects (determined by equipment)
  - Makes it more likely to land desired effects (e.g., range 6-8 instead of exactly 7)
  - Examples: Standing on 6-8 = party Luck +1, Standing on 18-20 = taunt selected enemy
  - Provides strategic choice between going for 21 (all enemies) vs standing within ranges (targeted effects)
- **Risk/Reward**: Players must balance hand value with risk of taking damage on each hit, risk of busting, and choice between standing for effects vs pushing for 21

**On-Attack Effects:**
- **Basic Attack Interaction (Not Berserking)**: While NOT berserking, basic attacks add effect ranges to the blackjack minigame
  - Effect ranges provide special effects when standing on scores within the range
  - Makes it more likely to land the effect you're looking for
- **Basic Attack Interaction (Berserking)**: While berserking, basic attacks:
  - Deal 1.5x damage (on top of the Power bonus from berserk stacks)
  - Heal a percentage of the Berserker's HP
  - Remove all stacks of berserk state
  - Do not generate effect ranges
  - Creates strategic choice: maintain berserk stacks for Power/Speed bonuses vs. spend them for enhanced basic attacks with healing

**Synergy Mechanics:**
- **Rage Synergy**: Berserk state may interact with other party members' abilities
- **Damage Amplification**: High hand values or berserk state can enhance other party members' attacks
- **Risk Management**: Berserker's high-risk playstyle can create opportunities for other party members

#### Time Wizard
- **Theme**: Temporal manipulation and precision
- **Minigame**: Minesweeper analogue with time limit
- **Mechanic**: Reveal grid squares within time limit, choose which timeline event to activate, clear entire grid for bonus damage
- **Abilities**: Time-based effects (haste, slow, delay, temporal damage)
- **Playstyle**: Fast-paced and strategic, rewards quick thinking and planning under pressure

**Attribute Effects:**
- **Speed**: Increases the amount of time available to finish the minigame
- **Skill**: Increases the number of timeline events present on the board (from 1 at Skill 0 to 11 at Skill 10)
- **Strategy**: Increases the size of the board (from 4x4 at Strategy 0 to 14x14 at Strategy 10)
- **Luck**: Scales ability damage

**Detailed Minigame Mechanics:**
- **Setup**: Small grid (typically 5x5 or 6x6) with hidden "important events in the timeline"
- **Objective**: Reveal grid squares within a time limit to find timeline events, either trigger an event during play or let time expire for burst spells
- **Time Limit**: Players have a limited time to reveal as many squares as possible
- **Number System**: Revealed squares show numbers indicating nearby events (classic minesweeper logic)
- **Event Symbols**: Timeline events are marked with different symbols that appear alongside numbers when revealed:
  - **Square (□)**: One type of timeline event
  - **Pentagon (⬟)**: Another type of timeline event
  - **Hexagon (⬡)**: Another type of timeline event
  - **Other symbols**: Additional event types possible
- **Scoring**: 
  - Each square revealed: Builds up effect power
  - Revealing an event: Event becomes available for activation
  - Effect scales with how much of the board has been cleared

**Ability Resolution:**
- **Event Activation**: If a timeline event is triggered before the time limit expires, the ability effect is determined by:
  - Which event symbol was activated
  - How much of the board had been cleared (scales effect power)
- **Time Burst**: If the time limit expires without triggering an event, a "Time Burst" spell activates, dealing damage scaled by how much of the board was cleared
- **Mega Time Burst**: If the time limit expires AND all non-event squares have been cleared, a "Mega Time Burst" spell activates, dealing extra damage beyond the standard Time Burst

**Impact Mechanics:**
- **Event-Based Effects**: Different event symbols correspond to different effects (determined by equipment):
  - Each symbol type represents a different timeline event with unique effects
  - Effects can include: enemy turn manipulation (delay/slow), party member buffs (haste, extra turns), temporal damage, Speed attribute buffs/debuffs, or other time-based effects
  - Effect power scales with board completion percentage
- **Time Burst Effects**: Standard damage spell that activates on time expiration
- **Mega Time Burst Effects**: Enhanced damage spell that activates when time expires with full non-event board completion
- **Strategic Choice**: Players must decide whether to:
  - Trigger an event early for specific effects (but lower power from less board cleared)
  - Wait to clear more board for stronger effects (but risk time expiring)
  - Aim for full board clear for Mega Time Burst (highest damage, but most risky)
- **Grid Position**: The location of revealed events may influence targeting (left = first enemy, right = last enemy, etc.)

**On-Attack Effects:**
- **Basic Attack Interaction**: Basic attacks partially clear the board for the next cast of the Time Wizard's ability
  - Effectively performs the first click for the player

**Synergy Mechanics:**
- **Event-Based Targeting**: Time Wizard can choose which party member receives effects based on which timeline event symbol is activated
  - Different symbols may target different party members or have different targeting rules
- **Turn Manipulation**: Event-based effects can grant extra turns to specific party members
- **Combo Windows**: High energy builds create "time windows" where other party members' abilities have reduced cooldowns or enhanced effects
- **Event Warnings**: Revealed event locations can be "marked" to warn other party members, giving them defensive bonuses or preparation time

#### Monk
- **Theme**: Martial arts mastery and reading opponents
- **Minigame**: Fighting game read/counter system (Rock Paper Scissors variant)
- **Mechanic**: Choose target first, then play against enemy's RPS cards, each with unique win/loss/tie effects
- **Abilities**: Varies greatly from enemy to enemy
- **Playstyle**: Aggressive and reactive, rewards reading enemy cards and strategic counter-play

**Attribute Effects:**
- **Power**: Ability damage scales with basic attack damage (already included in win/loss effects)
- **Skill**: Reduces the damage taken from a lost RPS
- **Strategy**: Determines the number of cards the enemy has (based on enemy's Strategy minus Monk's Strategy, with a minimum of 1)
- **Speed**: Adds "redos" to the minigame (0 at Speed 0, 1 at Speed 3, 2 at Speed 6, 3 at Speed 10)

**Detailed Minigame Mechanics:**
- **Target Selection**: Monk must choose target enemy BEFORE starting the minigame
- **Setup**: Target enemy reveals a set of Rock, Paper, or Scissors cards
  - Number of cards: Based on enemy's Strategy minus Monk's Strategy (minimum of 1)
  - RPS value of each card is random (enemy may have multiple Rock cards, Paper cards, etc.)
- **Objective**: Determine the best outcome from a single game of rock paper scissors
- **Fighting Game Moves** (Rock/Paper/Scissors):
  - **Strike** (Rock): Beats Scissors, loses to Paper
  - **Grapple** (Paper): Beats Rock, loses to Scissors
  - **Counter** (Scissors): Beats Paper, loses to Rock
- **Scoring**: 
  - Win: Trigger win effect for that enemy card
  - Lose: Trigger loss effect for that enemy card
  - Tie: Trigger tie effect for that enemy card
- **Ability Power**: Scales with number of cards defeated and outcomes achieved

**Impact Mechanics:**
- **Per-Enemy Card Effects**: Each enemy card has unique effects based on win/loss/tie outcomes (determined by equipment/enemy type):
  - **Win Effects**: Positive outcomes when Monk wins against that card, plus basic attack damage
  - **Loss Effects**: Negative outcomes when Monk loses against that card, plus half enemy attack damage taken
  - **Tie Effects**: Special outcomes when Monk ties against that card
- **Examples**:
  - Rat's Scissors card: Instant death effect if it loses (Monk wins)
  - Necromancer's Paper card: Silence effect on tie
  - Different enemies have different effect sets for their cards
- **Strategic Choice**: Players must consider which cards to win/lose/tie based on their effects

**On-Attack Effects:**
- **Basic Attack Interaction**: Basic attacks reduce the target's Strategy by 1 (stacking)
  - Reduces the number of cards the enemy will have in the next minigame

**Synergy Mechanics:**
- **Target Selection Synergy**: Choosing the right target can set up other party members (e.g., taunt effects, debuffs)
- **Effect Chaining**: Win/loss/tie effects from enemy cards can create opportunities for other party members
- **Combo Setup**: Certain card outcomes can "mark" enemies or create vulnerabilities for other party members
- **Pressure Building**: Successfully navigating multiple enemy cards builds pressure that benefits the entire party

### Unlockable Classes

#### Wild Mage
- **Theme**: Chaos and unpredictability
- **Minigame**: Poker-like card game
- **Mechanic**: Draw cards, form hands, ability power scales with hand strength
- **Abilities**: Varied magical effects (damage, debuffs, random effects)
- **Playstyle**: High risk/reward, performance varies significantly based on luck and skill

**Attribute Effects:**
- **Skill**: Increases the number of cards that can be discarded (1 at Skill 0, 2 at Skill 2, 3 at Skill 4, 4 at Skill 6, 5 at Skill 8, 6 at Skill 10)
- **Strategy**: Determines the number of discards available (0 at Strategy 0, 1 at Strategy 1, 2 at Strategy 4, 3 at Strategy 7, 4 at Strategy 10)
- **Luck**: Determines hand size (from 4 cards at Luck 0 to 14 cards at Luck 10)

**Detailed Minigame Mechanics:**
- **Setup**: Draw 5 cards from a 16-card deck
  - **Deck Composition**: Numbers 9-2 (8 different numbers), two suits (Ice ❄ and Fire 🔥)
  - Each number appears twice (once in Ice, once in Fire)
- **Objective**: Form the best hand possible with limited deck
- **Hand Strength Scaling**: 
  - Base damage: Basic attack damage (pre-multiplier)
  - High Card: Base damage/effect
  - Pair: 1.5x multiplier
  - Two Pair: 2x multiplier
  - Flush (all same suit): 3x multiplier
  - Flush + Pair (all same suit with a pair): 4x multiplier
  - Perfect Flush (all 5 cards same suit, no pairs): 5x multiplier

**Impact Mechanics:**
- **Hand-Based Effects (from equipment)**: The type of hand formed (flush, pair, etc.) and card composition determines bonus effects based on equipped items
  - Equipment may modify effects based on suit composition (Ice/Fire), number ranges, or hand types
  - Effects can include elemental damage, targeting modifications, utility effects, or special properties

**On-Attack Effects:**
- **Basic Attack Interaction**: Basic attacks "pre-draw" a card to be used in the next minigame
  - This pre-drawn card does not count towards hand size
  - Attacking again will reroll the pre-drawn card

**Synergy Mechanics:**
- **Card Sharing**: Wild Mage can "hold" a card for the next turn, potentially setting up better hands
- **Party Buffs**: Certain hands grant temporary buffs to party members (effects determined by equipment)
  - Hand types and compositions may grant defensive or offensive buffs based on equipped items
  - Pairs and flushes may grant party-wide effects depending on equipment
- **Combo Setup**: High-value hands can "mark" enemies, making them vulnerable to other party members' attacks
- **Hand Synergy**: Hand-based bonuses from equipment can interact with other party members' abilities

### Future Classes
- Additional classes will follow the "old game" theming pattern
- Potential themes: Tetris, Solitaire, Checkers, etc.
- Each class maintains unique identity and minigame mechanics

---

## 5. Minigame System

### Core Principles
- **Unique Per Class**: Each class has its own minigame(s) that fit their theme
- **Performance-Based**: Minigame results directly impact ability effectiveness
- **Integrated Flow**: Minigames feel like part of combat, not separate mini-games
- **Skill Expression**: Player skill at minigames matters for optimal play
- **Design Goals**:
  1. **Variety**: Represent a broad range of classic games
  2. **Simplicity**: Small enough not to distract from combat flow
  3. **Impact**: Contextual effects beyond just high scores
  4. **Synergy**: Minigames interact with each other and party composition

### Minigame Integration
- **Trigger**: Activated when character uses Spell/Ability action
- **Context**: Minigame UI overlays or replaces combat view temporarily
- **Resolution**: Results feed back into combat (damage numbers, effect application)
- **Return**: Seamless transition back to combat view
- **Duration**: Quick execution - typically 5-15 seconds per minigame

### Performance Scaling
- **Success Metrics**: Each minigame has clear success metrics
- **Effect Scaling**: Ability effects scale based on performance
- **Failure States**: Poor performance may result in reduced effect, negative effect, or no effect
- **Impact Mechanics**: Beyond raw power, choices and outcomes have contextual effects

### Synergy System
- **Cross-Class Interactions**: Minigames can affect other party members
  - This is mainly enabled by the Attribute system.
- **Strategic Choices**: Players must consider party composition when making minigame decisions
- **Combo Potential**: Certain minigame outcomes can set up or enhance other characters' abilities
- **Team Coordination**: Optimal play requires understanding how minigames work together

### Difficulty and Scaling
- **Static Rules**: Minigame rules don't change, but difficulty may scale
- **Optional Scaling**: Enemy difficulty or encounter level may affect minigame complexity
- **Player Skill**: Primary difficulty comes from player skill, not artificial difficulty increases

---

## 6. Encounter & Progression

### Encounter Generation
- **Hand-Crafted**: Encounters are hand-crafted and selected from encounter pools
- **Encounter Pools**: Encounters are organized into pools based on encounter level and land theme
  - Encounters are organized by land theme and difficulty level
- **Random Selection**: Encounters are randomly selected from appropriate pools to provide variety
  - Branching structure randomly selects from hand-crafted encounters in appropriate pools
  - Random selection from encounter pools ensures each run feels different while maintaining balanced, designed encounters
- **Enemy Composition**: Each hand-crafted encounter has a fixed enemy composition and formation
  - Hand-crafted enemy compositions and formations, randomly selected from encounter pools
- **Difficulty Scaling**: Encounters increase in difficulty as player progresses through lands
- **Rewards**: Rewards are hand-crafted per encounter, with some encounters offering random reward selections
- **Variety**: Different enemy types, formations, and special mechanics are designed into each encounter

### Branching Path Structure
- **Light Branching**: Occasional choice points between encounter paths
- **Route Selection**: Players select routes on the Land screen when branching options are available
- **Path Differences**: 
  - Different enemy types
  - Different rewards
  - Different difficulty levels
  - Special encounters unique to paths
- **Convergence**: Paths may converge at boss encounters or milestones
- **Replayability**: Branching encourages different path choices on subsequent runs

### Encounter Types
- **Standard Encounters**: Regular combat with hand-crafted enemy compositions
- **Boss Encounters**: Stronger enemies with unique mechanics, appear at milestones
- **Elite Encounters**: Tougher than standard but not bosses
- **Special Encounters**: Non-combat or unique mechanics (rewards, choices, events)

### Enemy Design & Mechanics
- **Enemy Attributes**: Enemies use the same five-attribute system as party members
  - **Power**: Affects enemy health and attack damage
  - **Skill**: Affects enemy minigame performance (if applicable)
  - **Strategy**: Affects enemy minigame performance and determines number of cards in Monk's minigame
  - **Speed**: Affects enemy turn frequency
  - **Luck**: Affects enemy minigame performance (if applicable)
- **Enemy Types**: Enemies are categorized by type and role
  - Different enemy types have different stat distributions and abilities
  - Enemy types may favor certain attributes (e.g., fast enemies have high Speed, tanky enemies have high Power)
- **Monk Minigame Interaction**: Enemy Strategy directly affects Monk's minigame
  - Number of RPS cards = Enemy's Strategy minus Monk's Strategy (minimum of 1)
  - Higher enemy Strategy means more cards to navigate
  - Basic attacks reduce enemy Strategy, making subsequent minigames easier
- **Enemy Scaling**: Enemy stats scale with encounter difficulty
  - Early encounters: Lower attribute values
  - Later encounters: Higher attribute values
  - Boss encounters: Significantly higher stats and unique mechanics
- **Enemy Abilities**: Enemies may have abilities that interact with party minigames
  - Some enemies may have their own minigame-like mechanics
  - Enemy abilities can modify party member attributes or minigame performance
  - Enemy abilities may apply status effects or debuffs

### Boss Encounter Mechanics
- **Unique Boss Mechanics**: Bosses have unique mechanics that differentiate them from standard encounters
  - Bosses may have multiple phases with different behaviors
  - Bosses may have special abilities that trigger at certain health thresholds
  - Bosses may have environmental effects or stage hazards
- **Boss Differences**: Bosses differ from standard encounters in several ways
  - Significantly higher stats (Power, Skill, Strategy, Speed, Luck)
  - Multiple health bars or phases
  - Unique attack patterns and abilities
  - Special mechanics that require specific strategies to counter
- **Boss Minigame Interactions**: Bosses may have special interactions with party minigames
  - Bosses may modify minigame parameters (e.g., reducing time limits, changing board sizes)
  - Bosses may have abilities that interfere with minigame performance
  - Bosses may have their own minigame-like mechanics that players must navigate
- **Boss Encounter Structure**: Boss encounters follow specific patterns
  - Bosses appear at the end of each land (milestone encounters)
  - Final boss appears at the end of "The Rift" (final land)
  - Boss encounters are hand-crafted with specific mechanics and patterns
  - Boss encounters may have multiple phases that change behavior and mechanics

### Run Progression
- **Start**: Party selection, begin first encounter
- **Mid-Run**: Series of encounters with occasional branching choices
- **Boss Milestones**: Boss encounters mark progression points
- **End**: Final boss or completion condition
- **Length**: Balanced for 30-60 minute runs (to be determined through playtesting)

---

## 7. Items & Equipment

### Item System

#### Item Categories
- **Healing Items**: Restore health to individual party members or the entire party
- **Buff Items**: Temporarily increase party member attributes (Power, Skill, Strategy, Speed, Luck)
- **Debuff Items**: Reduce enemy attributes (Power, Skill, Strategy, Speed, Luck)
- **Utility Items**: Special effects (status cures, temporary immunities, etc.)
- **Combat-Only Items**: Items that can only be used during combat encounters

#### Item Usage
- **Combat Usage**: Items can be used during combat via the standard Item action
  - No minigame required for item usage
  - Items take effect immediately when used
  - Items can be used on any character's turn
- **Between-Encounter Usage**: Most items can be used between encounters
  - Players can manage inventory and use items on the Land screen between encounters
  - Allows strategic resource management and preparation
- **Usage Restrictions**: Some items are marked as "Combat-Only"
  - Combat-only items cannot be used outside of combat encounters
  - Typically includes items that target enemies or have time-sensitive effects
  - Forces players to make tactical decisions during combat

#### Item Effects

**Healing Effects:**
- **Single Target**: Restore health to one party member
- **Party-Wide**: Restore health to all party members
- **Percentage-Based**: Restore a percentage of max HP
- **Fixed Amount**: Restore a fixed amount of HP

**Attribute Buffing:**
- **Individual Buffs**: Increase a single party member's attribute(s)
  - Can target specific attributes (e.g., +2 Power, +1 Speed)
  - Can target multiple attributes at once
  - Buffs are temporary (duration varies by item)
- **Party-Wide Buffs**: Increase all party members' attributes
  - Typically smaller bonuses than individual buffs
  - Useful for preparing for difficult encounters
  - Can stack with individual buffs
- **Attribute Types**: Items can buff any of the five attributes:
  - **Power**: Increases health and basic attack damage
  - **Skill**: Improves class-specific minigame performance
  - **Strategy**: Improves class-specific minigame performance
  - **Speed**: Reduces time between turns
  - **Luck**: Improves class-specific minigame performance

**Attribute Debuffing:**
- **Enemy Debuffs**: Reduce enemy attributes
  - Can target specific enemy attributes
  - Reduces enemy effectiveness in combat and minigames
  - Useful for weakening tough enemies before engaging
- **Debuff Types**: Items can reduce any of the five enemy attributes:
  - **Power**: Reduces enemy health and attack damage
  - **Skill**: Reduces enemy minigame performance (if applicable)
  - **Strategy**: Reduces enemy minigame performance (if applicable)
  - **Speed**: Increases time between enemy turns
  - **Luck**: Reduces enemy minigame performance (if applicable)

**Utility Effects:**
- **Status Cures**: Remove negative status effects from party members
- **Immunities**: Grant temporary immunity to specific status effects
- **Resource Restoration**: Restore MP or other resources (if applicable)
- **Special Effects**: Unique effects determined by item type

#### Item Acquisition
- **Encounter Rewards**: Items obtained after completing encounters
- **Special Events**: Items from non-combat encounters or choice events
- **Shops**: Items can be purchased from shop encounters (if implemented)
- **Boss Rewards**: Special items from boss encounters

#### Inventory Management
- **Limited Inventory**: Players have a limited inventory space
- **Item Stacking**: Some items may stack (multiple copies of the same item)
- **Inventory Between Encounters**: Players can view and manage inventory on the Land screen between encounters
- **Strategic Planning**: Limited inventory space requires careful resource management
- **Item Priority**: Players must decide which items to keep and which to use

### Equipment System

#### Equipment Overview
- **Purpose**: Equipment provides permanent stat boosts and modifies class abilities
- **Character-Specific**: Each character can equip items that affect their performance
- **Simplified System**: Focus on stat boosts and ability modifications, not complex equipment mechanics

#### Equipment Slots

Each character has a fixed set of equipment slots that determine what equipment can be equipped:

- **Ring Slots (2)**: Two ring slots per character
  - Rings generally enable specific synergistic effects between classes
  - Example: A ring that adds a specific effect range to the Berserker's minigame when a pair is played by the Wild Mage
  - Rings can create cross-class interactions and combo opportunities
  - Strategic choice: Which rings to equip to maximize party synergy

- **Neck Slot (1)**: One necklace slot per character
  - Necklaces usually increase some attributes on the entire party
  - Party-wide attribute bonuses make necklaces valuable for overall party strength
  - Strategic choice: Which party member should wear the necklace for maximum benefit

- **Armor Slot (1)**: One armor slot per character
  - Armor generally grants attributes to the wearer
  - Provides direct stat boosts to the equipped character
  - Strategic choice: Which attributes to prioritize for each character

- **Head Slot (1)**: One headgear slot per character
  - Headgear varies between giving attributes to the wearer and giving attributes to the party
  - Some headgear provides personal bonuses, others provide party-wide bonuses
  - Strategic choice: Personal power vs. party support

- **Class-Specific Slots (1-2)**: Variable number of slots depending on class
  - Generally weapon slots, but class-specific in nature
  - Give some attributes to the wearer
  - May shift the way the class is played
  - **Slot Details by Class**:
    - **Berserker**: 1-2 slots (depending on 1-handed weapon + shield vs. 2-handed weapon)
    - **Time Wizard**: 1 slot (pocketwatch)
    - **Wild Mage**: 2 slots (sword and book)
    - **Monk**: 1 slot (gloves)
  - Examples:
    - **Berserker: Ranting Axe of Eloquence** - Attribute bonuses from berserking are applied party-wide
    - **Time Wizard: Pentagonal Stopwatch** - Pentagon events permanently reduce speed of all enemies by 1
    - **Wild Mage: Flame Sword** - Red flushes deal fire damage and have a chance to apply burn
    - **Monk: Duelist Gauntlets** - Ties apply taunt to the targeted enemy and deal 0.5x attack damage
  - Strategic choice: How to build each class through weapon selection

#### Equipment Effects
- **Attribute Bonuses**: Equipment can provide permanent attribute increases
  - Bonuses apply to any of the five attributes
  - Equipment can provide bonuses to multiple attributes
  - Bonuses are additive with base attributes
- **Ability Modifications**: Equipment can modify class-specific abilities
  - Adds new effect ranges or modifies existing ones
  - Changes minigame parameters (board size, hand size, etc.)
  - Provides bonus effects based on minigame performance
- **Synergy Effects**: Equipment can create synergies between party members
  - Equipment that benefits from other party members' abilities
  - Equipment that enhances party-wide effects

#### Equipment Acquisition
- **Encounter Rewards**: Equipment obtained from completing encounters
- **Boss Rewards**: Special equipment from boss encounters
- **Shop Purchases**: Equipment can be purchased from shop encounters (if implemented)
- **Character Scaling**: Equipment quality scales with encounter difficulty
  - Early encounters: Basic equipment with small bonuses
  - Later encounters: Better equipment with larger bonuses and special effects

#### Equipment Management
- **Equip Between Encounters**: Players can swap equipment on the Land screen between encounters
- **No Combat Swapping**: Equipment cannot be changed during combat
- **Strategic Choices**: Players must decide which equipment to use based on party composition and upcoming encounters

### Resource Management

#### Health Management
- **Health Persistence**: Party health persists between encounters
- **No Auto-Recovery**: Health does not automatically regenerate between encounters
- **Strategic Healing**: Players must use items or abilities to restore health
- **Health as Resource**: Health is a limited resource that must be managed carefully

#### Item Management
- **Consumable Resources**: Items are consumed when used
- **Limited Supply**: Items must be acquired through encounters or purchases
- **Strategic Usage**: Players must decide when to use items vs. save them
- **Between-Encounter Planning**: Players can use items on the Land screen between encounters to prepare

#### Ability Resources
- **Ability Limitations**: Abilities may have cooldowns, MP costs, or other limitations
- **Resource Balance**: Players must balance ability usage with item usage
- **Strategic Planning**: Resource management is key to run success

#### Run-Wide Resource Strategy
- **Early vs. Late Game**: Players must balance using resources early vs. saving for difficult encounters
- **Boss Preparation**: Players may need to save powerful items for boss encounters
- **Risk Assessment**: Players must assess when to use resources and when to conserve them

---

## 8. Roguelike Elements

### Run Structure
- **Complete Runs**: Each playthrough is a full run from start to finish
- **Auto-Save System**: Runs are automatically saved mid-progress
  - Auto-save prevents save-scumming (reloading to undo decisions)
  - Players can resume runs from the last auto-save point
  - Saves are deleted on run completion or failure
- **Restart on Failure**: Party death results in run failure and restart

### Permadeath/Restart Mechanics
- **Party Death**: If all party members are defeated, run ends
- **Item Carryover**: When party wipes, one item can be saved from the run
  - Saved item is applied to the next run
  - Players choose which item to save from their inventory
  - Only one item can be carried over per run failure
  - Provides a small consolation prize and strategic choice on defeat
- **Full Restart**: Begin new run with fresh party selection
- **Limited Carryover**: Only the selected item persists between runs
  - All other resources, progress, and party state are lost
  - Equipment, currency, and other items are reset
- **Fresh Start**: Each run is largely independent, with only one item carrying over

### Meta-Progression
- **Persistent Currency**: Players earn currency after each run, even on defeat
  - Currency is earned regardless of whether the run succeeds or fails
  - Provides progress even when runs end in failure
  - Encourages continued play despite setbacks
- **Currency Usage**: Currency can be used to:
  - Purchase adventurers from mercenary outposts (primary use)
  - Reroll character selection at the start of runs
  - Reroll character selection at mercenary outposts
- **Zero-Cost Adventurers**: Depending on how much currency the player has, zero-cost adventurers may be offered
  - Zero-cost adventurers have no gear and all stats at 1
  - Provides a fallback option when currency is low
- **Philosophy**: Currency provides convenience and options without making runs easier through direct power increases

---

## 9. Technical Considerations

### Godot 4.5 Implementation
- **Engine**: Godot 4.5 with GL Compatibility renderer
- **Scene Structure**: 
  - Main menu scene
  - Party selection scene
  - Combat/encounter scene
  - Minigame scenes (one per class)
  - UI overlay systems
- **State Management**: Encounter state, party state, run state

### Scene Architecture
- **Combat Scene**: Main combat view with turn-based logic
- **Minigame Scenes**: Separate scenes or overlays for each minigame type
- **Scene Transitions**: Smooth transitions between combat and minigames
- **UI System**: Shared UI components for health, resources, etc.

### Combat, Minigame, and Class Interaction Architecture

The combat system, minigames, and character classes interact through a well-separated architecture that follows SOLID principles:

#### Class Behavior System
- **BaseClassBehavior**: Abstract base class that defines the interface for class-specific behaviors
  - Each character class has a corresponding behavior class (e.g., `BerserkerBehavior`, `MonkBehavior`)
  - Behavior classes handle all class-specific logic, keeping combat system generic
  - **Key Methods**:
    - `needs_target_selection() -> bool`: Determines if target selection is required before minigame
    - `build_minigame_context(character: Character, target: Variant) -> Dictionary`: Builds class-specific context data for minigames
    - `get_minigame_scene_path() -> String`: Returns the scene path for the class's minigame
    - `apply_attack_effects(attacker: Character, target: EnemyData, base_damage: int) -> int`: Applies on-attack effects (e.g., Berserker's berserk state interactions)
    - `format_minigame_result(character: Character, result: MinigameResult) -> Array[String]`: Formats class-specific result logging
    - `get_ability_target(character: Character, result: MinigameResult) -> Variant`: Determines ability target if not provided

#### Minigame Registry Pattern
- **MinigameRegistry**: Central autoload singleton that maps class types to their behaviors and minigame scenes
  - Provides centralized registration and lookup for class-specific data
  - Eliminates the need for match statements in combat system
  - New classes are registered by adding a behavior class and scene path to the registry
  - **Benefits**: 
    - Combat system doesn't need to know about all classes
    - Adding new classes doesn't require modifying combat code (Open/Closed Principle)
    - Single source of truth for class-to-minigame mappings

#### Combat System Integration
- **Combat System Responsibilities**: 
  - Manages turn order, action selection, and combat flow
  - Delegates class-specific logic to behavior instances via MinigameRegistry
  - Handles minigame modal lifecycle (opening, closing, result processing)
  - Applies standardized minigame results (damage, effects) generically
- **No Class-Specific Logic**: Combat system contains no match statements or class-specific conditionals
  - All class-specific behavior is handled by behavior classes
  - Combat system works with the `BaseClassBehavior` interface, not concrete classes

#### Minigame System
- **BaseMinigame**: Base class for all minigame implementations
  - Provides common interface and lifecycle management
  - Each minigame extends `BaseMinigame` and implements class-specific game logic
  - Emits `minigame_completed` signal with `MinigameResult` when finished
- **MinigameResult**: Standardized result format containing:
  - Damage value
  - Effects array (status effects, buffs, debuffs, etc.)
  - Metadata dictionary (class-specific data for logging/formatting)
- **Context Passing**: Minigames receive context dictionaries built by behavior classes
  - Context contains character state, target information, and class-specific data
  - Allows minigames to access necessary information without coupling to combat system

#### Interaction Flow
1. **Ability Trigger**: Player selects ability action for a character
2. **Target Selection**: Combat checks behavior's `needs_target_selection()` to determine if target selection is needed
3. **Context Building**: Combat uses behavior's `build_minigame_context()` to create minigame context
4. **Minigame Launch**: Combat loads minigame scene from registry and passes context
5. **Minigame Execution**: Player plays minigame, which emits result when complete
6. **Result Application**: Combat applies standardized results (damage, effects) generically
7. **Result Formatting**: Combat uses behavior's `format_minigame_result()` for class-specific logging

#### Benefits of This Architecture
- **Separation of Concerns**: Each system has clear, focused responsibilities
- **Extensibility**: New classes can be added without modifying existing code
- **Maintainability**: Class-specific logic is isolated in behavior classes
- **Testability**: Each component can be tested independently
- **Single Responsibility**: Combat handles combat flow, behaviors handle class logic, minigames handle game mechanics

### Minigame Implementation
- **Modular Design**: Each minigame is a separate, reusable system extending `BaseMinigame`
- **Integration Points**: Clear interfaces between combat system and minigame systems via behavior classes
- **Result Handling**: Standardized `MinigameResult` format that combat system can interpret generically
- **Reusability**: Minigames can be easily extended or modified without affecting combat system
- **Context-Driven**: Minigames receive all necessary data through context dictionaries, avoiding direct coupling

### Status Effect System

The status effect system provides a flexible, extensible framework for temporary combat conditions that modify entity behavior. The system follows object-oriented design principles with polymorphism and the Strategy pattern.

#### Status Effect Base Class

**File**: `scripts/data/status_effect.gd`

- **Base Class**: `StatusEffect` extends `RefCounted`
- **Core Properties**:
  - `duration: int` - Number of turns remaining before effect expires
  - `stacks: int` - Stack count for stackable effects (default 1)
  - `magnitude: float` - Scaling factor for effect strength (default 1.0)
  - `target: Variant` - Reference to the affected entity (Character or EnemyData)
- **Virtual Methods** (must be overridden by subclasses):
  - `get_effect_name() -> String` - Returns display name of the effect
  - `can_stack() -> bool` - Returns whether the effect can stack with itself
  - `_matches_existing_effect(existing: StatusEffect) -> bool` - Determines if an existing effect matches this one
    - Default: matches by script type (same class)
    - Child classes can override for custom matching (e.g., by attribute name for AlterAttributeEffect)
  - `on_apply(p_target: Variant, status_effects_array: Array[StatusEffect]) -> void` - Called when effect is applied
    - Sets target reference, finds matching existing effect using `_matches_existing_effect()`
    - Updates existing effect (stacking or duration refresh) or appends self to array
    - Handles all application logic internally
  - `on_tick(combatant: Variant) -> Dictionary` - Called at start of each turn
    - Returns dictionary with effects to apply (e.g., `{"damage": 5}`)
    - Can return `{"remove": true}` to force removal after processing
  - `on_modify_attributes(attributes: Attributes) -> void` - Called when calculating effective attributes
    - Default implementation does nothing
    - Child classes can override to modify attributes (e.g., AlterAttributeEffect)
  - `tick() -> bool` - Decrements duration, returns true if effect should be removed
  - `get_visual_data() -> Dictionary` - Returns visual representation data
    - Contains: `icon` (path), `color` (Color), `show_stacks` (bool)
  - `duplicate() -> StatusEffect` - Creates a copy of the effect for duplication

#### Status Effect Manager (Composition Pattern)

**File**: `scripts/data/status_effect_manager.gd`

The status effect system uses composition to eliminate code duplication between Character and EnemyData:

- **StatusEffectManager**: Encapsulates all status effect management logic
  - `status_effects: Array[StatusEffect]` - Stores all active effects
  - `owner: Variant` - Reference to the owning entity (Character or EnemyData)
  - `add_status_effect(effect: StatusEffect) -> void` - Delegates to effect's `on_apply()` method
  - `tick_status_effects() -> Dictionary` - Processes all effects, returns cumulative effects
  - `has_status_effect(effect_class: GDScript) -> bool` - Checks for effect type
  - `duplicate_effects(target_owner: Variant) -> Array[StatusEffect]` - Helper for duplication
  - `clear_effects() -> void` - Clears all effects (for death cleanup)

- **Benefits**: 
  - Eliminates duplication between Character and EnemyData
  - Single source of truth for status effect logic
  - Easy to test and maintain
  - Backward compatible (Character/EnemyData expose `status_effects` property that delegates to manager)

#### Concrete Status Effect Implementations

**Location**: `scripts/data/status_effects/`

Four status effects are currently implemented:

1. **BurnEffect** (`burn_effect.gd`)
   - **Stackable**: Yes (`can_stack()` returns true)
   - **Behavior**: Deals damage over time at start of each turn
   - **Damage Formula**: `magnitude * stacks` per turn
   - **Visual**: Orange color, displays stack count
   - **Application**: Applied by Wild Mage's Flame Sword equipment (red flushes)

2. **SilenceEffect** (`silence_effect.gd`)
   - **Stackable**: No (refreshes duration if already present)
   - **Behavior**: Prevents affected character from using abilities (Spell/Ability action)
   - **Visual**: Gray color, no stack display
   - **Application**: Applied by Monk's minigame (e.g., Necromancer's Paper card on tie)
   - **Combat Interaction**: Checked in combat system before allowing ability usage

3. **TauntEffect** (`taunt_effect.gd`)
   - **Stackable**: No (refreshes duration if already present)
   - **Behavior**: Forces enemies to target the affected character
   - **Visual**: Yellow color, no stack display
   - **Application**: Applied by Berserker's effect ranges (standing on 18-20) and Monk's Duelist Gauntlets (ties)
   - **Combat Interaction**: Enemy targeting logic prioritizes taunted party members

4. **AlterAttributeEffect** (`alter_attribute_effect.gd`)
   - **Stackable**: Yes (stacks alteration amounts additively)
   - **Behavior**: Modifies entity attributes (Power, Skill, Strategy, Speed, Luck)
   - **Properties**: 
     - `attribute_name: String` - Which attribute to modify
     - `alteration_amount: int` - Amount to modify (positive for buffs, negative for debuffs)
   - **Custom Matching**: Overrides `_matches_existing_effect()` to match by both class type AND attribute name
     - Allows multiple AlterAttribute effects (one per attribute) while still matching existing effects of the same attribute
   - **Attribute Modification**: Overrides `on_modify_attributes()` to apply alterations when calculating effective attributes
   - **Visual**: Green color for buffs, red color for debuffs, displays stacks
   - **Application**: Applied by Monk's basic attacks (reduces enemy Strategy by 1, stacking)

#### Entity Integration

**Files**: `scripts/data/character.gd`, `scripts/data/enemy_data.gd`

Both Character and EnemyData classes use composition with StatusEffectManager:

- **Status Effect Manager**: `status_manager: StatusEffectManager` - Manages all status effects
- **Backward Compatibility**: `status_effects: Array[StatusEffect]` - Read-only property that delegates to manager's array
- **Add Status Effect**: `add_status_effect(effect: StatusEffect) -> void`
  - Delegates to `status_manager.add_status_effect()`
  - Manager calls `effect.on_apply()` which handles target setting, matching, and appending
- **Tick Status Effects**: `tick_status_effects() -> Dictionary`
  - Delegates to `status_manager.tick_status_effects()`
  - Manager processes all effects and returns cumulative effects dictionary
- **Check Status Effect**: `has_status_effect(effect_class: GDScript) -> bool`
  - Delegates to `status_manager.has_status_effect()`
  - Uses `get_script()` comparison for type checking
- **Effective Attributes**: `get_effective_attributes() -> Attributes`
  - Calculates attributes with equipment bonuses and status effect modifications
  - Calls `effect.on_modify_attributes()` for each status effect
  - Allows effects like AlterAttributeEffect to modify attributes without type checking
- **Duplication**: `duplicate()` methods use manager's `duplicate_effects()` helper

#### Combat System Integration

**File**: `scripts/scenes/combat.gd`

##### Status Effect Processing

- **Method**: `_process_combatant_status_effects(combatant: Variant, is_party: bool) -> void`
  - Called at the start of each combatant's turn (before action execution)
  - Calls `tick_status_effects()` on the combatant
  - Applies damage from status effects (e.g., burn damage)
  - Updates UI displays (party or enemy displays)
  - Handles death from status effect damage

##### Effect Application

- **Method**: `_apply_effect(effect_dict: Dictionary, source: Character) -> void`
  - Creates effect instance from dictionary (supports both type string and class name)
  - Determines target if not provided in dictionary
  - Instantiates appropriate effect class using match statement:
    - `"burneffect"` or `"burn"` -> `BurnEffect`
    - `"silenceeffect"` or `"silence"` -> `SilenceEffect`
    - `"taunteffect"` or `"taunt"` -> `TauntEffect`
    - `"alterattributeeffect"` or `"alterattribute"` -> `AlterAttributeEffect`
      - Requires `attribute_name` and `alteration_amount` in dictionary
  - Applies effect to target via `add_status_effect()`
  - Effect's `on_apply()` method handles matching existing effects and appending
  - Logs effect application in combat log
  - Updates UI displays

##### Status Effect Checks

- **Silence Check**: In `_on_ability_pressed()`, checks `character.has_status_effect(SilenceEffect)` before allowing ability usage
  - If silenced, logs message and returns early (prevents minigame from opening)
- **Taunt Check**: In enemy targeting logic (`_select_enemy_target()`), prioritizes taunted party members
  - Checks all alive party members for `TauntEffect`
  - If taunted characters exist, randomly selects from taunted group
  - Otherwise, randomly selects from all alive party members

#### Status Effect Lifecycle

1. **Application**: Effect is created and added to target via `add_status_effect()`
   - Manager calls `effect.on_apply(target, status_effects_array)`
   - Effect sets its own target reference
   - Effect finds matching existing effect using `_matches_existing_effect()`
   - Effect updates existing effect (stacking/refresh) or appends itself to array
2. **Processing**: At start of each turn, `tick_status_effects()` is called on the entity
   - Manager processes all effects via `tick_status_effects()`
3. **Tick**: Each effect's `on_tick()` is called first, then `tick()` decrements duration
4. **Attribute Modification**: When `get_effective_attributes()` is called
   - Each effect's `on_modify_attributes()` is called with the attributes object
   - Effects can modify attributes directly (e.g., AlterAttributeEffect)
5. **Removal**: Effects are removed when:
   - Duration reaches 0 (from `tick()` returning true)
   - `on_tick()` returns `{"remove": true}`
   - Entity dies (status effects are cleared via `status_manager.clear_effects()`)
6. **Death Cleanup**: Status effects are cleared when entity dies (handled in `_handle_character_death()` and `_handle_enemy_death()`)

#### Design Patterns

- **Composition Pattern**: StatusEffectManager encapsulates status effect logic, eliminating duplication
- **Polymorphism**: Base class with virtual methods, concrete implementations handle specific behavior
- **Strategy Pattern**: Each effect type defines its own behavior through method overrides
- **Template Method**: Base class defines lifecycle structure, subclasses implement specific steps
- **Type Safety**: Uses `get_script()` comparison for type checking (works with `class_name` types)
- **Open/Closed Principle**: New effects can be added without modifying existing code

#### Extensibility

New status effects can be added by:

1. Creating a new class extending `StatusEffect` in `scripts/data/status_effects/`
2. Implementing all required virtual methods:
   - `get_effect_name()`, `can_stack()`, `on_apply()`, `on_tick()`, `tick()`, `get_visual_data()`, `duplicate()`
3. Optionally override `_matches_existing_effect()` for custom matching logic (e.g., match by attribute name)
4. Optionally override `on_modify_attributes()` to modify attributes when calculating effective attributes
5. Adding instantiation case in `_apply_effect()` match statement in `combat.gd`
6. No changes needed to Character/EnemyData classes or StatusEffectManager (Open/Closed Principle)

#### Integration Points

- **Minigame Results**: Effects are included in `MinigameResult.effects` array as dictionaries
  - Dictionary format: `{"class": "BurnEffect", "duration": 3, "magnitude": 2.0, "stacks": 1, "target": target_ref}`
- **Combat Log**: Status effect applications and processing are logged with appropriate event types
- **UI Displays**: Status effects can be visualized using `get_visual_data()` method
  - Provides icon path, color, and stack display preferences
- **Equipment/Items**: Can apply effects through effect dictionaries in minigame results or item usage

### Data Management
- **Class Definitions**: Data structures for classes, abilities, and minigame rules
- **Behavior Classes**: Class-specific logic encapsulated in behavior classes registered with MinigameRegistry
- **Enemy Definitions**: Enemy stats, abilities, and encounter pools
- **Encounter System**: Data structures and selection logic for hand-crafted encounters
- **Save System**: If needed, only for run state (not between runs)

### GDScript Best Practices

#### Code Style and Conventions
- **Naming Conventions**: Follow consistent naming conventions throughout the codebase
  - Use clear, descriptive names for variables, functions, and classes
  - Follow GDScript style guidelines for naming patterns
- **Avoid Global Function Overloading**: Do not use names that conflict with built-in GDScript functions
  - Avoid naming variables or functions after global functions like `char`, `max`, `min`, `abs`, etc.
  - Use alternative names (e.g., `character` instead of `char`, `maximum` instead of `max`)
  - Prevents conflicts and improves code clarity
- **Class Names**: Every script must have a `class_name` defined at the top
  - Provides clear type identification and enables type checking
  - Makes scripts accessible as types throughout the project
  - Example: `class_name Character` at the top of character scripts
  - **Exception**: Autoload singletons should NOT have `class_name` declarations
    - Autoload singletons are accessed globally by their autoload name (e.g., `GameManager`, `SceneManager`)
    - Adding `class_name` to autoload singletons can cause conflicts and is unnecessary
    - Autoload singletons should include a comment at the top explaining they are autoload singletons
- **Type Annotations**: Use explicit type annotations for parameters, variables, and return values wherever possible
  - Function parameters: `func _process(delta: float) -> void` instead of `func _process(delta)`
  - Return types: `func calculate_damage() -> int` instead of `func calculate_damage()`
  - Variable declarations: `var health: int = 100` instead of `var health = 100`
  - Improves code readability, enables better IDE support, and catches type errors early
  - Use `-> void` for functions that don't return a value
- **Indentation**: **-IMPORTANT, ALWAYS INCLUDE IN CONTEXT-** Four spaces should be used instead of tabs for indentation
- **Avoid Dictionaries**: Prefer typed classes over dictionaries wherever possible
  - Dictionaries lack type safety, IDE support, and compile-time error checking
  - Use `class_name` classes extending `RefCounted` for data structures
  - Create dedicated classes for contexts, configs, and state objects
  - Examples:
    - Instead of `Dictionary` for minigame context, create `MinigameContext` class
    - Instead of `Dictionary` for battle state, create `BattleState` class
    - Instead of `Dictionary` for VFX config, create `VFXConfig` class
    - Instead of `Dictionary` for status effect tick results, create `StatusEffectTickResult` class
  - Benefits:
    - Type safety and compile-time error checking
    - Better IDE autocomplete and refactoring support
    - Clearer code intent and self-documenting structure
    - Easier to extend and maintain
    - Better serialization support (can implement custom serialization methods)
  - **Exception**: Dictionaries may be used for:
    - Simple key-value mappings where the structure is truly dynamic and unknown at compile time
    - JSON parsing/deserialization (but convert to typed classes immediately)
    - Temporary data structures that are immediately converted to typed classes

#### SOLID Principles

The codebase follows SOLID principles to maintain clean, maintainable, and extensible code:

- **Single Responsibility Principle (SRP)**: Each class should have one reason to change
  - Combat system handles only combat flow and turn management
  - Behavior classes handle only class-specific logic
  - Minigames handle only their specific game mechanics
  - Avoid classes that mix multiple responsibilities (e.g., combat logic + class-specific logic)

- **Open/Closed Principle (OCP)**: Classes should be open for extension but closed for modification
  - Combat system is closed to modification when adding new classes
  - New classes extend `BaseClassBehavior` and register with `MinigameRegistry`
  - Adding new classes doesn't require changes to existing combat or minigame code
  - Use inheritance and polymorphism instead of match statements for class-specific behavior

- **Liskov Substitution Principle (LSP)**: Subtypes must be substitutable for their base types
  - All behavior classes must properly implement `BaseClassBehavior` interface
  - All minigames must properly extend `BaseMinigame` and emit results correctly
  - Subclasses should not violate the expected behavior of base classes

- **Interface Segregation Principle (ISP)**: Clients should not depend on interfaces they don't use
  - `BaseClassBehavior` provides focused methods for specific responsibilities
  - Combat system only uses the methods it needs from behavior classes
  - Avoid bloated interfaces with methods that most classes don't need

- **Dependency Inversion Principle (DIP)**: Depend on abstractions, not concretions
  - Combat system depends on `BaseClassBehavior` interface, not concrete behavior classes
  - Minigames depend on `MinigameResult` abstraction, not specific result implementations
  - Use registry pattern (`MinigameRegistry`) to provide abstractions rather than direct dependencies
  - High-level modules (combat) should not depend on low-level modules (specific classes)

#### Development Pattern

The project follows an iterative development cycle:

- **Prototype**: Build initial implementation to validate mechanics and gameplay
  - Focus on getting core functionality working
  - Don't worry about perfect architecture initially
  - Test with real gameplay scenarios

- **Test**: Verify the prototype works correctly and identify issues
  - Test edge cases and error conditions
  - Playtest to ensure mechanics feel good
  - Identify pain points and areas for improvement

- **Refactor**: Improve code quality and architecture based on testing
  - Extract class-specific logic into behavior classes
  - Remove match statements and replace with polymorphic behavior
  - Improve separation of concerns
  - Apply SOLID principles to make code more maintainable

- **Repeat**: Continue the cycle with new features or improvements
  - Each iteration builds on the previous refactoring
  - Architecture improves over time as patterns emerge
  - Balance between prototyping speed and code quality

**Philosophy**: It's acceptable to start with simpler implementations (e.g., match statements) during prototyping, but refactor to proper architecture (e.g., behavior classes) before moving to the next feature. This allows for rapid iteration while maintaining code quality.

---

## 10. Future Considerations

### Additional Classes
Potential new classes following the "old game" theme:
- **Tetris Class**: Stack blocks, clear lines for ability power
- **Solitaire Class**: Card arrangement and sequencing
- **Checkers Class**: Strategic piece movement
- **Simon Says Class**: Pattern memory and repetition
- **Connect Four Class**: Strategic placement and blocking

### Additional Minigames
- Each new class brings a new minigame
- Minigames should feel distinct and thematic
- Balance between skill and luck varies by class

### Expansion Ideas
- **More Encounter Types**: Puzzles, social encounters, exploration-lite mechanics
- **Character Progression**: Within-run progression (leveling, stat gains)
- **More Abilities**: Each class could have multiple abilities with the same minigame
- **Difficulty Modes**: Different difficulty settings for varied challenge
- **Achievements**: Track accomplishments across runs
- **Statistics**: Track performance metrics and minigame success rates

### Design Philosophy
- **Keep It Focused**: Maintain core loop of combat + minigames
- **Quality Over Quantity**: Better to have fewer, well-designed classes than many shallow ones
- **Player Skill**: Emphasize skill expression through minigames
- **Replayability**: Hand-crafted encounters with random selection and branching paths ensure variety

