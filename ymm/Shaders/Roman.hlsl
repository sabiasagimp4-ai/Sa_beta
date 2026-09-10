#define D2D_ENTRY main
#include <d2d1effecthelpers.hlsli>
float mode, amount, radius, density;
float dispersion, glow, phase, angle;
float waterAmount, colorInfluence, pressure, viscosity;
float iterations, fluidPad0, fluidPad1, fluidPad2;
float4 inputBounds;
// Precomputed once on the host when the corresponding animated values change.
float4 directions[16];
float4 waves[16];
float directionX(int i) { return directions[i].x; }
float directionY(int i) { return directions[i].y; }
float waveR(int i) { return waves[i].x; }
float waveG(int i) { return waves[i].y; }
float waveB(int i) { return waves[i].z; }
float waveEnvelope(int i) { return waves[i].w; }
#define LOOP [loop]
#include "RomanCore.hlsli"
Pixel sampleAt(float x, float y)
{
    float2 p=clamp(float2(x,y),inputBounds.xy+.5,inputBounds.zw-.5);
    float4 uv=D2DGetInputCoordinate(0);
    float4 c=InputTexture0.SampleLevel(InputSampler0,uv.xy+uv.zw*(p-D2DGetScenePosition().xy),0);
    Pixel r; r.r=c.r;r.g=c.g;r.b=c.b;r.a=c.a;return r;
}
D2D_PS_ENTRY(main)
{
    float2 p=D2DGetScenePosition().xy;
    Pixel c=roman(p.x,p.y);
    return float4(c.r,c.g,c.b,c.a);
}
