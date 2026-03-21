using Godot;
using System.Collections.Generic;

public partial class RadialMenu : CanvasLayer
{
	// Slot buttons - children of Background
	private TextureButton _monarchGloves;
	private TextureButton _monarchBoots;
	private TextureButton _monarchChest;
	private TextureButton _hermitGloves;
	private TextureButton _hermitBoots;
	private TextureButton _hermitChest;
	private TextureButton _sageGloves;
	private TextureButton _sageBoots;
	private TextureButton _sageChest;

	private Control _menuFadeContainer;
	private TextureRect _background;
	private CanvasLayer _blurLayer;
	private ColorRect _blurRect;

	[Export] public NodePath PlayerPath { get; set; } = "../Player";
	private CharacterBody2D _player;

	[Export] public float MaxSlowBank { get; set; } = 2.0f;
	[Export] public float RechargeRate { get; set; } = 0.2f;
	[Export] public float SlowScale { get; set; } = 0.25f;
	[Export] public float OpenFadeTime { get; set; } = 0.35f;
	[Export] public float CloseFadeTime { get; set; } = 0.18f;
	[Export] public float BlurMaxAmount { get; set; } = 2.8f;

	private float _slowBank = 2.0f;
	private float _lastRealTime = 0.0f;
	private bool _isSlowing = false;
	private bool _isHeld = false;
	private Tween _timeTween;
	private Tween _blurTween;
	private Tween _menuTween;

	[Signal]
	public delegate void EquipSwappedEventHandler(int slotIndex);

	public override void _Ready()
	{
		// Get node references
		_menuFadeContainer = GetNode<Control>("MenuFadeContainer");
		_background = GetNode<TextureRect>("MenuFadeContainer/Background");
		_blurLayer = GetTree().GetFirstNodeInGroup("blur_layer") as CanvasLayer;
		_blurRect = GetTree().GetFirstNodeInGroup("blur_rect") as ColorRect;

		_player = GetNodeOrNull<CharacterBody2D>(PlayerPath);

		// Get all buttons
		_monarchGloves = GetNode<TextureButton>("MenuFadeContainer/Background/MonarchGloves");
		_monarchBoots = GetNode<TextureButton>("MenuFadeContainer/Background/MonarchBoots");
		_monarchChest = GetNode<TextureButton>("MenuFadeContainer/Background/MonarchChest");
		_hermitGloves = GetNode<TextureButton>("MenuFadeContainer/Background/HermitGloves");
		_hermitBoots = GetNode<TextureButton>("MenuFadeContainer/Background/HermitBoots");
		_hermitChest = GetNode<TextureButton>("MenuFadeContainer/Background/HermitChest");
		_sageGloves = GetNode<TextureButton>("MenuFadeContainer/Background/SageGloves");
		_sageBoots = GetNode<TextureButton>("MenuFadeContainer/Background/SageBoots");
		_sageChest = GetNode<TextureButton>("MenuFadeContainer/Background/SageChest");

		_menuFadeContainer.Visible = false;
		var modulate = _menuFadeContainer.Modulate;
		modulate.A = 0.0f;
		_menuFadeContainer.Modulate = modulate;

		if (_blurLayer != null)
			_blurLayer.Visible = false;

		if (_blurRect != null)
		{
			_blurRect.Visible = false;
			var mat = _blurRect.Material as ShaderMaterial;
			if (mat != null)
				mat.SetShaderParameter("blur_amount", 0.0f);
		}

		Visible = true;
		AddToGroup("radial_menu");
		_slowBank = MaxSlowBank;
		_lastRealTime = Time.GetTicksMsec() / 1000.0f;

		// Debug: confirm every button
		GD.Print("=== Button Load Debug ===");
		GD.Print("MonarchGloves: ", _monarchGloves != null);
		GD.Print("MonarchBoots: ", _monarchBoots != null);
		GD.Print("MonarchChest: ", _monarchChest != null);
		GD.Print("HermitGloves: ", _hermitGloves != null);
		GD.Print("HermitBoots: ", _hermitBoots != null);
		GD.Print("HermitChest: ", _hermitChest != null);
		GD.Print("SageGloves: ", _sageGloves != null);
		GD.Print("SageBoots: ", _sageBoots != null);
		GD.Print("SageChest: ", _sageChest != null);
		GD.Print("=======================");

		// Connect hover/pressed for all 9
		ConnectSlot(_monarchGloves, EquipManager.ThreadColor.RED);
		ConnectSlot(_monarchBoots, EquipManager.ThreadColor.RED);
		ConnectSlot(_monarchChest, EquipManager.ThreadColor.RED);
		ConnectSlot(_hermitGloves, EquipManager.ThreadColor.BLUE);
		ConnectSlot(_hermitBoots, EquipManager.ThreadColor.BLUE);
		ConnectSlot(_hermitChest, EquipManager.ThreadColor.BLUE);
		ConnectSlot(_sageGloves, EquipManager.ThreadColor.YELLOW);
		ConnectSlot(_sageBoots, EquipManager.ThreadColor.YELLOW);
		ConnectSlot(_sageChest, EquipManager.ThreadColor.YELLOW);
	}

	private void ConnectSlot(TextureButton button, EquipManager.ThreadColor color)
	{
		if (button == null)
		{
			GD.Print($"Warning: button is null for color {color}");
			return;
		}

		GD.Print($"Connected hover/pressed for: {button.Name}");

		button.MouseEntered += () => OnSlotHover(button, color);
		button.MouseExited += () => OnSlotUnhover(button);
		button.Pressed += () => OnSlotPressed(button);
	}

	private float GetRealDelta()
	{
		float now = Time.GetTicksMsec() / 1000.0f;
		float delta = now - _lastRealTime;
		_lastRealTime = now;
		return delta;
	}

	public override void _Process(double delta)
	{
		float realDelta = GetRealDelta();

		if (!_isHeld)
		{
			_slowBank = Mathf.Min(_slowBank + RechargeRate * realDelta, MaxSlowBank);
		}

		if (_isSlowing && _isHeld)
		{
			_slowBank -= realDelta;
			if (_slowBank <= 0.0f)
			{
				_slowBank = 0.0f;
				_isSlowing = false;
				_isHeld = false;
				CloseMenu();
			}
		}

		if (_player != null && _isHeld)
		{
			Vector2 playerScreenPos = _player.GetGlobalTransformWithCanvas().Origin;
			Vector2 viewportSize = GetViewport().GetVisibleRect().Size;

			_background.Position = playerScreenPos - (viewportSize / 2);
			_background.Position += new Vector2(0, -80);
		}
	}

	public void UpdateHoldState(bool held)
	{
		if (held && !_isHeld)
		{
			_isHeld = true;
			FadeInMenu();

			if (_slowBank > 0.1f)
			{
				_isSlowing = true;
				Engine.TimeScale = SlowScale;
				FadeInBlur();
			}
			else
			{
				_isSlowing = false;
				Engine.TimeScale = 1.0;
			}
		}
		else if (!held && _isHeld)
		{
			_isHeld = false;
			CloseMenu();
		}
	}

	private void CloseMenu()
	{
		_isSlowing = false;
		FadeOutMenu();
		FadeOutBlur();

		if (_timeTween != null)
			_timeTween.Kill();

		_timeTween = CreateTween();
		_timeTween.TweenProperty(Engine.Singleton, "time_scale", 1.0, CloseFadeTime * 0.8)
			.SetEase(Tween.EaseType.In)
			.SetTrans(Tween.TransitionType.Sine);
	}

	private void FadeInMenu()
	{
		_menuFadeContainer.Visible = true;
		var modulate = _menuFadeContainer.Modulate;
		modulate.A = 0.0f;
		_menuFadeContainer.Modulate = modulate;

		if (_menuTween != null)
			_menuTween.Kill();

		_menuTween = CreateTween();
		_menuTween.TweenProperty(_menuFadeContainer, "modulate:a", 1.0, OpenFadeTime)
			.SetEase(Tween.EaseType.Out)
			.SetTrans(Tween.TransitionType.Sine);
	}

	private void FadeOutMenu()
	{
		if (_menuTween != null)
			_menuTween.Kill();

		_menuTween = CreateTween();
		_menuTween.TweenProperty(_menuFadeContainer, "modulate:a", 0.0, CloseFadeTime)
			.SetEase(Tween.EaseType.In)
			.SetTrans(Tween.TransitionType.Sine);
		_menuTween.TweenCallback(Callable.From(() => _menuFadeContainer.Visible = false));
	}

	private void FadeInBlur()
	{
		if (_blurLayer != null)
			_blurLayer.Visible = true;

		if (_blurRect != null)
		{
			_blurRect.Visible = true;
			var mat = _blurRect.Material as ShaderMaterial;
			if (mat != null)
				mat.SetShaderParameter("blur_amount", 0.0f);
		}

		if (_blurTween != null)
			_blurTween.Kill();

		if (_blurRect != null && _blurRect.Material is ShaderMaterial blurMat)
		{
			_blurTween = CreateTween();
			_blurTween.TweenProperty(blurMat, "shader_parameter/blur_amount", BlurMaxAmount, OpenFadeTime)
				.SetEase(Tween.EaseType.Out)
				.SetTrans(Tween.TransitionType.Sine);
		}
	}

	private void FadeOutBlur()
	{
		if (_blurTween != null)
			_blurTween.Kill();

		if (_blurRect != null && _blurRect.Material is ShaderMaterial blurMat)
		{
			_blurTween = CreateTween();
			_blurTween.TweenProperty(blurMat, "shader_parameter/blur_amount", 0.0, CloseFadeTime)
				.SetEase(Tween.EaseType.In)
				.SetTrans(Tween.TransitionType.Sine);
			_blurTween.TweenCallback(Callable.From(() =>
			{
				if (_blurLayer != null)
					_blurLayer.Visible = false;
				if (_blurRect != null)
					_blurRect.Visible = false;
			}));
		}
	}

	private void SelectEquip(int slotIdx)
	{
		int slotType = slotIdx / 3;
		int colorIdx = slotIdx % 3;

		var equipManager = GetNode<EquipManager>("/root/EquipManager");
		equipManager.CurrentEquip[slotType] = colorIdx;
		equipManager.EmitSignal(EquipManager.SignalName.EquipChanged, slotType, slotIdx);

		var equipName = equipManager.EquipData[slotIdx]["name"].AsString();
		GD.Print($"Equipped: {equipName} (slot {slotType}, color {colorIdx})");

		_slowBank = MaxSlowBank;
		CloseMenu();
	}

	// HOVER ANIMATION - real-time even during slow time
	private void OnSlotHover(TextureButton button, EquipManager.ThreadColor color)
	{
		Color glowColor = EquipManager.THREAD_COLORS[(int)color].Lightened(0.6f);
		var tween = CreateTween();
		tween.SetProcessMode(Tween.TweenProcessMode.Idle);  // Runs at real time
		tween.SetParallel();
		tween.TweenProperty(button, "modulate", glowColor, 0.15)
			.SetEase(Tween.EaseType.Out).SetTrans(Tween.TransitionType.Cubic);
		tween.TweenProperty(button, "scale", new Vector2(1.18f, 1.18f), 0.15)
			.SetEase(Tween.EaseType.Out).SetTrans(Tween.TransitionType.Back);

		var pulse = CreateTween();
		pulse.SetProcessMode(Tween.TweenProcessMode.Idle);
		pulse.SetLoops();
		pulse.TweenProperty(button, "modulate:a", 0.9, 0.5)
			.SetEase(Tween.EaseType.InOut);
		pulse.TweenProperty(button, "modulate:a", 1.0, 0.5)
			.SetEase(Tween.EaseType.InOut);
	}

	private void OnSlotUnhover(TextureButton button)
	{
		var tween = CreateTween();
		tween.SetProcessMode(Tween.TweenProcessMode.Idle);
		tween.SetParallel();
		tween.TweenProperty(button, "modulate", Colors.White, 0.15)
			.SetEase(Tween.EaseType.In);
		tween.TweenProperty(button, "scale", Vector2.One, 0.15)
			.SetEase(Tween.EaseType.In);

		var modulate = button.Modulate;
		modulate.A = 1.0f;
		button.Modulate = modulate;
	}

	private void OnSlotPressed(TextureButton button)
	{
		int slotIdx = -1;
		string buttonName = button.Name.ToString();

		if (buttonName == "MonarchGloves") slotIdx = 0;
		else if (buttonName == "MonarchBoots") slotIdx = 3;
		else if (buttonName == "MonarchChest") slotIdx = 6;
		else if (buttonName == "HermitGloves") slotIdx = 1;
		else if (buttonName == "HermitBoots") slotIdx = 4;
		else if (buttonName == "HermitChest") slotIdx = 7;
		else if (buttonName == "SageGloves") slotIdx = 2;
		else if (buttonName == "SageBoots") slotIdx = 5;
		else if (buttonName == "SageChest") slotIdx = 8;

		if (slotIdx >= 0)
		{
			AnimateButtonToCenter(button, slotIdx);
		}
		else
			GD.Print($"Warning: unknown button pressed: {button.Name}");
	}

	private void AnimateButtonToCenter(TextureButton button, int slotIdx)
	{
		// Store original position and pivot
		Vector2 originalPos = button.Position;
		Vector2 originalPivot = button.PivotOffset;
		
		// Get button's current global position
		Vector2 buttonGlobalPos = button.GlobalPosition + button.Size / 2;
		
		var tween = CreateTween();
		tween.SetProcessMode(Tween.TweenProcessMode.Idle);
		tween.SetParallel();
		
		// Scale up from center
		button.PivotOffset = button.Size / 2;
		tween.TweenProperty(button, "scale", new Vector2(1.5f, 1.5f), 0.3f)
			.SetEase(Tween.EaseType.Out)
			.SetTrans(Tween.TransitionType.Back);
		
		// Brighten
		tween.TweenProperty(button, "modulate", Colors.White.Lightened(0.3f), 0.3f);
		
		// After animation completes, select the equipment and close menu
		tween.Chain().TweenCallback(Callable.From(() =>
		{
			SelectEquip(slotIdx);
			// Reset button position/scale for next time
			button.Position = originalPos;
			button.PivotOffset = originalPivot;
			button.Scale = Vector2.One;
			button.Modulate = Colors.White;
		}));
	}

	public override void _Input(InputEvent @event)
	{
		if (_menuFadeContainer.Visible && @event.IsActionPressed("ui_cancel"))
		{
			UpdateHoldState(false);
		}
	}
}
