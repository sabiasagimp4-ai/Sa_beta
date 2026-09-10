using Vortice.Direct2D1;
using YukkuriMovieMaker.Commons;
using YukkuriMovieMaker.Player.Video;
namespace SaBetaYmm;
internal sealed class RomanProcessor : IVideoEffectProcessor
{
    private readonly RomanEffect _item;
    private readonly RomanShader? _shader;
    private readonly ID2D1Image? _output;
    private ID2D1Image? _input;
    public RomanProcessor(IGraphicsDevicesAndContext devices, RomanEffect item)
    {
        _item=item;
        var shader=new RomanShader(devices);
        try
        {
            if (!shader.IsEnabled) return;
            _output=shader.Output;
            _shader=shader;
        }
        finally { if (_shader is null) shader.Dispose(); }
    }
    public ID2D1Image Output => _output ?? _input ?? throw new InvalidOperationException("入力が未設定です。");
    public void SetInput(ID2D1Image? input) { _input=input; _shader?.SetInput(0,input,true); }
    public void ClearInput() { _input=null; _shader?.SetInput(0,null,true); }
    public DrawDescription Update(EffectDescription effectDescription)
    {
        if (_shader is null) return effectDescription.DrawDescription;
        var frame=effectDescription.ItemPosition.Frame;
        var length=effectDescription.ItemDuration.Frame;
        var fps=effectDescription.FPS;
        _shader.Mode=(float)_item.Mode;
        _shader.Amount=(float)(_item.Amount.GetValue(frame,length,fps) / 100.0);
        _shader.Radius=(float)(_item.Radius.GetValue(frame,length,fps) );
        _shader.Density=(float)(_item.Density.GetValue(frame,length,fps) );
        _shader.Dispersion=(float)(_item.Dispersion.GetValue(frame,length,fps) );
        _shader.Glow=(float)(_item.Glow.GetValue(frame,length,fps) );
        _shader.Phase=(float)(_item.Phase.GetValue(frame,length,fps) );
        _shader.Angle=(float)(_item.Angle.GetValue(frame,length,fps) * Math.PI / 180.0);
        return effectDescription.DrawDescription;
    }
    public void Dispose() { ClearInput(); _output?.Dispose(); _shader?.Dispose(); }
}
