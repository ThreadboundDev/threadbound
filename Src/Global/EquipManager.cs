using Godot;
using System.Collections.Generic;

/// <summary>
/// EquipManager (Autoload singleton)
/// Central data for all 9 equips + tuning
/// </summary>
public partial class EquipManager : Node
{
	// Equip enum (for easy indexing)
	public enum EquipSlot { GLOVES = 0, BOOTS = 1, CHEST_HEAD = 2 }

	// Thread color enum — renamed so it doesn't clash with built-in Color
	public enum ThreadColor { RED = 0, BLUE = 1, YELLOW = 2 }

	// Current equipped (0-8: gloves-red=0, gloves-blue=1, ..., chest-yellow=8)
	public int[] CurrentEquip = new int[] { 0, 0, 0 };  // [gloves, boots, chest] indices

	// Equip data: cooldowns, names, colors (tune here!)
	public Dictionary<int, Dictionary<string, Variant>> EquipData = new Dictionary<int, Dictionary<string, Variant>>
	{
		// Gloves (0-2)
		{ 0, new Dictionary<string, Variant> { { "name", "Red Grapple" }, { "thread_color", (int)ThreadColor.RED }, { "cooldown", 1.2f } } },
		{ 1, new Dictionary<string, Variant> { { "name", "Blue Swing" }, { "thread_color", (int)ThreadColor.BLUE }, { "cooldown", 0.8f } } },
		{ 2, new Dictionary<string, Variant> { { "name", "Yellow Manifest" }, { "thread_color", (int)ThreadColor.YELLOW }, { "cooldown", 1.0f } } },
		// Boots (3-5)
		{ 3, new Dictionary<string, Variant> { { "name", "Red Stomp" }, { "thread_color", (int)ThreadColor.RED }, { "cooldown", 1.5f } } },
		{ 4, new Dictionary<string, Variant> { { "name", "Blue Drift" }, { "thread_color", (int)ThreadColor.BLUE }, { "cooldown", 0.6f } } },
		{ 5, new Dictionary<string, Variant> { { "name", "Yellow Foothold" }, { "thread_color", (int)ThreadColor.YELLOW }, { "cooldown", 0.9f } } },
		// Chest/Head (6-8)
		{ 6, new Dictionary<string, Variant> { { "name", "Red Rage" }, { "thread_color", (int)ThreadColor.RED }, { "cooldown", 3.0f } } },
		{ 7, new Dictionary<string, Variant> { { "name", "Blue Harmony" }, { "thread_color", (int)ThreadColor.BLUE }, { "cooldown", 2.5f } } },
		{ 8, new Dictionary<string, Variant> { { "name", "Yellow Clone" }, { "thread_color", (int)ThreadColor.YELLOW }, { "cooldown", 2.0f } } }
	};

	// Color constants (for highlights, particles, etc.)
	public static readonly Color[] THREAD_COLORS = new Color[]
	{
		new Color(1.0f, 0.3f, 0.2f),     // Red (slightly desaturated)
		new Color(0.3f, 0.6f, 1.0f),     // Blue
		new Color(1.0f, 0.9f, 0.3f)      // Yellow
	};

	// Get equip index from slot + thread color (e.g. gloves + red = 0)
	public static int GetEquipIndex(EquipSlot slot, ThreadColor threadColor)
	{
		return (int)slot * 3 + (int)threadColor;
	}

	// Get thread color value for a given equip index
	public static Color GetThreadColor(int equipIndex)
	{
		int threadColorIdx = equipIndex % 3;
		return THREAD_COLORS[threadColorIdx];
	}

	// Signal when any equip changes
	[Signal]
	public delegate void EquipChangedEventHandler(EquipSlot slot, int newEquipIndex);

	public override void _Ready()
	{
		GD.Print("EquipManager loaded");
		GD.Print("Gloves + Red index: ", GetEquipIndex(EquipSlot.GLOVES, ThreadColor.RED));  // Should print 0
		GD.Print("Boots + Blue index: ", GetEquipIndex(EquipSlot.BOOTS, ThreadColor.BLUE));    // Should print 4
	}
}
