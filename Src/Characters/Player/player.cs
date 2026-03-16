using Godot;
using System;
using PhantomCamera;

public partial class player : CharacterBody2D
{
    // ===============================
    // NODES
    // ===============================
    [Export] private AnimatedSprite2D playerAnimation;
    [Export] private NodePath cameraPath; // e.g. "../Camera Master/PhantomCameraHost2D/MainFollowCam"
    private PhantomCameraHost2D cameraHost;

    [Export] private Sprite2D glowSprite;
    [Export] private Timer abilityCooldownTimer;

    // ===============================
    // TUNABLES – Base movement & shared glow
    // ===============================
    [Export] public float Speed { get; set; } = 500.0f;
    [Export] public float AirControlMult { get; set; } = 0.75f;
    [Export] public float Gravity { get; set; } = 1600.0f;
    [Export] public float MaxFallSpeed { get; set; } = 1000.0f;
    [Export] public float CoyoteTime { get; set; } = 0.12f;
    [Export] public float LookOffset { get; set; } = 60.0f;
    [Export] public float LookSpeed { get; set; } = 10.0f;
    [Export] public float HoldDuration { get; set; } = 1.0f;

    // Shared glow config (used by all charge-based tools later)
    [Export] public float IdleGlowWidth { get; set; } = 1.2f;
    [Export] public float IdleGlowIntensity { get; set; } = 0.35f;
    [Export] public float ChargeGlowMaxWidth { get; set; } = 4.0f;
    [Export] public float ChargeGlowMaxIntensity { get; set; } = 1.2f;

    // Base jump force – Boots equip will override/augment this
    [Export] public float BaseJumpForce { get; set; } = 700.0f;

    // ===============================
    // STATE
    // ===============================
    private float coyoteTimer = 0.0f;
    public int LastDirection { get; private set; } = 1; // Public for bias_controller

    private bool isNearInteractable = false;
    private Area2D currentSelector = null;

    private float currentLookOffsetY = 0.0f;
    private float holdTimer = 0.0f;

    // Charge levels (filled/used by equipped tools later)
    public float JumpChargeRatio { get; private set; } = 0.0f;
    public float MomentumChargeRatio { get; private set; } = 0.0f;

    private Color currentGlowColor = new Color(0.8f, 0.8f, 1.0f); // Default faint blueish

    public override void _Ready()
    {
        playerAnimation ??= GetNodeOrNull<AnimatedSprite2D>("Player Animation");
        glowSprite ??= GetNodeOrNull<Sprite2D>("GlowSprite");
        abilityCooldownTimer ??= GetNodeOrNull<Timer>("AbilityCooldownTimer");

        var camNode = GetNodeOrNull(cameraPath);
        cameraHost = camNode as PhantomCameraHost2D;

        if (abilityCooldownTimer != null)
        {
            abilityCooldownTimer.Timeout += OnAbilityCooldownTimeout;
        }

        // Initial glow setup
        UpdateBaseGlow(currentGlowColor, IdleGlowWidth, IdleGlowIntensity);
    }

    public override void _PhysicsProcess(double delta)
    {
        float fDelta = (float)delta;

        // Gravity & Coyote time
        if (!IsOnFloor())
        {
            Velocity = Velocity with { Y = Velocity.Y + Gravity * fDelta };
            if (Velocity.Y > MaxFallSpeed)
                Velocity = Velocity with { Y = MaxFallSpeed };

            coyoteTimer -= fDelta;
        }
        else
        {
            coyoteTimer = CoyoteTime;
        }

        // Horizontal input & direction tracking
        float horizontalInput = Input.GetAxis("move_left", "move_right");
        if (horizontalInput != 0)
        {
            LastDirection = Mathf.Sign(horizontalInput);
        }

        float control = IsOnFloor() ? 1.0f : AirControlMult;
        Velocity = Velocity with { X = Speed * horizontalInput * control };

        // Base jump (instant, with coyote forgiveness)
        if (Input.IsActionJustPressed("jump") && (IsOnFloor() || coyoteTimer > 0))
        {
            Velocity = Velocity with { Y = -BaseJumpForce };
            coyoteTimer = 0f; // Consume coyote window

            // Optional: Add jump sound, particle, or animation transition here later
            // e.g. playerAnimation.Play("JumpStart");
        }

        // Vertical camera offset (hold up/down – using PhantomCam FollowOffset)
        if (cameraHost != null)
        {
            Vector2 curOffset = cameraHost.FollowOffset;
            float targetY = 0.0f;

            if (Input.IsActionPressed("move_up"))
            {
                holdTimer += fDelta;
                if (holdTimer >= HoldDuration && !isNearInteractable)
                    targetY = -LookOffset;
            }
            else if (Input.IsActionPressed("move_down"))
            {
                holdTimer += fDelta;
                if (holdTimer >= HoldDuration)
                    targetY = LookOffset;
            }
            else
            {
                holdTimer = 0.0f;
            }

            currentLookOffsetY = Mathf.Lerp(currentLookOffsetY, targetY, fDelta * LookSpeed);
            cameraHost.FollowOffset = new Vector2(curOffset.X, currentLookOffsetY);
        }

        // Interact / pickup stub (can repurpose later for equip pickups)
        if (isNearInteractable && currentSelector != null && Input.IsActionJustPressed("move_up"))
        {
            GD.Print($"Interacting with: {currentSelector.Name}");
        }

        MoveAndSlide();

        UpdateAnimations(horizontalInput);
    }

    public override void _Process(double delta)
    {
        if (Input.IsActionJustPressed("ui_cancel"))
        {
            GetTree().Quit();
        }

        // Sync glow sprite to current animation frame
        if (glowSprite != null && playerAnimation != null && playerAnimation.SpriteFrames != null)
        {
            var tex = playerAnimation.SpriteFrames.GetFrameTexture(playerAnimation.Animation, playerAnimation.Frame);
            glowSprite.Texture = tex;
            glowSprite.FlipH = playerAnimation.FlipH;
            glowSprite.Position = playerAnimation.Position;
            glowSprite.Scale = playerAnimation.Scale;

            ApplyChargeGlow();
        }

        // Radial menu hold polling (implement later)
        var menu = GetTree().GetFirstNodeInGroup("radial_menu");
        if (menu != null)
        {
            menu.CallDeferred("update_hold_state", Input.IsActionPressed("open_menu"));
        }
    }

    private void ApplyChargeGlow()
    {
        if (glowSprite?.Material == null) return;

        float level = Mathf.Clamp(Mathf.Max(JumpChargeRatio, MomentumChargeRatio), 0f, 1f);
        var mat = (ShaderMaterial)glowSprite.Material;

        float targetWidth = Mathf.Lerp(IdleGlowWidth, ChargeGlowMaxWidth, level);
        float targetIntensity = Mathf.Lerp(IdleGlowIntensity, ChargeGlowMaxIntensity, level);

        mat.SetShaderParameter("glow_width", targetWidth);
        mat.SetShaderParameter("glow_intensity", targetIntensity);
        mat.SetShaderParameter("glow_color", level > 0.01f ? currentGlowColor : currentGlowColor);
    }

    public void SetJumpChargeLevel(float level)
    {
        JumpChargeRatio = Mathf.Clamp(level, 0f, 1f);
    }

    public void SetMomentumChargeLevel(float level)
    {
        MomentumChargeRatio = Mathf.Clamp(level, 0f, 1f);
    }

    public void StartAbilityCooldown(float duration)
    {
        if (abilityCooldownTimer != null)
        {
            abilityCooldownTimer.WaitTime = duration;
            abilityCooldownTimer.Start();
        }
    }

    private void UpdateBaseGlow(Color color, float width, float intensity)
    {
        currentGlowColor = color;
        if (glowSprite?.Material != null && Mathf.Max(JumpChargeRatio, MomentumChargeRatio) <= 0.01f)
        {
            var mat = (ShaderMaterial)glowSprite.Material;
            mat.SetShaderParameter("glow_color", color);
            mat.SetShaderParameter("glow_width", width);
            mat.SetShaderParameter("glow_intensity", intensity);
        }
    }

    private void UpdateAnimations(float horizontalInput)
    {
        if (playerAnimation == null || playerAnimation.SpriteFrames == null) return;

        if (!IsOnFloor() && playerAnimation.SpriteFrames.HasAnimation("Jump"))
        {
            playerAnimation.Play("Jump");
        }
        else if (Mathf.Abs(horizontalInput) > 0.01f && playerAnimation.SpriteFrames.HasAnimation("Walk"))
        {
            playerAnimation.Play("Walk");
        }
        else if (playerAnimation.SpriteFrames.HasAnimation("Idle"))
        {
            playerAnimation.Play("Idle");
        }

        if (Velocity.X != 0)
        {
            playerAnimation.FlipH = Velocity.X < 0;
        }
    }

    // Signal callbacks – connect in editor (Area2D body_entered / body_exited)
    private void OnInteractableEntered(Area2D area)
    {
        isNearInteractable = true;
        currentSelector = area;
    }

    private void OnInteractableExited(Area2D area)
    {
        isNearInteractable = false;
        if (currentSelector == area)
            currentSelector = null;
    }

    private void OnAbilityCooldownTimeout()
    {
        GD.Print("Ability cooldown finished");
    }
}