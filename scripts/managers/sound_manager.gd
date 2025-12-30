extends Node

# NOTE: This is an autoload singleton. Do not add class_name.
# Autoload singletons are accessed globally by their autoload name (SoundManager).

# SoundManager - Centralized sound system for BGM and SFX
# Single BGM track and single SFX track for alpha

# Sound ID Constants
const SFX_ACTION_MENU_HOVER: String = "action_menu_hover"
const SFX_ACTION_MENU_SELECT: String = "action_menu_select"
const SFX_TARGET_SELECTION_HIGHLIGHT: String = "target_selection_highlight"
const SFX_TARGET_SELECTION_SELECT: String = "target_selection_select"
const SFX_PLAYER_ATTACK: String = "player_attack"
const SFX_ENEMY_ATTACK: String = "enemy_attack"
const SFX_MINIGAME_OPEN: String = "minigame_open"
const SFX_MINIGAME_CLOSE: String = "minigame_close"
const SFX_MINIGAME_ACTION: String = "minigame_action"
const SFX_ENEMY_DEATH: String = "enemy_death"
const SFX_PARTY_DEATH: String = "party_death"
const SFX_VICTORY: String = "victory"
const SFX_DEFEAT: String = "defeat"
const SFX_STATUS_EFFECT: String = "status_effect"

var bgm_player: AudioStreamPlayer = null
var sfx_player: AudioStreamPlayer = null

func _ready() -> void:
    # Create BGM player
    bgm_player = AudioStreamPlayer.new()
    bgm_player.name = "BGMPlayer"
    bgm_player.volume_db = 0.0
    add_child(bgm_player)
    
    # Create SFX player
    sfx_player = AudioStreamPlayer.new()
    sfx_player.name = "SFXPlayer"
    sfx_player.volume_db = 0.0
    add_child(sfx_player)

func play_sfx(_sound_id: String) -> void:
    """Play a sound effect by ID."""
    # TODO: Load and play actual sound file
    # For now, this is a placeholder
    if sfx_player == null:
        push_warning("SoundManager: SFX player not initialized")
        return
    
    # TODO: Load sound resource based on sound_id
    # var sound_resource = load("res://sounds/sfx/%s.ogg" % sound_id)
    # if sound_resource != null:
    #     sfx_player.stream = sound_resource
    #     sfx_player.play()
    pass

func change_bgm(_music_id: String) -> void:
    """Change background music by ID."""
    # TODO: Load and play actual music file
    # For now, this is a placeholder
    if bgm_player == null:
        push_warning("SoundManager: BGM player not initialized")
        return
    
    # TODO: Load music resource based on music_id
    # var music_resource = load("res://sounds/bgm/%s.ogg" % music_id)
    # if music_resource != null:
    #     bgm_player.stream = music_resource
    #     bgm_player.play()
    pass

func set_sfx_volume(volume: float) -> void:
    """Set SFX volume (0.0 to 1.0)."""
    if sfx_player != null:
        sfx_player.volume_db = linear_to_db(clamp(volume, 0.0, 1.0))

func set_bgm_volume(volume: float) -> void:
    """Set BGM volume (0.0 to 1.0)."""
    if bgm_player != null:
        bgm_player.volume_db = linear_to_db(clamp(volume, 0.0, 1.0))
