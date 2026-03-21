using Godot;

/// <summary>
/// Global debug UI singleton
/// Provides a single debug label accessible from anywhere
/// </summary>
public partial class DebugUI : Node
{
	private Label _debugLabel;
	private Node2D _targetNode = null;  // Usually the player
	private CanvasLayer _canvasLayer = null;

	public override void _Ready()
	{
		// Create canvas layer for debug UI (always on top)
		_canvasLayer = new CanvasLayer();
		_canvasLayer.Name = "DebugCanvas";
		AddChild(_canvasLayer);

		// Create debug label
		_debugLabel = new Label();
		_debugLabel.AddThemeFontSizeOverride("font_size", 18);
		_debugLabel.Text = "Debug";
		_debugLabel.Position = new Vector2(10, 10);  // Top-left corner by default
		_canvasLayer.AddChild(_debugLabel);
	}

	/// <summary>
	/// Update debug text - call from anywhere
	/// </summary>
	public void UpdateDebug(string text)
	{
		if (_debugLabel != null)
		{
			_debugLabel.Text = text;
		}
	}

	/// <summary>
	/// Clear debug text
	/// </summary>
	public void ClearDebug()
	{
		if (_debugLabel != null)
		{
			_debugLabel.Text = "";
		}
	}

	/// <summary>
	/// Set target node for relative positioning (optional)
	/// When set, the debug label will follow the target node
	/// </summary>
	public void SetTargetNode(Node2D node)
	{
		_targetNode = node;
		if (_targetNode != null && _debugLabel != null)
		{
			// Position relative to target (above player)
			_debugLabel.Position = new Vector2(0, -120);
			// Move label to follow target
			if (_debugLabel.GetParent() != _targetNode)
			{
				_debugLabel.GetParent().RemoveChild(_debugLabel);
				_targetNode.AddChild(_debugLabel);
			}
		}
	}

	/// <summary>
	/// Reset to screen-relative positioning
	/// </summary>
	public void ResetPosition()
	{
		if (_debugLabel != null && _targetNode != null)
		{
			if (_debugLabel.GetParent() == _targetNode)
			{
				_targetNode.RemoveChild(_debugLabel);
			}
			_canvasLayer.AddChild(_debugLabel);
			_debugLabel.Position = new Vector2(10, 10);
			_targetNode = null;
		}
	}
}
