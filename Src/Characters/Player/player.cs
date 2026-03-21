using Godot;
using System;

public partial class Player : CharacterBody2D
{
	// ===============================
	// NODES
	// ===============================
	private AnimatedSprite2D _playerAnimation;
	private Node _camera;
	private Sprite2D _glowSprite;
	private Timer _abilityCooldownTimer;

	// ===============================
	// TUNABLES
	// ===============================
	[Export] public float Speed { get; set; } = 500.0f;
	[Export] public float AirControlMult { get; set; } = 0.75f;
	[Export] public float Gravity { get; set; } = 1600.0f;
	[Export] public float MaxFallSpeed { get; set; } = 1000.0f;
	[Export] public float CoyoteTime { get; set; } = 0.12f;
	[Export] public float LookOffset { get; set; } = 60.0f;
	[Export] public float LookSpeed { get; set; } = 10.0f;
	[Export] public float HoldDuration { get; set; } = 1.0f;

	// Glow configuration (shared across all archetypes)
	[Export] public float IdleGlowWidth { get; set; } = 1.2f;
	[Export] public float IdleGlowIntensity { get; set; } = 0.35f;
	[Export] public float ChargeGlowMaxWidth { get; set; } = 4.0f;
	[Export] public float ChargeGlowMaxIntensity { get; set; } = 1.2f;
	[Export] public float JumpForce { get; set; } = 700.0f;

	// ===============================
	// STATE
	// ===============================
	public float CoyoteTimer { get; set; } = 0.0f;
	private int _lastDirection = 1;

	// Exposed for GDScript compatibility (camera scripts)
	public int last_direction => _lastDirection;
	private bool _isNearInteractable = false;
	private Node _currentSelector = null;
	private float _currentLookOffsetY = 0.0f;
	private float _holdTimer = 0.0f;

	// Charge ratios for glow effects (set by archetypes)
	private float _jumpChargeRatio = 0.0f;
	private float _dashChargeRatio = 0.0f;
	private Color _baseGlowColor = ThreadType.RED_COLOR;
	private float _baseGlowWidth = 1.2f;
	private float _baseGlowIntensity = 0.35f;
	private Color _defaultGlowColor = ThreadType.RED_COLOR;
	private float _defaultGlowWidth = 1.2f;
	private float _defaultGlowIntensity = 0.35f;
	private Color _currentChargeGlowColor = ThreadType.RED_COLOR;

	// Archetype - typed as BaseArchetype
	private BaseArchetype _archetype = null;

	// ===============================
	// INITIALIZATION
	// ===============================
	public override void _Ready()
	{
		// Get node references
		_playerAnimation = GetNode<AnimatedSprite2D>("Player Animation");
		_camera = GetNodeOrNull("../Camera Master/Camera2D/PhantomCameraHost2D/MainFollowCam");
		_glowSprite = GetNode<Sprite2D>("GlowSprite");
		_abilityCooldownTimer = GetNode<Timer>("AbilityCooldownTimer");

		// Connect ability cooldown timer timeout signal
		if (_abilityCooldownTimer != null)
		{
			_abilityCooldownTimer.Timeout += OnAbilityCooldownTimeout;
		}

		// Set default archetype to Red
		SetArchetype(ThreadType.RED);
	}

	// --------------------------------------------------------------
	// MAIN LOOP
	// --------------------------------------------------------------
	public override void _PhysicsProcess(double delta)
	{
		float dt = (float)delta;

		// ---- GRAVITY + COYOTE ----
		if (!IsOnFloor())
		{
			var vel = Velocity;
			vel.Y += Gravity * dt;
			if (vel.Y > MaxFallSpeed)
				vel.Y = MaxFallSpeed;
			Velocity = vel;
			CoyoteTimer -= dt;
		}
		else
		{
			CoyoteTimer = CoyoteTime;
		}

		// ---- ARCHETYPE ACTIONS ----
		if (_archetype != null)
		{
			// Primary action (Jump) - handle PRESSED and RELEASED independently
			if (Input.IsActionJustPressed("Jump"))
				_archetype.HandlePrimaryAction(BaseArchetype.ActionState.PRESSED, dt);
			if (Input.IsActionJustReleased("Jump"))
				_archetype.HandlePrimaryAction(BaseArchetype.ActionState.RELEASED, dt);
			// HOLDING is called every frame while button is held (but not on press/release frames)
			if (Input.IsActionPressed("Jump") && !Input.IsActionJustPressed("Jump") && !Input.IsActionJustReleased("Jump"))
				_archetype.HandlePrimaryAction(BaseArchetype.ActionState.HOLDING, dt);

			// Secondary action (Dash) - handle PRESSED and RELEASED independently
			if (Input.IsActionJustPressed("Dash"))
				_archetype.HandleSecondaryAction(BaseArchetype.ActionState.PRESSED, dt);
			if (Input.IsActionJustReleased("Dash"))
				_archetype.HandleSecondaryAction(BaseArchetype.ActionState.RELEASED, dt);
			// HOLDING is called every frame while button is held (but not on press/release frames)
			if (Input.IsActionPressed("Dash") && !Input.IsActionJustPressed("Dash") && !Input.IsActionJustReleased("Dash"))
				_archetype.HandleSecondaryAction(BaseArchetype.ActionState.HOLDING, dt);

			// Thread mechanic (called every frame)
			_archetype.ThreadMechanic(dt);

			// Process archetype mechanics (called every frame)
			_archetype.ProcessMechanics(dt, this);
		}

		// ---- HORIZONTAL INPUT ----
		float horizontalInput = Input.GetAxis("move_left", "move_right");
		if (horizontalInput != 0)
			_lastDirection = (int)Mathf.Sign(horizontalInput);

		// ---- BASE MOVEMENT — ALWAYS RUNS ----
		float control = IsOnFloor() ? 1.0f : AirControlMult;
		// Only apply base movement if archetype isn't controlling velocity (e.g., during dash)
		bool archetypeControlling = _archetype is RedArchetype redArch && redArch.IsDashing;
		if (!archetypeControlling)
		{
			var vel = Velocity;
			vel.X = Speed * horizontalInput * control;
			Velocity = vel;
		}

		// ---- ARCHETYPE SELECTION ----
		if (_isNearInteractable && _currentSelector != null && Input.IsActionJustPressed("move_up"))
		{
			// Try to get the ArchetypeColor from the selector
			if (_currentSelector is ArchetypeSelector selector)
			{
				SetArchetype(selector.ArchetypeColor);
			}
			else
			{
				// Fallback for GDScript selectors
				string color = (string)_currentSelector.Get("Color");
				SetArchetype(color);
			}
		}

		// ---- LOOK / INTERACT ----
		if (_camera != null)
		{
			Vector2 cur = _camera.Get("follow_offset").AsVector2();
			float targetY = 0.0f;

			bool isDashing = _archetype is RedArchetype redArchDash && redArchDash.IsDashing;

			if (Input.IsActionPressed("move_up") && !isDashing)
			{
				_holdTimer += dt;
				if (_holdTimer >= HoldDuration && !_isNearInteractable)
					targetY = -LookOffset;
			}
			else if (Input.IsActionPressed("move_down") && !isDashing)
			{
				_holdTimer += dt;
				if (_holdTimer >= HoldDuration)
					targetY = LookOffset;
			}
			else
			{
				_holdTimer = 0.0f;
			}

			_currentLookOffsetY = Mathf.Lerp(_currentLookOffsetY, targetY, dt * LookSpeed);
			_camera.Call("set_follow_offset", new Vector2(cur.X, _currentLookOffsetY));
		}

		// ---- FINAL PHYSICS MOVE ----
		MoveAndSlide();

		// ---- ANIMATIONS ----
		UpdateAnimations(horizontalInput);
	}

	public override void _Process(double delta)
	{
		if (Input.IsActionJustPressed("ui_cancel"))
		{
			GetTree().Quit();
		}

		if (_glowSprite != null && _playerAnimation != null && _playerAnimation.SpriteFrames != null)
		{
			var tex = _playerAnimation.SpriteFrames.GetFrameTexture(_playerAnimation.Animation, _playerAnimation.Frame);
			_glowSprite.Texture = tex;
			_glowSprite.FlipH = _playerAnimation.FlipH;
			_glowSprite.Position = _playerAnimation.Position;
			_glowSprite.Scale = _playerAnimation.Scale;
		}
		ApplyChargeGlow();

		// Radial menu hold check (polling for hold/release)
		var menu = GetTree().GetFirstNodeInGroup("radial_menu") as RadialMenu;
		if (menu != null)
		{
			menu.UpdateHoldState(Input.IsActionPressed("open_menu"));
		}
	}

	// --------------------------------------------------------------
	// GLOW EFFECTS
	// --------------------------------------------------------------
	private void ApplyChargeGlow()
	{
		if (_glowSprite == null || _glowSprite.Material == null || _archetype == null)
			return;

		float level = Mathf.Clamp(Mathf.Max(_jumpChargeRatio, _dashChargeRatio), 0.0f, 1.0f);
		var mat = _glowSprite.Material as ShaderMaterial;
		if (mat == null)
			return;

		float targetWidth = Mathf.Lerp(_baseGlowWidth, ChargeGlowMaxWidth, level);
		float targetIntensity = Mathf.Lerp(_baseGlowIntensity, ChargeGlowMaxIntensity, level);
		mat.SetShaderParameter("glow_width", targetWidth);
		mat.SetShaderParameter("glow_intensity", targetIntensity);

		if (level > 0.01f)
			mat.SetShaderParameter("glow_color", _archetype.ChargeGlowColor);
		else
			mat.SetShaderParameter("glow_color", _baseGlowColor);
	}

	public void SetDashChargeLevel(float level)
	{
		_dashChargeRatio = Mathf.Clamp(level, 0.0f, 1.0f);
	}

	public void SetJumpChargeLevel(float level)
	{
		_jumpChargeRatio = Mathf.Clamp(level, 0.0f, 1.0f);
	}

	/// <summary>
	/// Start ability cooldown timer - called by archetypes
	/// </summary>
	public void StartAbilityCooldown(float duration)
	{
		if (_abilityCooldownTimer != null)
		{
			_abilityCooldownTimer.WaitTime = duration;
			_abilityCooldownTimer.Start();
		}
	}

	private void SetBaseGlow(Color color, float width, float intensity)
	{
		_baseGlowColor = color;
		_baseGlowWidth = width;
		_baseGlowIntensity = intensity;

		if (_glowSprite != null && _glowSprite.Material != null && Mathf.Max(_jumpChargeRatio, _dashChargeRatio) <= 0.01f)
		{
			var mat = _glowSprite.Material as ShaderMaterial;
			if (mat != null)
			{
				mat.SetShaderParameter("glow_color", color);
				mat.SetShaderParameter("glow_width", width);
				mat.SetShaderParameter("glow_intensity", intensity);
			}
		}
	}

	// --------------------------------------------------------------
	// ANIMATIONS
	// --------------------------------------------------------------
	private void UpdateAnimations(float dir)
	{
		bool isDashing = _archetype is RedArchetype redArchAnim && redArchAnim.IsDashing;

		if (isDashing && _playerAnimation.SpriteFrames.HasAnimation("Dash"))
		{
			_playerAnimation.Play("Dash");
		}
		else if (!IsOnFloor() && _playerAnimation.SpriteFrames.HasAnimation("Jump"))
		{
			_playerAnimation.Play("Jump");
		}
		else if (dir != 0 && _playerAnimation.SpriteFrames.HasAnimation("Walk"))
		{
			_playerAnimation.Play("Walk");
		}
		else if (_playerAnimation.SpriteFrames.HasAnimation("Idle"))
		{
			_playerAnimation.Play("Idle");
		}

		if (Velocity.X != 0)
		{
			_playerAnimation.FlipH = Velocity.X < 0;
		}
	}

	// --------------------------------------------------------------
	// INTERACTABLES
	// --------------------------------------------------------------
	public void OnInteractableEntered(Area2D area)
	{
		_isNearInteractable = true;
		_currentSelector = area;
	}

	public void OnInteractableExited(Area2D area)
	{
		_isNearInteractable = false;
		if (_currentSelector == area)
			_currentSelector = null;
	}

	private void OnAbilityCooldownTimeout()
	{
		// Call archetype callback when cooldown completes
		if (_archetype != null)
			_archetype.OnAbilityCooldownComplete();
	}

	// --------------------------------------------------------------
	// ARCHETYPE MANAGEMENT
	// --------------------------------------------------------------
	public void SetArchetype(string color)
	{
		if (_archetype != null)
		{
			RemoveChild(_archetype);
			_archetype.QueueFree();
		}

		switch (color)
		{
			case ThreadType.RED:
				_archetype = new RedArchetype();
				break;
			case ThreadType.BLUE:
				_archetype = new BlueArchetype();
				break;
			case ThreadType.YELLOW:
				_archetype = new YellowArchetype();
				break;
			default:
				GD.PushError($"Unknown archetype color: {color}");
				return;
		}

		if (_archetype != null)
		{
			AddChild(_archetype);  // _EnterTree() runs, which calls InitializeArchetype()
			// Set glow from archetype's color and player's glow configuration
			Color archetypeColor = ThreadType.GetColor(color);
			SetBaseGlow(archetypeColor, IdleGlowWidth, IdleGlowIntensity);
		}
	}
}
