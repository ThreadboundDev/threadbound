using Godot;
using System.Collections.Generic;

public partial class PlayerThreadState : Node
{
	public string StartingArchetype { get; set; } = "";

	public Dictionary<string, bool> Absorbed = new Dictionary<string, bool>
	{
		{ ThreadType.RED, false },
		{ ThreadType.BLUE, false },
		{ ThreadType.YELLOW, false }
	};

	public Dictionary<string, bool> Spared = new Dictionary<string, bool>
	{
		{ ThreadType.RED, false },
		{ ThreadType.BLUE, false },
		{ ThreadType.YELLOW, false }
	};

	private const float BASE_GRAY = 0.2f;
	private const float CHOICE_BOOST = 0.4f;
	private const float ABSORB_BOOST = 0.4f;
	private const float SPARE_PENALTY = 0.2f;

	[Signal]
	public delegate void PaletteChangedEventHandler(Color newColor);

	[Signal]
	public delegate void BossAbsorbedEventHandler(string color);

	[Signal]
	public delegate void BossSparedEventHandler(string color);

	public override void _Ready()
	{
		StartingArchetype = ThreadType.RED;
		Absorb(ThreadType.RED);
		Spare(ThreadType.BLUE);
		Spare(ThreadType.YELLOW);
		GD.Print("TRUE RED FINAL COLOR:", GetCurrentPalette());  // Should be (1, 0, 0, 1)
	}

	public Color GetCurrentPalette()
	{
		float r = BASE_GRAY;
		float g = BASE_GRAY;
		float b = BASE_GRAY;

		if (StartingArchetype == ThreadType.RED)
			r += CHOICE_BOOST;
		if (StartingArchetype == ThreadType.BLUE)
			g += CHOICE_BOOST;
		if (StartingArchetype == ThreadType.YELLOW)
			b += CHOICE_BOOST;

		if (Absorbed[ThreadType.RED]) r += ABSORB_BOOST;
		if (Absorbed[ThreadType.BLUE]) g += ABSORB_BOOST;
		if (Absorbed[ThreadType.YELLOW]) b += ABSORB_BOOST;

		if (Spared[ThreadType.RED]) r -= SPARE_PENALTY;
		if (Spared[ThreadType.BLUE]) g -= SPARE_PENALTY;
		if (Spared[ThreadType.YELLOW]) b -= SPARE_PENALTY;

		return new Color(r, g, b);
	}

	public void Absorb(string color)
	{
		if (!ThreadType.IsValid(color))
		{
			GD.PushError("Invalid absorb color: " + color);
			return;
		}
		if (Absorbed[color])
			return;

		Absorbed[color] = true;
		EmitSignal(SignalName.PaletteChanged, GetCurrentPalette());
		EmitSignal(SignalName.BossAbsorbed, color);
	}

	public void Spare(string color)
	{
		if (!ThreadType.IsValid(color))
		{
			GD.PushError("Invalid spare color: " + color);
			return;
		}
		if (Spared[color])
			return;

		Spared[color] = true;
		EmitSignal(SignalName.PaletteChanged, GetCurrentPalette());
		EmitSignal(SignalName.BossSpared, color);
	}
}
