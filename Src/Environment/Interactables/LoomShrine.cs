using Godot;

public partial class LoomShrine : Node2D
{
	private Label _promptLabel;
	private GpuParticles2D _energyBurst;
	private Area2D _interactionArea;

	private bool _playerInRange = false;

	public override void _Ready()
	{
		_promptLabel = GetNode<Label>("PromptLabel");
		_energyBurst = GetNode<GpuParticles2D>("EnergyBurst");
		_interactionArea = GetNode<Area2D>("InteractionArea");

		_interactionArea.BodyEntered += OnPlayerEntered;
		_interactionArea.BodyExited += OnPlayerExited;
	}

	private void OnPlayerEntered(Node2D body)
	{
		if (body.IsInGroup("player"))
		{
			_playerInRange = true;
			_promptLabel.Visible = true;
			_promptLabel.Text = "↑ to weave ↑";
			_energyBurst.Restart();
			_energyBurst.Emitting = true;
		}
	}

	private void OnPlayerExited(Node2D body)
	{
		if (body.IsInGroup("player"))
		{
			_playerInRange = false;
			_promptLabel.Visible = false;
			_energyBurst.Emitting = false;
		}
	}

	public override void _Process(double delta)
	{
		if (_playerInRange && Input.IsActionJustPressed("move_up"))
		{
			GD.Print("LOOM SHRINE OPENED — EQUIPMENT MENU READY");
			// open_equipment_menu()  // ← next step
		}
	}
}
