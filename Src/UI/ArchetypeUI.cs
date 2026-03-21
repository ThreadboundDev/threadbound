using Godot;

/// <summary>
/// UI component for archetype-specific UI elements
/// Handles popups and other visual feedback
/// </summary>
public partial class ArchetypeUI : Node
{
	private Label _grapplePopup;
	public Node ParentNode { get; set; }

	public ArchetypeUI(Node parent = null)
	{
		ParentNode = parent;
	}

	public override void _Ready()
	{
		if (ParentNode != null)
		{
			SetupUI();
		}
	}

	private void SetupUI()
	{
		// Grapple popup
		_grapplePopup = new Label();
		_grapplePopup.AddThemeFontSizeOverride("font_size", 24);
		_grapplePopup.Position = new Vector2(0, -80);
		_grapplePopup.Visible = false;
		ParentNode.AddChild(_grapplePopup);
	}

	public void ShowGrapplePrompt(string text = "Q to attach")
	{
		if (_grapplePopup == null)
			return;

		_grapplePopup.Visible = true;
		_grapplePopup.Text = text;
		var tw = CreateTween();
		tw.TweenProperty(_grapplePopup, "scale", new Vector2(1.2f, 1.2f), 0.1);
		tw.TweenProperty(_grapplePopup, "scale", Vector2.One, 0.1).SetTrans(Tween.TransitionType.Bounce);
	}

	public void HideGrapplePrompt()
	{
		if (_grapplePopup != null)
		{
			_grapplePopup.Visible = false;
		}
	}
}
