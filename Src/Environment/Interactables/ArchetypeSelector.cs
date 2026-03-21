using Godot;

public partial class ArchetypeSelector : Area2D
{
	// Archetype color - set this in the editor (Red, Blue, or Yellow)
	[Export] public string ArchetypeColor { get; set; } = ThreadType.RED;

	// Compatibility property - returns ArchetypeColor for backward compatibility
	public string Color => ArchetypeColor;

	private Label _popup;

	public override void _Ready()
	{
		AddToGroup("selectors");
		SetupVisuals();
		ConnectSignals();
	}

	private void SetupVisuals()
	{
		Color rectColor = GetColorForArchetype(ArchetypeColor);
		if (HasNode("ColorRect"))
		{
			GetNode<ColorRect>("ColorRect").Color = rectColor;
		}

		_popup = new Label();
		_popup.Text = $"Use W Key to select {ArchetypeColor} archetype";
		_popup.Visible = false;
		_popup.Position = new Vector2(-125, -125);
		AddChild(_popup);
	}

	private Color GetColorForArchetype(string color)
	{
		return ThreadType.GetColor(ArchetypeColor);
	}

	private void ConnectSignals()
	{
		BodyEntered += OnBodyEntered;
		BodyExited += OnBodyExited;
	}

	private void OnBodyEntered(Node2D body)
	{
		if (body.Name == "Player")
		{
			body.Call("OnInteractableEntered", this);
			_popup.Visible = true;
		}
	}

	private void OnBodyExited(Node2D body)
	{
		if (body.Name == "Player")
		{
			body.Call("OnInteractableExited", this);
			_popup.Visible = false;
		}
	}
}
