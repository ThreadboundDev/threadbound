using Godot;

public partial class RedPlatform : RigidBody2D
{
	[Export] public float MaxPullDist { get; set; } = 650.0f;
	[Export] public float ReturnSpeed { get; set; } = 600.0f;
	[Export] public float ReturnDelay { get; set; } = 2.0f;
	[Export] public float AutoReturnDelay { get; set; } = 3.0f;

	private Vector2 _anchorPos;
	private float _returnTimer = -1.0f;
	private float _autoReturnTimer = 0.0f;
	private bool _isAttached = false;

	private Area2D _detectionArea;
	private TileMapLayer _platformTiles;

	public override void _Ready()
	{
		_anchorPos = GlobalPosition;
		GravityScale = 0.0f;
		ContactMonitor = true;
		MaxContactsReported = 5;
		LinearDamp = 25.0f;
		AngularDamp = 25.0f;

		var physicsMaterial = new PhysicsMaterial();
		physicsMaterial.Bounce = 0.0f;
		physicsMaterial.Friction = 1.0f;
		PhysicsMaterialOverride = physicsMaterial;

		CollisionLayer = 4;
		CollisionMask = 3;

		_detectionArea = GetNode<Area2D>("DetectionArea");
		_platformTiles = GetNode<TileMapLayer>("PlatformTiles");
	}

	public override void _PhysicsProcess(double delta)
	{
		float dt = (float)delta;
		Vector2 toAnchor = _anchorPos - GlobalPosition;
		float dist = toAnchor.Length();

		// === AUTO-RETURN TIMER (when attached) ===
		if (_isAttached)
		{
			_autoReturnTimer += dt;
			if (_autoReturnTimer >= AutoReturnDelay)
			{
				Vector2 back = toAnchor.Normalized();
				ApplyCentralForce(back * ReturnSpeed * 0.6f * dt);
				LinearVelocity = LinearVelocity.Lerp(Vector2.Zero, dt * 6.0f);
			}
		}
		else
		{
			_autoReturnTimer = 0.0f;
		}

		// === RETURN TIMER (after detach) ===
		if (!_isAttached)
		{
			if (_returnTimer > 0)
				_returnTimer -= dt;

			if (_returnTimer <= 0 && dist > 0.1f)
			{
				Vector2 back = toAnchor.Normalized();
				ApplyCentralForce(back * ReturnSpeed * 0.8f * dt);
				LinearVelocity = LinearVelocity.Lerp(Vector2.Zero, dt * 8.0f);
			}
		}
	}

	public float GetAnchorDist()
	{
		return GlobalPosition.DistanceTo(_anchorPos);
	}

	public float GetStretchRatio(Vector2 playerPos, float tautStopDist, float maxMult, float remainingSlack)
	{
		float anchorDist = GetAnchorDist();
		float playerDist = GlobalPosition.DistanceTo(playerPos);
		float used = anchorDist + playerDist - remainingSlack;
		float maxTotal = MaxPullDist + tautStopDist;
		float ratio = Mathf.Clamp(used / (maxTotal * maxMult), 0.0f, 1.0f);
		return ratio;
	}

	public async void AttachGrapple()
	{
		if (_isAttached) return;

		_isAttached = true;
		_autoReturnTimer = 0.0f;
		_returnTimer = -1.0f;
		_platformTiles.Modulate = new Color(2.0f, 0.3f, 0.3f, 1.5f);

		await ToSignal(GetTree().CreateTimer(0.2), "timeout");

		if (_isAttached)
			_platformTiles.Modulate = Colors.White;
	}

	public void DetachGrapple()
	{
		_isAttached = false;
		_returnTimer = ReturnDelay;
		_autoReturnTimer = 0.0f;
	}

	public void SetInRange(bool active)
	{
		if (active)
			_platformTiles.Modulate = new Color(1.5f, 1.5f, 1.5f, 1.0f);
		else
			_platformTiles.Modulate = Colors.White;
	}

	// === CRITICAL: RESET RETURN TIMER ON ANY PULL ===
	public void ResetReturnTimer()
	{
		if (_isAttached)
		{
			_returnTimer = -1.0f;
			_autoReturnTimer = 0.0f;
		}
	}
}
