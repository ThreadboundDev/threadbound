using Godot;
using System.Collections.Generic;

/// <summary>
/// Global singleton for archetype constants
/// Provides centralized access to archetype names, colors, and configuration
/// </summary>
public partial class ThreadType : Node
{
	// Archetype name constants
	public const string RED = "Red";
	public const string BLUE = "Blue";
	public const string YELLOW = "Yellow";

	// Archetype color constants
	public static readonly Color RED_COLOR = new Color(1, 0, 0, 1);
	public static readonly Color BLUE_COLOR = new Color(0, 0, 1, 1);
	public static readonly Color YELLOW_COLOR = new Color(1, 1, 0, 1);

	// Dictionary mapping archetype names to their colors
	public static readonly Dictionary<string, Color> ARCHETYPE_COLORS = new Dictionary<string, Color>
	{
		{ RED, RED_COLOR },
		{ BLUE, BLUE_COLOR },
		{ YELLOW, YELLOW_COLOR }
	};

	// Get color for an archetype name
	public static Color GetColor(string archetypeName)
	{
		return ARCHETYPE_COLORS.GetValueOrDefault(archetypeName, new Color(0, 0, 0, 1));
	}

	// Get all valid archetype names
	public static string[] GetAllArchetypes()
	{
		return new string[] { RED, BLUE, YELLOW };
	}

	// Check if an archetype name is valid
	public static bool IsValid(string archetypeName)
	{
		return ARCHETYPE_COLORS.ContainsKey(archetypeName);
	}
}
