using Godot;

/// <summary>
/// YELLOW ARCHETYPE — Double-Jump
/// </summary>
public partial class YellowArchetype : BaseArchetype
{
	private int _lastDirection = 1;

	// ──────────────────────── VISUAL REFERENCES ────────────────────────
	private ArchetypeUI _ui;

	// ──────────────────────── DOUBLE-JUMP THREAD STATE ───────────────────────
	private int _jumpCount = 0;

	// ===================================================================
	// INITIALIZATION
	// ===================================================================
	protected override void InitializeArchetype()
	{
		_jumpCount = 0;
		ChargeGlowColor = ThreadType.YELLOW_COLOR;

		// UI Component
		_ui = new ArchetypeUI();
		_ui.ParentNode = player;
		AddChild(_ui);

		// Set up global debug UI
		var debugUI = GetNode<DebugUI>("/root/DebugUI");
		if (debugUI != null)
		{
			debugUI.SetTargetNode(player);
			debugUI.UpdateDebug("YELLOW: Ready");
		}

		GD.Print("[YELLOW] Archetype loaded successfully");
	}

	// ===================================================================
	// PRIMARY ACTION: DOUBLE JUMP
	// ===================================================================
	public override void HandlePrimaryAction(ActionState state, float delta)
	{
		switch (state)
		{
			case ActionState.PRESSED:
				HandleDoubleJump();
				break;
			case ActionState.RELEASED:
			case ActionState.HOLDING:
				// No action needed
				break;
		}
	}

	// ===================================================================
	// SECONDARY ACTION: None
	// ===================================================================
	public override void HandleSecondaryAction(ActionState state, float delta)
	{
	}

	// ===================================================================
	// THREAD MECHANIC: None
	// ===================================================================
	public override void ThreadMechanic(float delta)
	{
	}

	private void HandleDoubleJump()
	{
		// Double jump is available when in air and not already used
		if (_jumpCount < 3)
		{
			var velocity = player.Velocity;
			velocity.Y = -(float)player.Get("JumpForce");
			player.Velocity = velocity;
			_jumpCount++;
		}
	}

	// ===================================================================
	// PROCESS MECHANICS
	// ===================================================================
	public override void ProcessMechanics(float delta, CharacterBody2D p)
	{
		if (player == null)
			return;

		float hInput = Input.GetAxis("move_left", "move_right");
		if (hInput != 0)
			_lastDirection = (int)Mathf.Sign(hInput);

		if (player.Call("is_on_floor").AsBool())
		{
			_jumpCount = 0;
		}
	}
}
