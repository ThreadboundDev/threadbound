using Godot;

/// <summary>
/// BLUE ARCHETYPE — Peak Suspend Jump, Thread Swing
/// </summary>
public partial class BlueArchetype : BaseArchetype
{
	private int _lastDirection = 1;

	// ──────────────────────── VISUAL REFERENCES ────────────────────────
	private ArchetypeUI _ui;

	// ──────────────────────── PEAK SUSPEND JUMP STATE ───────────────────────
	private bool _isSuspendedAtPeak = false;
	private float _peakSuspendTimer = 0.0f;
	private float _newVelocityY = 0.0f;  // Store current frame's vertical velocity for peak detection
	private float _previousVelocityY = 0.0f;  // Store previous frame's vertical velocity for peak detection
	[Export] public float JumpForce { get; set; } = 700.0f;
	[Export] public float PeakSuspendDuration { get; set; } = 0.5f;  // Time player suspends at jump peak

	// ──────────────────────── THREAD SWING STATE ───────────────────────
	private Node2D _threadSwingTarget = null;
	private bool _isSwinging = false;
	private float _swingAngle = 0.0f;
	private float _swingVelocity = 0.0f;
	[Export] public float SwingMaxRange { get; set; } = 300.0f;
	[Export] public float SwingGravity { get; set; } = 500.0f;
	[Export] public float SwingDamping { get; set; } = 0.95f;

	// ===================================================================
	// INITIALIZATION
	// ===================================================================
	protected override void InitializeArchetype()
	{
		ChargeGlowColor = ThreadType.BLUE_COLOR;

		// UI Component
		_ui = new ArchetypeUI();
		_ui.ParentNode = player;
		AddChild(_ui);

		// Set up global debug UI
		var debugUI = GetNode<DebugUI>("/root/DebugUI");
		if (debugUI != null)
		{
			debugUI.SetTargetNode(player);
			debugUI.UpdateDebug("BLUE: Ready");
		}

		GD.Print("[BLUE] Archetype loaded successfully");
	}

	// ===================================================================
	// PRIMARY ACTION: PEAK SUSPEND JUMP
	// ===================================================================
	public override void HandlePrimaryAction(ActionState state, float delta)
	{
		switch (state)
		{
			case ActionState.PRESSED:
				// Blue archetype: instant jump on press
				if (player.Call("is_on_floor").AsBool() || (float)player.Get("coyote_timer") > 0.0f)
				{
					var velocity = player.Velocity;
					velocity.Y = -JumpForce;
					player.Velocity = velocity;
					player.Set("coyote_timer", 0.0f);
					_previousVelocityY = -JumpForce;  // Set to negative to ensure peak detection works
					_newVelocityY = -JumpForce;
				}
				break;
			case ActionState.RELEASED:
			case ActionState.HOLDING:
				// No action needed for release/hold
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
	// THREAD MECHANIC: THREAD SWING
	// ===================================================================
	public override void ThreadMechanic(float delta)
	{
		HandleThreadSwing(delta);
	}

	private void HandleThreadSwing(float delta)
	{
		// TODO: Implement thread swing mechanic
		// Player can attach to blue-threaded objects and swing
		if (Input.IsActionJustPressed("Traversal"))
		{
			if (!_isSwinging)
			{
				// Try to attach to nearest blue thread target
				AttachToThreadTarget();
			}
			else
			{
				// Detach from swing
				DetachFromSwing();
			}
		}

		if (_isSwinging && _threadSwingTarget != null)
		{
			// Update swing physics
			UpdateSwingPhysics(delta);
		}
		else
		{
			_isSwinging = false;
		}
	}

	private void AttachToThreadTarget()
	{
		// Find nearest blue thread target in range
		Node2D nearestTarget = null;
		float nearestDist = SwingMaxRange;

		foreach (var target in GetTree().GetNodesInGroup("blue_thread"))
		{
			var targetNode = target as Node2D;
			if (targetNode != null)
			{
				float dist = player.GlobalPosition.DistanceTo(targetNode.GlobalPosition);
				if (dist < nearestDist)
				{
					nearestDist = dist;
					nearestTarget = targetNode;
				}
			}
		}

		if (nearestTarget != null)
		{
			_threadSwingTarget = nearestTarget;
			_isSwinging = true;
			_swingAngle = 0.0f;
			_swingVelocity = 0.0f;
		}
	}

	private void DetachFromSwing()
	{
		_isSwinging = false;
		_threadSwingTarget = null;
	}

	private void UpdateSwingPhysics(float delta)
	{
		if (_threadSwingTarget == null)
			return;

		Vector2 toTarget = _threadSwingTarget.GlobalPosition - player.GlobalPosition;
		float angle = Mathf.Atan2(toTarget.Y, toTarget.X);

		// Apply swing gravity
		_swingVelocity += SwingGravity * delta * Mathf.Sin(angle);
		_swingVelocity *= SwingDamping;

		// Update angle
		_swingAngle += _swingVelocity * delta;

		// Apply swing force to player
		Vector2 swingForce = new Vector2(Mathf.Cos(_swingAngle), Mathf.Sin(_swingAngle)) * _swingVelocity * 100.0f;
		player.Velocity += swingForce * delta;
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

		// Reset when on ground
		if (player.Call("is_on_floor").AsBool())
		{
			_previousVelocityY = 0.0f;
			_isSuspendedAtPeak = false;  // Reset suspend state on ground
		}
		else
		{
			_previousVelocityY = _newVelocityY;
		}
		_newVelocityY = player.Velocity.Y;

		// Detect peak of jump: previous velocity was negative (ascending), current is positive (descending)
		if (!_isSuspendedAtPeak && _previousVelocityY < 0.0f && _newVelocityY >= 0.0f)
		{
			_isSuspendedAtPeak = true;
			_peakSuspendTimer = PeakSuspendDuration;
		}

		// Apply peak suspend effect
		if (_isSuspendedAtPeak)
		{
			_peakSuspendTimer -= delta;
			if (_peakSuspendTimer <= 0.0f)
			{
				_isSuspendedAtPeak = false;
			}
			else
			{
				// Hold the player at the peak by setting velocity to 0
				var velocity = player.Velocity;
				velocity.Y = 0.0f;
				player.Velocity = velocity;
			}
		}
	}
}
