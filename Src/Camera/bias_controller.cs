using Godot;
using System;
using PhantomCamera;

public partial class bias_controller : Node
{
	[Export] private NodePath camPath; // Optional: drag the PhantomCamera2D here if you prefer explicit path
	private PhantomCamera2D cam;

	[Export] private NodePath playerPath; // Optional: drag Player here
	private CharacterBody2D player;

	[Export] public float BiasDistance { get; set; } = 60.0f;     // ± pixels offset when stopped
	[Export] public float DampSpeed { get; set; } = 6.0f;         // Lerp speed (higher = snappier)
	[Export] public float StoppedThreshold { get; set; } = 10.0f; // velocity.x below this → considered stopped

	private float currentBias = 0.0f;

	public override void _Ready()
	{
		// Auto-find if paths not set via export
		cam ??= GetParent<PhantomCamera2D>(); // assumes this node is direct parent of the camera
		player ??= cam?.FollowTarget as CharacterBody2D; // PhantomCamera2D usually has FollowTarget property

		// Alternative: if using exported paths
		// cam = GetNodeOrNull<PhantomCamera2D>(camPath);
		// player = GetNodeOrNull<CharacterBody2D>(playerPath);

		if (cam == null)
		{
			GD.PushWarning("Bias controller could not find PhantomCamera2D.");
		}

		if (player == null)
		{
			GD.PushWarning("Bias controller could not find Player reference.");
		}

		// Reset offset on start
		if (cam != null)
		{
			cam.FollowOffset = Vector2.Zero;
		}

		// Optional debug print (uncomment to see init values)
		// GD.Print($"Bias ready — threshold: {StoppedThreshold} | distance: {BiasDistance}");
	}

	public override void _Process(double delta)
	{
		if (player == null || cam == null) return;

		float targetBias = 0.0f; // Default: centered during movement

		// When nearly stopped → apply bias based on facing direction
		if (Mathf.Abs(player.Velocity.X) < StoppedThreshold)
		{
			targetBias = player.LastDirection * BiasDistance;

			// If you want the camera to bias *behind* the player instead of in front:
			// targetBias = -player.LastDirection * BiasDistance;
		}

		// Smoothly interpolate to target
		float lerpWeight = Mathf.Clamp(DampSpeed * (float)delta, 0.0f, 1.0f);
		currentBias = Mathf.Lerp(currentBias, targetBias, lerpWeight);

		// Apply to camera offset (x-axis only)
		cam.FollowOffset = new Vector2(currentBias, cam.FollowOffset.Y);

		// Optional debug (uncomment during tuning)
		// GD.Print($"Vel.x: {player.Velocity.X:F1} | Threshold: {StoppedThreshold} | Bias: {currentBias:F1} (Target: {targetBias:F1}) | Facing: {player.LastDirection}");
	}
}
