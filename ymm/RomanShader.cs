using System.Runtime.InteropServices;
using System.Runtime.CompilerServices;
using System.Numerics;
using Vortice;
using Vortice.Direct2D1;
using YukkuriMovieMaker.Commons;
using YukkuriMovieMaker.Player.Video;
namespace SaBetaYmm;
internal sealed class RomanShader(IGraphicsDevicesAndContext devices) : D2D1CustomShaderEffectBase(Create<RomanShader.Impl>(devices))
{
    public float Mode { set => SetValue(0,value); }
    public float Amount { set => SetValue(1,value); }
    public float Radius { set => SetValue(2,value); }
    public float Density { set => SetValue(3,value); }
    public float Dispersion { set => SetValue(4,value); }
    public float Glow { set => SetValue(5,value); }
    public float Phase { set => SetValue(6,value); }
    public float Angle { set => SetValue(7,value); }
    [CustomEffect(1)]
    private sealed class Impl : D2D1CustomShaderEffectImplBase<Impl>
    {
        private Constants _constants = new() { Density=8, Radius=32, Amount=1 };
        public Impl() : base(ShaderResourceLoader.Get("Roman")) { }
        [CustomEffectProperty(PropertyType.Float, 0)] public float Mode { get => _constants.Mode; set { _constants.Mode=float.IsFinite(value) ? Math.Clamp(value,0f,1f) : 0f; UpdateConstants(); } }
        [CustomEffectProperty(PropertyType.Float, 1)] public float Amount { get => _constants.Amount; set { _constants.Amount=float.IsFinite(value) ? Math.Clamp(value,0f,1f) : 0f; UpdateConstants(); } }
        [CustomEffectProperty(PropertyType.Float, 2)] public float Radius { get => _constants.Radius; set { _constants.Radius=float.IsFinite(value) ? Math.Clamp(value,0f,512f) : 0f; UpdateConstants(); } }
        [CustomEffectProperty(PropertyType.Float, 3)] public float Density { get => _constants.Density; set { _constants.Density=float.IsFinite(value) ? Math.Clamp(value,0.25f,64f) : 0.25f; UpdateConstants(); } }
        [CustomEffectProperty(PropertyType.Float, 4)] public float Dispersion { get => _constants.Dispersion; set { _constants.Dispersion=float.IsFinite(value) ? Math.Clamp(value,0f,150f) : 0f; UpdateConstants(); } }
        [CustomEffectProperty(PropertyType.Float, 5)] public float Glow { get => _constants.Glow; set { _constants.Glow=float.IsFinite(value) ? Math.Clamp(value,0f,4f) : 0f; UpdateConstants(); } }
        [CustomEffectProperty(PropertyType.Float, 6)] public float Phase { get => _constants.Phase; set { _constants.Phase=float.IsFinite(value) ? Math.Clamp(value,-1000f,1000f) : 0f; UpdateConstants(); } }
        [CustomEffectProperty(PropertyType.Float, 7)] public float Angle { get => _constants.Angle; set { _constants.Angle=float.IsFinite(value) ? Math.Clamp(value,-7f,7f) : 0f; UpdateConstants(); } }
        private float _cachedAngle=float.NaN, _cachedDensity=float.NaN, _cachedPhase=float.NaN, _cachedDispersion=float.NaN;
        protected override void UpdateConstants()
        {
            if (_cachedAngle != _constants.Angle)
            {
                for (int i=0; i<16; i++)
                {
                    float theta=6.2831853f*(i/16f)+_constants.Angle;
                    _constants.Directions[i]=new Vector4(MathF.Cos(theta),MathF.Sin(theta),0,0);
                }
                _cachedAngle=_constants.Angle;
            }
            if (_cachedDensity != _constants.Density || _cachedPhase != _constants.Phase || _cachedDispersion != _constants.Dispersion)
            {
                for (int i=0; i<16; i++)
                {
                    float u=(i+1)/16f;
                    float wave=6.2831853f*u*_constants.Density-_constants.Phase;
                    float spread=_constants.Dispersion*.03f;
                    _constants.Waves[i]=new Vector4(MathF.Cos(wave-spread),MathF.Cos(wave),MathF.Cos(wave+spread),MathF.Exp(-u*2.5f));
                }
                _cachedDensity=_constants.Density; _cachedPhase=_constants.Phase; _cachedDispersion=_constants.Dispersion;
            }
            drawInformation?.SetPixelShaderConstantBuffer(_constants);
        }
        public override void MapInputRectsToOutputRect(RawRect[] inputRects, RawRect[] inputOpaqueSubRects, out RawRect outputRect, out RawRect outputOpaqueSubRect)
        {
            outputRect=inputRects[0]; outputOpaqueSubRect=default;
            _constants.Left=outputRect.Left; _constants.Top=outputRect.Top;
            _constants.Right=outputRect.Right; _constants.Bottom=outputRect.Bottom;
            UpdateConstants();
        }
        public override void MapOutputRectToInputRects(RawRect outputRect, RawRect[] inputRects)
        {
            int halo=(int)MathF.Ceiling(_constants.Radius+_constants.Dispersion)+2;
            inputRects[0]=new(outputRect.Left-halo,outputRect.Top-halo,outputRect.Right+halo,outputRect.Bottom+halo);
        }
        [InlineArray(16)]
        private struct VectorTable { private Vector4 _element0; }
        [StructLayout(LayoutKind.Sequential)]
        private struct Constants
        {
            public float Mode,Amount,Radius,Density;
            public float Dispersion,Glow,Phase,Angle;
            public float Left,Top,Right,Bottom;
            public VectorTable Directions, Waves;
        }
    }
}
