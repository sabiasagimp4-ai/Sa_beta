// This scalar core is compiled unchanged as HLSL and C++ for reference renders.
// sampleAt receives scene coordinates and returns premultiplied RGBA.
struct Pixel { float r; float g; float b; float a; };
Pixel sampleAt(float x, float y);
float light(Pixel c) { return c.a > 0.00001 ? (c.r*.2126+c.g*.7152+c.b*.0722)/c.a : 0.0; }
float palette(float t, float shift) { return .5+.5*cos(6.2831853*(t+shift)); }
Pixel roman(float x, float y)
{
    Pixel src = sampleAt(x,y);
    if (amount <= 0.0 || src.a <= 0.00001) return src;
    float l = light(src);
    Pixel dst = src;
    if (mode < .5)
    {
        // Quantized luminance sheets move independently; phase travels through sheets.
        float z = l*density+phase;
        float layer = floor(z);
        float t = frac(z);
        float displacement = sin(layer*2.3999632+phase)*radius;
        float dx = cos(angle), dy = sin(angle);
        Pixel cr = sampleAt(x+dx*(displacement+dispersion),y+dy*(displacement+dispersion));
        Pixel cg = sampleAt(x+dx*displacement,y+dy*displacement);
        Pixel cb = sampleAt(x+dx*(displacement-dispersion),y+dy*(displacement-dispersion));
        float edge = pow(saturate(1.0-abs(t-.5)*2.0), 16.0);
        float rim = edge*glow;
        float pr = palette(layer*.097+phase*.07,0.0);
        float pg = palette(layer*.097+phase*.07,.3333333);
        float pb = palette(layer*.097+phase*.07,.6666667);
        dst.r = saturate((cr.a>0.00001 ? cr.r/cr.a : 0.0)+rim*pr)*src.a;
        dst.g = saturate((cg.a>0.00001 ? cg.g/cg.a : 0.0)+rim*pg)*src.a;
        dst.b = saturate((cb.a>0.00001 ? cb.b/cb.a : 0.0)+rim*pb)*src.a;
    }
    else
    {
        // Difference of successive radial samples excites a damped RGB wave kernel.
        // Each edge is a source; signed waves interfere, rather than just blurring.
        float wr=0.0, wg=0.0, wb=0.0;
        LOOP for(int d=0; d<16; ++d)
        {
            float theta = 6.2831853*(float(d)/16.0)+angle;
            float dx=cos(theta),dy=sin(theta);
            float previous=l;
            LOOP for(int s=1; s<=16; ++s)
            {
                float u=float(s)/16.0;
                float dist=u*radius;
                Pixel q=sampleAt(x+dx*dist,y+dy*dist);
                float current=q.a>0.00001 ? light(q) : previous;
                float e=(current-previous)*min(q.a,src.a);
                previous=current;
                float envelope=exp(-u*2.5);
                float wave=6.2831853*u*density-phase;
                float spread=dispersion*.03;
                wr+=e*envelope*cos(wave-spread);
                wg+=e*envelope*cos(wave);
                wb+=e*envelope*cos(wave+spread);
            }
        }
        float gain=glow*1.8;
        float base=1.0-saturate(dispersion/150.0)*.8;
        dst.r=(1.0-(1.0-src.r/src.a*base)/(1.0+abs(wr)*gain))*src.a;
        dst.g=(1.0-(1.0-src.g/src.a*base)/(1.0+abs(wg)*gain))*src.a;
        dst.b=(1.0-(1.0-src.b/src.a*base)/(1.0+abs(wb)*gain))*src.a;
    }
    dst.r=lerp(src.r,dst.r,amount); dst.g=lerp(src.g,dst.g,amount); dst.b=lerp(src.b,dst.b,amount);
    dst.a=src.a;
    return dst;
}
