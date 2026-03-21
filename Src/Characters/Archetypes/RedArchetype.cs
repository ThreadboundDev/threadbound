using Godot;
using System;

/// <summary>
/// RED ARCHETYPE — Charge Jump, Charge Dash, Reverse Grapple
/// </summary>
public partial class RedArchetype : BaseArchetype
{
	// ──────────────────────── VISUAL REFERENCES ────────────────────────
	private AnimatedSprite2D _animSprite;
	private Line2D _threadLine;
	private ArchetypeUI _ui;

	// ──────────────────────── REVERSE GRAPPLE STATE ───────────────────────
	private RigidBody2D _currentGrappleTarget = null;
	private bool _connected = false;
	private float _currentSlack = 0.0f;

	// ──────────────────────── CHARGE JUMP STATE ───────────────────────
	private bool _isChargingJump = false;
	private float _jumpChargeTimer = 0.0f;
	private float _jumpChargeRatio = 0.0f;
	[Export] public float JumpChargeMaxTime { get; set; } = 0.9f;
	[Export] public float JumpChargeMinForce { get; set; } = 700.0f;
	[Export] public float JumpChargeMaxForce { get; set; } = 1800.0f;

	// ──────────────────────── CHARGE DASH STATE ───────────────────────
	public bool IsDashing { get; private set; } = false;
	private bool _isChargingDash = false;
	private float _chargeDashTimer = 0.0f;
	private float _dashCharge = 0.0f;
	private int _lastDirection = 1;
	private float _dashSpeed = 0.0f;
	[Export] public float ChargeDashMaxTime { get; set; } = 2.0f;
	[Export] public float ChargeDashMinSpeed { get; set; } = 600.0f;
	[Export] public float ChargeDashMaxSpeed { get; set; } = 1800.0f;
	[Export] public float ChargeDashMinDuration { get; set; } = 0.1f;
	[Export] public float ChargeDashMaxDuration { get; set; } = 0.3f;

	// ──────────────────────── REVERSE GRAPPLE TUNABLES ───────────────────────
	[Export] public float MaxSlack { get; set; } = 50.0f;
	[Export] public float SlackTakeRate { get; set; } = 380.0f;
	[Export] public float SlackRestoreRate { get; set; } = 100.0f;
	[Export] public float YankForce { get; set; } = 1600.0f;
	[Export] public float GrappleSlowFactor { get; set; } = 0.15f;
	[Export] public float GrappleMaxRange { get; set; } = 850.0f;
	[Export] public float ScreenShakeSmall { get; set; } = 3.0f;
	[Export] public float ScreenShakeBig { get; set; } = 8.0f;
	[Export] public float PullVelThreshold { get; set; } = 35.0f;
	[Export] public float TautStopDist { get; set; } = 150.0f;
	[Export] public float MaxTotalStretchMult { get; set; } = 1.0f;

	// ===================================================================
	// INITIALIZATION
	// ===================================================================
	protected override void InitializeArchetype()
	{
		ChargeGlowColor = ThreadType.RED_COLOR;

		_animSprite = player.GetNodeOrNull<AnimatedSprite2D>("Player Animation");
		if (_animSprite == null)
		{
			GD.PushError("RedArchetype: 'Player Animation' node not found!");
			return;
		}

		// UI Component
		_ui = new ArchetypeUI();
		_ui.ParentNode = player;
		AddChild(_ui);

		// Set up global debug UI
		var debugUI = GetNode<DebugUI>("/root/DebugUI");
		if (debugUI != null)
		{
			debugUI.SetTargetNode(player);
			debugUI.UpdateDebug("RED: Ready");
		}

		// Thread line visual
		_threadLine = new Line2D();
		_threadLine.Width = 3.0f;
		_threadLine.DefaultColor = ThreadType.RED_COLOR;
		var color = _threadLine.DefaultColor;
		color.A = 0.8f;
		_threadLine.DefaultColor = color;
		_threadLine.Visible = false;
		player.AddChild(_threadLine);

		// Connect to grapple platforms
		foreach (var plat in GetTree().GetNodesInGroup("red_grapple"))
		{
			var platNode = plat as Node;
			if (platNode != null && platNode.HasNode("DetectionArea"))
			{
				var area = platNode.GetNode<Area2D>("DetectionArea");
				area.BodyEntered += (body) => OnDetectionEntered(body, platNode);
				area.BodyExited += (body) => OnDetectionExited(body, platNode);
			}
		}

		GD.Print("[RED] Archetype loaded successfully");
	}

	// ===================================================================
	// PRIMARY ACTION: CHARGE JUMP
	// ===================================================================
	public override void HandlePrimaryAction(ActionState state, float delta)
	{
		switch (state)
		{
			case ActionState.PRESSED:
				StartJumpCharge();
				break;
			case ActionState.RELEASED:
				if (player.Call("is_on_floor").AsBool() || (float)player.Get("coyote_timer") > 0.0f)
					PerformChargedJump();
				else
					CancelJumpCharge();
				break;
			case ActionState.HOLDING:
				if (_isChargingJump)
				{
					if (player.Call("is_on_floor").AsBool() || (float)player.Get("coyote_timer") > 0.0f)
					{
						_jumpChargeTimer = Mathf.Min(_jumpChargeTimer + delta, JumpChargeMaxTime);
						_jumpChargeRatio = Mathf.Clamp(_jumpChargeTimer / JumpChargeMaxTime, 0.0f, 1.0f);
						if (player.HasMethod("set_jump_charge_level"))
							player.Call("set_jump_charge_level", _jumpChargeRatio);
					}
					else
					{
						_jumpChargeRatio = 0.0f;
						if (player.HasMethod("set_jump_charge_level"))
							player.Call("set_jump_charge_level", 0.0f);
					}
				}
				break;
		}
	}

	private void StartJumpCharge()
	{
		_isChargingJump = true;
		_jumpChargeTimer = 0.0f;
		_jumpChargeRatio = 0.0f;
	}

	private void PerformChargedJump()
	{
		if (!_isChargingJump)
			return;

		float charge = Mathf.Clamp(_jumpChargeRatio, 0.0f, 1.0f);
		float force = Mathf.Lerp(JumpChargeMinForce, JumpChargeMaxForce, charge);
		var velocity = player.Velocity;
		velocity.Y = -force;
		player.Velocity = velocity;
		player.Set("coyote_timer", 0.0f);
		CancelJumpCharge();
	}

	private void CancelJumpCharge()
	{
		_isChargingJump = false;
		_jumpChargeTimer = 0.0f;
		_jumpChargeRatio = 0.0f;
		if (player.HasMethod("set_jump_charge_level"))
			player.Call("set_jump_charge_level", 0.0f);
	}

	// ===================================================================
	// SECONDARY ACTION: CHARGE DASH
	// ===================================================================
	public override void HandleSecondaryAction(ActionState state, float delta)
	{
		HandleChargeDash(state, delta);
	}

	private void HandleChargeDash(ActionState state, float delta)
	{
		// Block dash if connected to grapple
		if (_connected && state == ActionState.PRESSED)
			return;

		switch (state)
		{
			case ActionState.PRESSED:
				// Start charging dash
				if (!IsDashing)
				{
					_isChargingDash = true;
					_chargeDashTimer = 0.0f;
					_dashCharge = 0.0f;
					UpdatePlayerDashCharge(0.0f);
				}
				break;
			case ActionState.RELEASED:
				// Release dash - set IsDashing to true
				if (_isChargingDash)
				{
					IsDashing = true;
					_isChargingDash = false;
					_dashSpeed = Mathf.Lerp(ChargeDashMinSpeed, ChargeDashMaxSpeed, _dashCharge);
					player.Velocity = new Vector2(_lastDirection * _dashSpeed, 0);
					// Start ability cooldown timer in player (0.2 second dash duration)
					if (player.HasMethod("start_ability_cooldown"))
						player.Call("start_ability_cooldown", 0.2f);
					UpdatePlayerDashCharge(0.0f);
				}
				break;
			case ActionState.HOLDING:
				// Continue charging while held
				if (_isChargingDash)
				{
					_chargeDashTimer += delta;
					_dashCharge = Mathf.Min(_chargeDashTimer / ChargeDashMaxTime, 1.0f);
					UpdatePlayerDashCharge(_dashCharge);
				}
				break;
		}

		// Dash timer is now managed by player's ability_cooldown_timer
		if (!_isChargingDash && !IsDashing)
		{
			UpdatePlayerDashCharge(0.0f);
		}
	}

	private void UpdatePlayerDashCharge(float value)
	{
		if (player != null && player.HasMethod("set_dash_charge_level"))
			player.Call("set_dash_charge_level", value);
	}

	public override void OnAbilityCooldownComplete()
	{
		// Dash duration complete - reset dash state
		if (IsDashing)
		{
			IsDashing = false;
			UpdatePlayerDashCharge(0.0f);
		}
	}

	// ===================================================================
	// THREAD MECHANIC: REVERSE GRAPPLE
	// ===================================================================
	public override void ThreadMechanic(float delta)
	{
		HandleReverseGrapple(delta);
	}

	private void HandleReverseGrapple(float delta)
	{
		// Attach/detach
		if (Input.IsActionJustPressed("Traversal"))
		{
			if (_currentGrappleTarget != null && !_connected && IsInRange())
			{
				_currentGrappleTarget.Call("attach_grapple");
				_connected = true;
				_currentSlack = MaxSlack;
				_currentGrappleTarget.Call("reset_return_timer");
				_ui.HideGrapplePrompt();
			}
			else if (_connected)
			{
				Detach();
			}
		}

		if (!_connected || _currentGrappleTarget == null)
		{
			if (_threadLine != null)
				_threadLine.Visible = false;
			return;
		}

		Vector2 targetPos = _currentGrappleTarget.GlobalPosition;
		Vector2 playerPos = player.GlobalPosition;
		Vector2 awayDir = (playerPos - targetPos).Normalized();
		bool pulling = player.Velocity.Dot(awayDir) > PullVelThreshold;
		float distanceToTarget = playerPos.DistanceTo(targetPos);

		if (distanceToTarget > GrappleMaxRange)
		{
			var vel = player.Velocity;
			vel.X = 0;
			player.Velocity = vel;
		}

		if (pulling)
		{
			float oldSlack = _currentSlack;
			_currentSlack = Mathf.Max(_currentSlack - SlackTakeRate * delta, 0.0f);
			_currentGrappleTarget.Call("reset_return_timer");

			if (player.Call("is_on_floor").AsBool())
			{
				var vel = player.Velocity;
				vel.X = (float)player.Get("speed") * Input.GetAxis("move_left", "move_right");
				player.Velocity = vel;
			}

			if (oldSlack > MaxSlack * 0.99f && _currentSlack < MaxSlack * 0.99f)
				ScreenShake(ScreenShakeSmall);
			if (oldSlack > 2.0f && _currentSlack <= 0.0f)
				ScreenShake(ScreenShakeBig);
			if (_currentSlack <= 0.0f)
				_currentGrappleTarget.ApplyImpulse(awayDir * YankForce * delta, Vector2.Zero);
		}
		else
		{
			float stretchRatio = (float)_currentGrappleTarget.Call("get_stretch_ratio", playerPos, TautStopDist, MaxTotalStretchMult, _currentSlack);
			float stretchMult = Mathf.Lerp(1.0f, 0.0f, stretchRatio);
			float slackT = 1.0f - (_currentSlack / MaxSlack);
			float slackMult = Mathf.Lerp(1.0f, GrappleSlowFactor, slackT);
			float finalMult = slackMult * stretchMult;

			if (player.Call("is_on_floor").AsBool())
			{
				var vel = player.Velocity;
				vel.X = (float)player.Get("speed") * Input.GetAxis("move_left", "move_right") * finalMult;
				player.Velocity = vel;
			}
			if (stretchRatio >= 1.0f)
			{
				var vel = player.Velocity;
				vel.X = 0;
				player.Velocity = vel;
				_currentGrappleTarget.Call("reset_return_timer");
			}

			_currentSlack = Mathf.Min(_currentSlack + SlackRestoreRate * delta, MaxSlack);
		}

		UpdateThreadLine();
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

		// Update dash state
		if (IsDashing)
		{
			var vel = player.Velocity;
			vel.X = _lastDirection * _dashSpeed;
			player.Velocity = vel;
		}
	}

	// ===================================================================
	// HELPER FUNCTIONS
	// ===================================================================
	private void UpdateThreadLine()
	{
		if (_threadLine == null)
			return;

		_threadLine.ClearPoints();
		if (!_connected || _currentGrappleTarget == null)
		{
			_threadLine.Visible = false;
			return;
		}

		Vector2 t = _currentGrappleTarget.GlobalPosition;
		Vector2 p = player.GlobalPosition;
		float slackFactor = _currentSlack / MaxSlack;
		float sagAmount = 60.0f * slackFactor;
		_threadLine.Visible = true;
		var color = _threadLine.DefaultColor;
		color.A = 1.0f;
		_threadLine.DefaultColor = color;
		int points = 8;

		for (int i = 0; i <= points; i++)
		{
			float ratio = i / (float)points;
			Vector2 basePos = t.Lerp(p, ratio);
			Vector2 mid = new Vector2(0, 1) * sagAmount * Mathf.Sin(Mathf.Pi * ratio);
			_threadLine.AddPoint(_threadLine.ToLocal(basePos + mid));
		}
	}

	private bool IsInRange()
	{
		if (_currentGrappleTarget == null)
			return false;

		var area = _currentGrappleTarget.GetNodeOrNull<Area2D>("DetectionArea");
		return area != null && area.OverlapsBody(player);
	}

	private void Detach()
	{
		if (_currentGrappleTarget != null)
			_currentGrappleTarget.Call("detach_grapple");

		_connected = false;
		_currentSlack = 0.0f;

		if (_threadLine != null)
			UpdateThreadLine();

		if (IsInRange())
			_ui.ShowGrapplePrompt("Q to attach");
		else
			_ui.HideGrapplePrompt();

		_currentGrappleTarget = null;
	}

	private void OnDetectionEntered(Node body, Node plat)
	{
		if (body != player)
			return;
		if (_currentGrappleTarget != null)
			return;

		_currentGrappleTarget = plat as RigidBody2D;
		plat.Call("set_in_range", true);
		_ui.ShowGrapplePrompt("Q to attach");
	}

	private void OnDetectionExited(Node body, Node plat)
	{
		if (body != player)
			return;
		if (_currentGrappleTarget == plat && !_connected)
		{
			_currentGrappleTarget = null;
			plat.Call("set_in_range", false);
			_ui.HideGrapplePrompt();
		}
	}

	private void ScreenShake(float amount)
	{
		var cam = GetViewport().GetCamera2D();
		if (cam == null)
			return;

		cam.Offset += new Vector2(GD.Randf() * amount * 2 - amount, GD.Randf() * amount * 2 - amount);
		var tw = CreateTween();
		tw.TweenProperty(cam, "offset", Vector2.Zero, 0.3).SetTrans(Tween.TransitionType.Sine).SetEase(Tween.EaseType.Out);
	}
}
