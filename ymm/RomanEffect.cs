using System.ComponentModel.DataAnnotations;
using YukkuriMovieMaker.Commons;
using YukkuriMovieMaker.Controls;
using YukkuriMovieMaker.Exo;
using YukkuriMovieMaker.Player.Video;
using YukkuriMovieMaker.Plugin.Effects;
namespace SaBetaYmm;
[VideoEffect("Sa_beta ロマン", ["フィルタ"], ["地層", "干渉", "実験"], IsAviUtlSupported = false)]
public sealed class RomanEffect : VideoEffectBase
{
    public override string Label => "Sa_beta ロマン";
    [Display(Name="方式", Order=0)] [EnumComboBox]
    public RomanMode Mode { get => _mode; set => Set(ref _mode, value); }
    private RomanMode _mode;
    [Display(Name="適用量", Order=1)] [AnimationSlider("F2", "%", 0, 100)]
    public Animation Amount { get; } = new(100, 0, 100);
    [Display(Name="広がり", Order=2)] [AnimationSlider("F2", "px", 0, 512)]
    public Animation Radius { get; } = new(32, 0, 512);
    [Display(Name="層数・波数・渦密度", Order=3)] [AnimationSlider("F2", "", 0.25, 64)]
    public Animation Density { get; } = new(8, 0.25, 64);
    [Display(Name="色の分離・渦の強さ", Order=4)] [AnimationSlider("F2", "", 0, 150)]
    public Animation Dispersion { get; } = new(16, 0, 150);
    [Display(Name="発光", Order=5)] [AnimationSlider("F2", "", 0, 4)]
    public Animation Glow { get; } = new(0.6, 0, 4);
    [Display(Name="位相", Order=6)] [AnimationSlider("F2", "", -1000, 1000)]
    public Animation Phase { get; } = new(0, -1000, 1000);
    [Display(Name="方向", Order=7)] [AnimationSlider("F2", "°", -360, 360)]
    public Animation Angle { get; } = new(0, -360, 360);
    public override IEnumerable<string> CreateExoVideoFilters(int keyFrameIndex, ExoOutputDescription exoOutputDescription) => [];
    public override IVideoEffectProcessor CreateVideoEffect(IGraphicsDevicesAndContext devices) => new RomanProcessor(devices,this);
    protected override IEnumerable<IAnimatable> GetAnimatables() => [Amount, Radius, Density, Dispersion, Glow, Phase, Angle];
}
public enum RomanMode
{
    [Display(Name="色彩地層")] Strata=0,
    [Display(Name="輪郭干渉")] Interference=1,
    [Display(Name="色流体")] PigmentFlow=2
}

