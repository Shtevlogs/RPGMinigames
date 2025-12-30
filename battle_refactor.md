# Battle System Refactor

## Vision Statement

When battle starts, there will be a beat to set the scene and show what enemies you're encountering (including an encounter message and sound cue).
Initiatives will then be rolled and the battle will take place in a turn-by-turn manner.
When each turn starts, that party member or enemy will be highlighted for a beat before continuing.
On an enemy turn, the enemy in question will lightly animate for a beat to signify they are doing something, then the result of their action (attack, spell, item, etc) will occur. After the action is resolved, the battle will progress to the next turn.
On a party member's turn, action options will appear for the player to choose. These actions will include Attack, Spell (or some theme-coherent analogue), and Item. Highlighting different options will result in a sound cue, changing selected option will take a beat.
On selecting attack, the display for other party members will animate down and the action menu will close. At this time the player may highlight an enemy to attack. Each time a new enemy or ally is highlighted, a light sound cue will play and a selection arrow will move to 'target' the selected entity (this movement will take a beat).
If an attack is 'canceled' (via right click, or cancel button) party member displays will all return to normal (over a small beat) and the action menu will re open.
If a target is selected for an attack command, the party member's display will shake lightly to indicate an action taking place. An animation will play over top of the selected entity and they will flash for a beat (generally achieved by toggling the alpha of the sprite). Some time will be given for the animation to complete, and the battle will progress to the next turn.
On selecting spell (or theme-coherent analogue), the display for other party members will animate down and the action menu will close. If the class of the current party member reqires a target before playing their minigame, this will happen now simmilarly to the attack action entity process. At this time (or, once target selection is completed if necessary) the party member's class-specific minigame will animate open.
The specifics of each minigame will vary, but each action taken in specific minigames will have an action-specific timing, sound, and possibly motion.
If an action in the minigame requires a target, the minigame will close (but maintain state) and a similar target selection process will occur as selecting a target for an attack command (however, in this case, there will be no option to cancel the process). Once a target has been selected, the minigame may re-open, though this is fairly unlikely. If the minigame does not need to re-open, it's state will be cleaned up here while the animation for the minigame effect takes place.
After the minigame has been fully resolved it will animate closed (if it is still open) and whatever effect the minigame resulted in will occur, likely involving a visual effect, sound effect, and some animation. After a beat, the battle will progress to the next turn.
When an enemy reaches 0 hp or below, they will play a death animation, sound effect, and possibly visual effect. After a beat, combat will resume if there are enemies left.
When a party member reaches 0 hp or below, they will play a death animation, sound effect, and their party member display will grey out. After a beat, combat will resume if there are party members left.
If there are no enemies left alive, a victory message will animate in. After a beat, the rewards will be displayed in a list. After the player confirms the rewards the screen will fade back to the land screen.
If there are no party members left alive, a defeat message will animate in. After a beat, some run statistics will be shown. After the player confirms the run statistics, the screen will fade back to the main menu (and run conclusion logic will take place).

## Q&A: Clarifying the Vision

### Timing and Pacing

1. **What is a "beat"?** Is this a fixed duration (e.g., 0.5 seconds), a variable timing based on animation length, or a configurable value? Should different beats have different durations for different contexts?
1.a: A beat is some configurable length of time. Some of these will be stored in a config file or as constants (ie. ACTION_MENU_BEAT_DURATION, or MINIGAME_OPEN_BEAT_DURATION). Others may simply depend on how long an animation lasts.

2. **How should the timing of beats be coordinated?** Should beats be sequential (wait for one to complete before starting the next) or can some overlap? For example, can sound effects play while animations are still completing?
2.a: Some will overlap, but the logic will have to be structured on a good deal of sequential events. Sound effects and animations can happen at the same time, but the minigame modal will have to be fully opened before any player actions in that minigame can take place. Another example of sequential actions influencing logic will be in attack animations needing to finish before the next enemy/party member can start their turn.

3. **What happens if the player tries to interact during a beat/animation?** Should input be blocked during these moments, or should there be a way to skip/accelerate certain animations?
3.a: The design will be for most of these animations to be snappy, thus skipping the animations isn't necessary and inputs should be blocked/ignored during this time.

### Battle Start and Initialization

4. **What information should be displayed in the encounter message?** Should it show enemy names, encounter type, difficulty level, or just a thematic message?
4.a: For now, let's say there's a string in the encounter data that should be displayed at this time, that way some flavor can be injected on a by-encounter type basis, (like, "A gaggle of rats" or "An evil priest and his buddies").

5. **Should the initiative roll be visible to the player?** Should they see the turn order being calculated, or should it happen behind the scenes and then display the final turn order?
5.a: An animation for this would be cool, but is definitely a nice-to-have. For now simply showing the resulting turn order will do.

6. **How should the turn order display be updated during battle?** Should it update immediately after each turn, or only when a new turn starts?
6.a: Either is fine, after a new speed roll is done to figure out what the new turn order is, we can animate the turn order.

### Turn Highlighting and Visual Feedback

7. **What does "highlighting" mean visually?** Should it be a glow effect, color change, border, scale animation, or combination? Should different entities (party vs enemies) have different highlight styles?
7.a: Likely enemies and party members will 'highlight' differently. For enemies a highlight behind their sprite slightly larger than the size of their sprite will work. For party members a border would do fine. As a secondary highlight indicator, an arrow should animate around the screen when a selection is needed, this arrow should animate between selections (slightly above enemies, or slightly above party member UI) with a small amount of travel time.

8. **Should the highlighting persist for the entire turn, or just at the start?** Should it fade out once the action menu appears (for party members) or once the action begins (for enemies)?
8.a: On a party member turn, highlighting should persist for the turn. On the enemy turn it can be temporary. The Arrow should only appear when the player is selecting something, once the selection is made it should disappear.

### Enemy Turn Behavior

9. **What determines which action an enemy takes?** Is this based on AI logic, random selection, or predetermined patterns? Should the player see any indication of what the enemy is about to do before it happens?
9.a: This is somewhat TBD. If it turns out the combat system needs enemy action indication we can add it later, but likely not for alpha. The most that may happen is a 'wind-up' type action (say, if a dragon takes a turn, but instead of attacking/casting directly a message logs 'Dragon A takes a deep breath' they can infer a big fire-breath attack is likely coming).

10. **How should enemy animations vary by action type?** Should attacks, spells, and items have distinct animation styles? Should different enemy types have unique animation sets?
10.a: For alpha, we can keep to a single 'action' animation (likely just a bit of a wiggle). However, in the case of party equipment, certain equipment (say the wild mage's flame sword) may change some vfx (a splash of fire rather than a slash of physical damage).

11. **Should enemy actions be interruptible or skippable?** If a player has seen the same enemy action multiple times, can they speed it up?
11.a: No, actions should be snappy enough to not need this.

### Party Member Action Selection

12. **How should the action menu appear?** Should it slide in, fade in, pop up, or appear instantly? Should it appear near the active party member or in a fixed location?
12.a: A slide in to a fixed location should do for now.

13. **What happens if a party member is silenced or otherwise unable to use abilities?** Should the Spell option be disabled/greyed out, or should it be hidden entirely? Should there be visual feedback explaining why it's unavailable?
13.a: Silence should have a unique minigame-specific interation for each class. So the option will still be there, but the minigame will be harder in some way (it would be thematic for this to affect different classes more or less than others).

14. **Should there be visual feedback for unavailable actions?** For example, if a character has no items, should the Item option be disabled or show an empty inventory indicator?
14.a: Nah, it's ok for the Item option to show an empty list of items.

### Target Selection

15. **How should target selection work with multiple enemies/allies?** Should the player cycle through targets with arrow keys, click directly on entities, or use a combination? Should dead entities be selectable (for visual feedback) or excluded entirely?
15.a: For now, dead enemies will vanish. Dead party members can be selected for revives, but that's it. For the alpha, we'll focus on mouse events and not worry about other selection methods.

16. **What visual feedback should indicate valid vs invalid targets?** Should invalid targets be greyed out, have different cursor behavior, or be completely unselectable?
16.a: An invalid target either wouldn't be there anymore (in the case of dead enemies) or would be greyed out (in the case of dead party members) and unselectable.

17. **For minigames that require target selection mid-minigame, how should the transition feel?** Should the minigame UI fade out, slide away, or maintain some visual presence (like a minimized state)?
17.a: The minigame UI should mostly slide away if the action won't end the minigame, fully if the action will end the minigame.

### Minigame Integration

18. **How should minigame animations (opening/closing) coordinate with combat state?** Should combat UI elements fade out completely, or remain partially visible? Should the combat background change or remain the same?
18.a: Combat background should remain the same, UI elements can stay where they are as well, the minigame modal should slide in on top of all other elements. If necessary, we can add a shadow element to pull focus away from the combat UI while the minigame modal is up.

19. **What should happen if a minigame is interrupted (e.g., by a status effect or enemy action)?** Should the minigame state be preserved, or should it reset? Should there be visual feedback for the interruption?
19.a: The minigames will only happen on the player's turn, so combat is effectively paused for their duration. There's no need to account for interruptions that I can see.

20. **How should minigame results be communicated before the effect occurs?** Should there be a preview of damage/effects, or should the result only be visible when the effect actually applies?
20.a: This will depend on each class (but enumerating each interaction we have now may help us find patterns for future). Berserker: Active effect ranges (a very breif description of their effect ie 'fire damage' or 'silence') should display in a horizontal list above the berserker's party UI, when the minigame is opened they'll show in full including their actual target score ranges. Wild Mage: Effects will be added to different hand types by equipment, as such there may be icons that change (say, the fire sword changes one suit symbol into fire symbols to indicate fire damage), or there may be effects listed under the listed hand types. For the Time Wizard, most of the effects will be equipment driven (say, squares grant the entire party 2 speed), so all that will really change is the actual effects. For the Monk, effects (if any) should be listed in brief under each of the opponents cards alongside their condition (win loss tie).

### Death and State Transitions

21. **Should death animations be skippable?** If multiple entities die in quick succession (e.g., from an AoE attack), should their death animations play sequentially or simultaneously?
21.a: Death animations can play simultaneously in this case.

22. **What should happen to a dead party member's UI elements?** Should their display remain visible (greyed out) for the rest of combat, or should it be removed/hidden? Should their turn still appear in the turn order (greyed out) or be removed entirely?
22.a: Dead party members will be greyed out for the remainder of combat unless they are revived.

### Victory and Defeat

23. **What information should be included in the rewards display?** Should it show items, equipment, currency, experience (if applicable), or all of the above? Should rewards be displayed one at a time or all at once?
23.a: All of the above, rewards can be sorted by equipment (rare first), then consumables. Experience is not necessary, character growth can be handled by one-off attribute increases or equipment.

24. **Should there be a way to review combat statistics during or after battle?** Should players be able to see damage dealt, status effects applied, minigame performance, etc.?
24.a: Damage numbers or 'x effect applied' should appear when an attack or effect connects above the entity it applies to.

### Technical and Implementation

25. **How should animation states be managed?** Should there be a centralized animation manager, or should each entity manage its own animations? How should animation completion be detected and handled?
25.a: For animations, a basic implementation for sprite wiggling and flashing should do for now, no need for individual animation handlers. Down the line we may do some sprite swapping, but likely no full-blown animations. For VFX (sword swings, fire blasts, ice particles, etc) these should be a centralized manager so we can cue up a certain effect ID at a certain point and let it do it's thing.

26. **How should sound effects be prioritized and managed?** Should multiple sound effects be able to play simultaneously, or should some take priority? How should sound effects coordinate with visual beats?
26.a: There should be a sound effect manager that handles background music and sfx. For the alpha, and maybe even for full release, it can just have a single background track and a single track of sfx. From the rest of the code, we can just call out to this manager when we want to play a sound effect or change the background music. SFX and VFX that need to be synced will be triggered at the same time, it's up to the design of the vfx/sfx to sync up, we won't be dealing with that in code.

27. **What should happen if the player closes/minimizes the game during a battle?** Should the battle state be preserved, or should it reset? Should auto-save occur at specific points during combat?
27.a: Auto saves should occur at every player and enemy turn to maintain game state. If saving ends up slowing the game down at all that's a pre-release polish issue not something to consider for the alpha.

## Follow-Up Questions

### Silence and Minigame Interactions

28. **How should silence affect each class's minigame?** You mentioned class-specific interactions that make minigames harder. Can you provide examples for each class? For instance:
   - Berserker: Does silence reduce available effect ranges, limit hand value, or something else?
   - Time Wizard: Does silence reduce time limit, hide event symbols, or reduce board size?
   - Monk: Does silence reduce available moves, hide enemy cards, or something else?
   - Wild Mage: Does silence reduce hand size, limit discards, or something else?
28.a: *Key Point* We should design a system flexible enough for us to change our mind on some of these things without too much overhead.
   - Berserker: Silence should nullify the effect range mechanic.
   - Time Wizard: Silence will change all event symbols to a null symbol which just ends the minigame as if time had expired (no special effects).
   - Monk: Silence will remove special effects from enemy options.
   - Wild Mage: Silence will disallow discards.

### Dead Party Members and Turn Order

29. **Should dead party members still have turns in the turn order?** If a dead party member's turn comes up, should their turn be automatically skipped (with no UI interaction), or should they be removed from the turn order entirely? If they're removed, how should the turn order display handle this dynamically?
29.a: The dead party member should be removed from the turn order (after it disappears, the turn order will reflow to show the current order). If a party member is revived, the starting speed will be the speed of the current active entity + a typical turn speed roll. 

### Revive Mechanics

30. **How do revives work in combat?** You mentioned dead party members can be selected for revives. Is this:
   - An item action (e.g., "Revive Potion" that targets dead party members)?
   - An ability from a specific class?
   - Both?
   - Should there be visual feedback when hovering over a dead party member during target selection for a revive action?
30.a: Items should be able to revive, at least one single target and one full party. Some class effects may provide a revive effect as well (though none have been decided yet). *Key point* in any case the 'revive' logic should be reusable so both cases can be implemented without reworking the whole system. Visual feedback for targeting should be consistent (highlight and arrow, but keep the greyed out state).

### Minigame Result UI Implementation

31. **Where exactly should the minigame result previews appear?** For the Berserker's effect ranges above the party UI - should this be:
   - A persistent UI element that's always visible during combat (when effect ranges exist)?
   - Only visible when the Berserker's turn is active?
   - Only visible when the minigame is open?
   - Should it be part of the party member's individual display, or a separate floating element?
31.a: This should be visible when the berserker's turn is active and for a brief amount of time when a new effect is added if it's not already visible. This list will be a separate element that's "tied to" the berserker's party UI.

32. **How should the minigame result previews be structured?** For classes like Wild Mage and Monk that show effects under hand types or enemy cards - should these be:
   - Tooltips that appear on hover?
   - Persistent text/icons that are always visible?
   - Expandable/collapsible sections?
   - Should the format be consistent across all classes, or can each class have its own UI style?
23.a: These should be brief descriptions, if necessary we can add more description on hover in a tooltip. The tooltip UI should be consistent across classes.

### VFX Manager Implementation

33. **How should the VFX manager be structured?** You mentioned effect IDs that can be cued up. Should this be:
   - A registry system where effects are registered by ID (similar to MinigameRegistry)?
   - Effect IDs defined as constants or enums?
   - Should effects be able to take parameters (e.g., position, color, scale)?
   - How should the VFX manager handle cleanup when effects complete?
33.a: A registry system would be the idea. For effect IDs, an EffectIds enum makes the most sense to me (can be passed in to the manager when requesting an effect). A few basic effect parameters makes sense, possibly in a settings or configuration object to keep it tidy. The VFX manager should maintain a pool of 10 or so deactivated VFX nodes that are accessed as needed. If the whole pool is in use the VFX manager can greedily take whichever VFX node has been active for the longest and repurpose it.

34. **What information should be passed when triggering a VFX?** For example, when triggering a "fire damage" effect:
   - Should we pass the target entity's position/sprite location?
   - Should we pass damage amount (for scaling effects)?
   - Should we pass source entity (for directional effects)?
   - Should effects be able to attach to entities and follow them, or are they always world-space?
34.a: The location to center the effect at, a config object with any extra scale, color, etc information. VFX won't need to move once placed and playing, so we won't need to attach them to entities.

### Auto-Save Implementation

35. **When exactly should auto-save occur during a turn?** Should it be:
   - Before the turn starts (after turn order is determined)?
   - After the action is selected but before execution?
   - After the action completes but before effects resolve?
   - Should failed saves block turn progression, or should they fail silently and continue?
35.a: Auto saves should happen just after the turn order is determined. For now, failed saves should print a debug error and continue.

36. **What should be included in the battle auto-save state?** Should it save:
   - Current turn order and whose turn it is?
   - All entity states (HP, status effects, positions)?
   - Action selection state (if a player has selected an action but not confirmed)?
   - Minigame state (if a minigame is in progress)?
   - Should it be a full state snapshot or incremental changes?
36.a: A full snapshot of the current battle state would be ideal. *Key point* this battle state (including initiative, effects, hp/attribute values, minigame-specific state if any) should be made fairly accessible, ie a very simple straightforward data structure that can be used as the 'source of truth' for the rest of the systems.

### Wind-Up Messages and Future Planning

37. **Should we architect the system to support wind-up messages even if not implemented in alpha?** For example:
   - Should enemy actions have a "wind_up_message" field in their data structure?
   - Should the combat system have a hook for displaying messages before actions execute?
   - Or should this be deferred entirely until needed?
37.a: The action system should be flexible enough to enable a specific action script to 'log' a message to the battle screen.

## Architectural Direction Summary

Based on the vision and Q&A, here are the key architectural decisions that should guide the refactor:

### Core Principles

1. **Battle State as Source of Truth**: A clean, straightforward data structure that represents the complete battle state (turn order, entity states, HP, status effects, minigame-specific state). This should be easily serializable for auto-save and accessible to all systems.

2. **Delay-Based Timing System**: Configurable delay durations (constants/config) with sequential logic flow. Some delays overlap (sound + animation), but critical logic steps are sequential (minigame must fully open before input, attack animations must finish before next turn).

3. **Input Blocking**: Input is blocked/ignored during delays and animations. No skipping or acceleration needed - animations are designed to be snappy.

4. **Flexible, Extensible Systems**: Design systems that allow easy modification without major refactoring:
   - Silence system that can modify minigame behavior per class
   - Reusable revive logic (works for items and abilities)
   - Action system that can log messages (for wind-up messages)
   - VFX and sound systems that can be extended

### Key Systems to Implement

#### Battle State Manager
- Maintains complete battle state snapshot
- Serializable for auto-save (full snapshot after turn order determined)
- Accessible to all systems as source of truth
- Handles turn order calculation and updates
- Manages entity lifecycle (death, revival, removal from turn order)

#### Delay/Timing System
- Configurable delay durations (constants like `ACTION_MENU_DELAY_DURATION`)
- Sequential event coordination
- Animation completion detection
- Input blocking during delays

#### VFX Manager (Centralized)
- Registry pattern with `EffectIds` enum
- Pool of ~10 VFX nodes (greedy reuse if pool exhausted)
- Takes position and config object (scale, color, etc.)
- Effects are world-space, don't attach to entities

#### Sound Manager
- Handles BGM and SFX (single track each for alpha)
- Simple interface: call manager to play sound or change music
- SFX/VFX sync handled by design, not code

#### Action System
- Flexible enough for actions to log messages (wind-up support)
- Supports Attack, Spell/Ability, Item actions
- Handles target selection with consistent visual feedback
- Reusable revive logic

#### Turn Order System
- Dynamic updates after each turn
- Removes dead party members (reflows display)
- Revived members rejoin with current active entity speed + roll
- Animated updates when order changes

#### Minigame Integration
- Modal slides in on top of combat UI
- Maintains state during target selection (if needed mid-minigame)
- Class-specific silence interactions (flexible system)
- Result previews with consistent tooltip system

#### UI Systems
- Highlighting: Enemies (glow behind sprite), Party (border), Arrow (for selection)
- Party member displays: Grey out on death, remain visible
- Turn order display: Updates dynamically, removes dead members
- Action menu: Slides in to fixed location
- Target selection: Mouse-based, consistent highlight/arrow feedback
- Minigame result previews: Class-specific UI tied to party displays

### Refactor Approach

This refactor should focus on **establishing the foundation** rather than implementing every feature:

1. **Battle State Structure**: Create the clean data structure that will be the source of truth
2. **Core Managers**: Implement VFX manager, Sound manager, Delay system
3. **Turn Flow**: Refactor turn order and turn progression to support delays and sequential logic
4. **Action System**: Refactor action handling to be flexible and support the new flow
5. **UI Integration**: Update UI systems to work with delays, highlighting, and new flow

The goal is to create a **flexible, extensible foundation** that enables incremental development toward the full vision, rather than implementing everything at once.