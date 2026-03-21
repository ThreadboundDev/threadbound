using Godot;

public partial class PlatformTiles : TileMapLayer
{
	private bool _isInRange = false;
	private TextureRect _glowRect;
	private ShaderMaterial _glowMaterial;
	private Tween _pulseTween;

	public override void _Ready()
	{
		if (HasNode("GlowLayer/GlowRect"))
		{
			_glowRect = GetNode<TextureRect>("GlowLayer/GlowRect");
			if (_glowRect != null)
			{
				_glowMaterial = _glowRect.Material as ShaderMaterial;
			}
		}

		if (_glowRect != null && _glowMaterial != null)
		{
			_glowMaterial.SetShaderParameter("glow_intensity", 0.0f);
			_glowMaterial.SetShaderParameter("glow_color", new Color(1.0f, 0.2f, 0.2f, 1.0f));
			GD.Print("PlatformTiles: Glow ready");
		}
		else
		{
			GD.Print("ERROR: GlowRect or material missing! Check ShaderMaterial on GlowRect.");
		}
	}

	public void SetInRange(bool active)
	{
		_isInRange = active;
		if (active)
			FadeInGlow();
		else
			FadeOutGlow();
	}

	private void FadeInGlow()
	{
		if (_glowMaterial == null) return;

		var tween = CreateTween();
		tween.TweenMethod(Callable.From<float>(i => _glowMaterial.SetShaderParameter("glow_intensity", i)), 0.0f, 1.0f, 0.5);
		tween.TweenCallback(Callable.From(StartPulse));
	}

	private void FadeOutGlow()
	{
		if (_glowMaterial == null) return;

		var currentIntensity = (float)_glowMaterial.GetShaderParameter("glow_intensity");
		var tween = CreateTween();
		tween.TweenMethod(Callable.From<float>(i => _glowMaterial.SetShaderParameter("glow_intensity", i)), currentIntensity, 0.0f, 0.3);
		StopPulse();
	}

	private void StartPulse()
	{
		if (_glowMaterial == null) return;

		_pulseTween = CreateTween();
		_pulseTween.SetLoops();
		_pulseTween.TweenMethod(Callable.From<float>(i => _glowMaterial.SetShaderParameter("glow_intensity", 0.7f + i * 0.8f)), 0.0f, 1.0f, 1.6);
	}

	private void StopPulse()
	{
		if (_pulseTween != null)
		{
			_pulseTween.Kill();
		}
	}
}
