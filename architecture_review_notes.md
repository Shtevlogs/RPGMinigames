# Architecture Review Notes

This is a review of the code archetecture as of 12/29/2025.

## Architecture Primer Notes

This section will cover my notes on subjects covered in ARCHITECTURE_PRIMER.md.

### Registry Pattern (MinigameRegistry)

Overall a good design, my only note would be to just pass in the GDScript as that can be used as a key in these dictionaries instead of the String that's being passed around now.

### Behavior Pattern (BaseClassBehavior)

We'll need refactor slightly, I'd like to see a BattleEntity passed in instead of varient. The BattleEntity can be a base class of the party members and enemies, but the ideal solution would be a separate object that the whole battle system can interact with directly without needing to figure out if it's a Character or EnemyData (as they'll mostly be interacting with the battle system in the same way). We'll have to have a larger discussion on how to proceed here.

Going forward we'll also have to be cognisent of how these behaviors interact with the BattleState as a source of truth.

### Composition Pattern (StatusEffectManager)

Owner should be a BattleEntity (see above).
No need to collect on_tick return values, see notes in next section.

### Polymorphism Pattern (StatusEffect)

StatusEffect on_tick should be an object. The cumulative_effects Dictionary in status_effect_manager tick_status_effects can probably be the same class of object. That object can then be returned into whatever is calling this.

Actually, instead of returning a tick result object at all, ticks should just apply their effects in the effect code. Enough of the BattleState should be accessible from these functions to do what they need to do.

We should also implement an on_remove function for these, in case there is logic that needs to happen as a status is removed.

### Combat System

Many of my other notes will affect this system. Overall, the structure is solid.

We should give some thought about how a BattleEntity (a shared class between both Character and EnemyData) would simplify the combat logic.

I see now that the minigame context classes are being turned back into dictionaries in _build_minigame_context. They should just be passed on into the minigame modal load_minigame function as MinigameContexts. The goal is that the minigame instances themselves have these objects to reference.

In _apply_minigame_result, that MinigameResult object should have an array of StatusEffect. That would be better than the array of dictionaries it currently has. Those status effects can be added directly to BattleEntities (or as it is now, Character and EnemyData) with the add_status_effect function.

Once these refactors are done, we will look at at combat.gd again to see if we can break any functionality out of here for better organization. Specifically I'm thinking the end-of-combat logic, run management, scene setting, turn management, saving, blocking and unblocking input, highlighting, input handling, turn order ui, minigame initialization, - I could go on. It's a lot of things for one file to do.

### Battle State Management

Looks good so far.

### Delay/Timing System

Looks good.

### VFX Manager

A solid placeholder to be extended later.

### Sound Manager

Looks good so far.

### Minigame System

We should be using the MinigameContext objects in here, we can cast them to the class-specific MinigameContexts in the subclasses.

In the subclasses will be where initializing effects will take place for my note above (line 40).

### Status Effect System

See my notes on "Composition Pattern (StatusEffectManager)" above.

### Manager Systems

No complaints here so far.

## Common Themes

- We should avoid passing strings around where possible, it's just best practice.
- The battle system should operate in a data-driven manner and downstream objects should react as the data changes. (Like a battle entity taking damage and generating an event that either the Character display or EnemyData reacts to with animations whatever else is necessary)
- Dictionaries are a good sign there should be some actual hard architecture and game design decisions made.
- Backward compatibility is not important now and will not be for a very long time.
- Match statements are a good sign that we're missing an opportunity to leverage classes and inheritance.