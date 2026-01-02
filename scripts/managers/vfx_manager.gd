extends Node

# VFXManager - Centralized visual effects system using registry pattern
# Maintains pool of VFX nodes and handles effect playback

const POOL_SIZE: int = 10

var vfx_pool: Array[Node] = []
var active_vfx: Array[Node] = []  # Track active VFX for greedy reuse

func _ready() -> void:
    # Initialize VFX node pool
    _initialize_pool()

func _initialize_pool() -> void:
    """Initialize pool of VFX nodes."""
    vfx_pool.clear()
    active_vfx.clear()
    
    # Create pool of placeholder nodes (TODO: Replace with actual VFX nodes)
    for i in range(POOL_SIZE):
        var vfx_node: Node = Node.new()
        vfx_node.name = "VFXNode_%d" % i
        vfx_node.set_script(null)  # No script for now
        vfx_pool.append(vfx_node)

func play_effect(_effect_id: EffectIds.EffectIds, position: Vector2, config: VFXConfig = null) -> void:
    """Play a visual effect at the specified position."""
    # Get VFX node from pool
    var vfx_node: Node = _get_vfx_node()
    if vfx_node == null:
        push_warning("VFXManager: No available VFX nodes in pool")
        return
    
    # Configure VFX node (TODO: Implement actual VFX logic)
    # For now, this is a placeholder
    vfx_node.position = position
    
    # Add to active list
    active_vfx.append(vfx_node)
    
    # TODO: Start actual VFX animation
    # For now, just schedule cleanup after duration
    var duration: float = config.duration if config != null else 1.0
    _schedule_cleanup(vfx_node, duration)

func _get_vfx_node() -> Node:
    """Get a VFX node from the pool, reusing longest-active if pool exhausted."""
    # First, try to get from pool
    if not vfx_pool.is_empty():
        return vfx_pool.pop_back()
    
    # Pool exhausted - greedily reuse longest-active node
    if not active_vfx.is_empty():
        var longest_active: Node = active_vfx[0]
        active_vfx.erase(longest_active)
        return longest_active
    
    # No nodes available - create new one (shouldn't happen with proper pool size)
    push_warning("VFXManager: Creating new VFX node (pool exhausted)")
    var new_node: Node = Node.new()
    new_node.name = "VFXNode_New"
    return new_node

func _schedule_cleanup(vfx_node: Node, duration: float) -> void:
    """Schedule cleanup of VFX node after duration."""
    # TODO: Use actual animation completion signal
    # For now, use timer
    await get_tree().create_timer(duration).timeout
    _return_vfx_node(vfx_node)

func _return_vfx_node(vfx_node: Node) -> void:
    """Return VFX node to pool."""
    # Remove from active list
    active_vfx.erase(vfx_node)
    
    # Reset node state (TODO: Reset actual VFX properties)
    vfx_node.position = Vector2.ZERO
    
    # Return to pool
    if vfx_pool.size() < POOL_SIZE:
        vfx_pool.append(vfx_node)
    else:
        # Pool full - queue free
        vfx_node.queue_free()
