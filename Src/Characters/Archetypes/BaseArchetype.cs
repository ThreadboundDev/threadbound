using Godot;

/// <summary>
/// Base class for all archetypes
/// Provides common interface: primary_action, secondary_action, thread_mechanic
/// </summary>
public partial class BaseArchetype : Node
{
	// Player reference - set in _EnterTree()
	protected CharacterBody2D player;

	// Charge glow color - override in subclasses for archetype-specific color
	[Export] public Color ChargeGlowColor { get; set; } = new Color(1, 0, 0, 1);

	// ===================================================================
	// INITIALIZATION
	// ===================================================================
	public override void _EnterTree()
	{
		player = GetParent() as CharacterBody2D;
		if (player == null)
		{
			GD.PushError($"{GetType().Name}: Parent is NOT CharacterBody2D!");
			return;
		}
		InitializeArchetype();
	}

	// Override in subclasses for archetype-specific initialization
	protected virtual void InitializeArchetype()
	{
	}

	// ===================================================================
	// ARCHETYPE ACTION INTERFACE
	// ===================================================================

	public enum ActionState
	{
		PRESSED,    // Just pressed
		RELEASED,   // Just released
		HOLDING     // Currently held (called every frame while held)
	}

	/// <summary>
	/// Primary action (typically jump) - called when primary input state changes
	/// state: ActionState (PRESSED, RELEASED, or HOLDING)
	/// delta: Time since last frame
	/// </summary>
	public virtual void HandlePrimaryAction(ActionState state, float delta)
	{
	}

	/// <summary>
	/// Secondary action (typically dash) - called when secondary input state changes
	/// state: ActionState (PRESSED, RELEASED, or HOLDING)
	/// delta: Time since last frame
	/// </summary>
	public virtual void HandleSecondaryAction(ActionState state, float delta)
	{
	}

	// Legacy methods for backward compatibility (deprecated)
	public virtual void PrimaryAction(float delta)
	{
	}

	public virtual void SecondaryAction(float delta)
	{
	}

	/// <summary>
	/// Thread mechanic - called every frame to handle thread-based abilities
	/// Examples: reverse grapple, thread swing, double-jump
	/// </summary>
	public virtual void ThreadMechanic(float delta)
	{
	}

	/// <summary>
	/// Process archetype-specific mechanics - called every frame
	/// </summary>
	public virtual void ProcessMechanics(float delta, CharacterBody2D p)
	{
	}

	/// <summary>
	/// Called when ability cooldown timer reaches zero
	/// Override in subclasses to handle cooldown completion (e.g., reset dash state)
	/// </summary>
	public virtual void OnAbilityCooldownComplete()
	{
	}
}
