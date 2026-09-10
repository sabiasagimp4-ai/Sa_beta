#include <cmath>
#include <algorithm>
#include <cstddef>
using std::cos; using std::sin; using std::exp; using std::pow; using std::floor;
using std::min; using std::max; using std::sqrt; using std::abs;
static float saturate(float x) { return std::clamp(x,0.f,1.f); }
static float frac(float x) { return x-std::floor(x); }
static float lerp(float a,float b,float t) { return a+(b-a)*t; }
static thread_local float mode,amount,radius,density,dispersion,glow,phase,angle;
static thread_local const float* pixels;
static thread_local int width,height;
#define LOOP
#ifdef ROMAN_BASELINE
#include "baseline/RomanCore.hlsli"
#else
static thread_local float directions[16][2], waves[16][4];
static float directionX(int i) { return directions[i][0]; }
static float directionY(int i) { return directions[i][1]; }
static float waveR(int i) { return waves[i][0]; }
static float waveG(int i) { return waves[i][1]; }
static float waveB(int i) { return waves[i][2]; }
static float waveEnvelope(int i) { return waves[i][3]; }
#include "../ymm/Shaders/RomanCore.hlsli"
#endif
Pixel sampleAt(float x,float y)
{
    x=std::clamp(x-.5f,0.f,float(width-1));
    y=std::clamp(y-.5f,0.f,float(height-1));
    int x0=int(x),y0=int(y),x1=std::min(x0+1,width-1),y1=std::min(y0+1,height-1);
    float tx=x-x0,ty=y-y0;
    float result[4];
    for(int c=0;c<4;++c) result[c]=lerp(lerp(pixels[(y0*width+x0)*4+c],pixels[(y0*width+x1)*4+c],tx),lerp(pixels[(y1*width+x0)*4+c],pixels[(y1*width+x1)*4+c],tx),ty);
    return {result[0],result[1],result[2],result[3]};
}
extern "C" void render(const float* src,float* dst,int w,int h,const float* p)
{
    #pragma omp parallel
    {
        pixels=src;width=w;height=h;
        mode=p[0];amount=p[1];radius=p[2];density=p[3];dispersion=p[4];glow=p[5];phase=p[6];angle=p[7];
        #ifndef ROMAN_BASELINE
        for(int i=0;i<16;++i) {
            // Match the original scalar core's arithmetic, including intermediate rounding.
            float theta=6.2831853*(float(i)/16.0)+angle;
            directions[i][0]=cos(theta); directions[i][1]=sin(theta);
            float u=float(i+1)/16.0;
            float envelope=exp(-u*2.5);
            float wave=6.2831853*u*density-phase;
            float spread=dispersion*.03;
            waves[i][0]=cos(wave-spread);waves[i][1]=cos(wave);waves[i][2]=cos(wave+spread);waves[i][3]=envelope;
        }
        #endif
        #pragma omp for
        for(int y=0;y<h;++y) for(int x=0;x<w;++x)
        {
            Pixel q=roman(x+.5f,y+.5f);std::size_t i=(std::size_t(y)*w+x)*4;
            dst[i]=q.r;dst[i+1]=q.g;dst[i+2]=q.b;dst[i+3]=q.a;
        }
    }
}

