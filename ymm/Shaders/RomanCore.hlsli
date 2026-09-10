// This scalar core is compiled unchanged as HLSL and C++ for reference renders.
// sampleAt receives scene coordinates and returns premultiplied RGBA.
struct Pixel { float r; float g; float b; float a; };
Pixel sampleAt(float x, float y);
float light(Pixel c) { return c.a > 0.00001 ? (c.r*.2126+c.g*.7152+c.b*.0722)/c.a : 0.0; }
float palette(float t, float shift) { return .5+.5*cos(6.2831853*(t+shift)); }
float chroma(Pixel c)
{
    if (c.a <= 0.00001) return 0.0;
    float r=c.r/c.a, g=c.g/c.a, b=c.b/c.a;
    return max(r,max(g,b))-min(r,min(g,b));
}
float hue01(Pixel c)
{
    if (c.a <= 0.00001) return 0.0;
    float r=c.r/c.a, g=c.g/c.a, b=c.b/c.a;
    float hi=max(r,max(g,b)), lo=min(r,min(g,b)), d=hi-lo;
    if (d < 0.00001) return 0.0;
    float h;
    if (hi == r) h=(g-b)/d;
    else if (hi == g) h=2.0+(b-r)/d;
    else h=4.0+(r-g)/d;
    return frac(h/6.0+1.0);
}
float2 norm2(float2 v)
{
    float m=sqrt(v.x*v.x+v.y*v.y);
    return m > 0.00001 ? float2(v.x/m,v.y/m) : float2(0.0,0.0);
}
float2 rotate2(float2 v, float a)
{
    float c=cos(a), s=sin(a);
    return float2(v.x*c-v.y*s,v.x*s+v.y*c);
}

// Image-guided velocity. Hue supplies a direction, chroma supplies its mass,
// and luminance/chroma contours supply the tangent that carries water around edges.
float2 fluidVelocityRaw(float x, float y)
{
    Pixel c=sampleAt(x,y);
    if (c.a <= 0.00001) return float2(0.0,0.0);
    float h=0.8+min(radius*.02,8.0);
    Pixel xp=sampleAt(x+h,y), xm=sampleAt(x-h,y);
    Pixel yp=sampleAt(x,y+h), ym=sampleAt(x,y-h);
    float gx=(light(xp)-light(xm))/(2.0*h);
    float gy=(light(yp)-light(ym))/(2.0*h);
    float cx=(chroma(xp)-chroma(xm))/(2.0*h);
    float cy=(chroma(yp)-chroma(ym))/(2.0*h);
    float edge=saturate(sqrt(gx*gx+gy*gy)*7.0);
    float cMass=saturate(chroma(c)*2.2)*saturate(colorInfluence/100.0);
    float hue=hue01(c)*6.2831853+phase*.021;
    float2 edgeTangent=rotate2(norm2(float2(-gy,gx)),angle);
    float2 colorDir=rotate2(float2(cos(hue),sin(hue)),angle);
    float2 colorTangent=rotate2(norm2(float2(-cy,cx)),angle*.5);
    float f=density*.0040906154;
    float u=x*f, v=y*f;
    float2 eddy=float2(
        sin(v+phase)+.48*cos(u*.6+v*.8+phase*.71+1.7)+.135*cos(-u*.89+v*.45-phase*.37),
        cos(u-phase)-.36*cos(u*.6+v*.8+phase*.71+1.7)+.267*cos(-u*.89+v*.45-phase*.37));
    float2 velocity=edgeTangent*(.28+.72*edge)+colorDir*cMass+colorTangent*cMass*.55;
    velocity+=norm2(eddy)*(dispersion/150.0)*(.2+.8*cMass);
    float water=saturate(waterAmount/100.0);
    return velocity*(.35+water*.65);
}

// A local incompressibility step: remove the dominant divergent component,
// blend toward neighbouring velocities for viscosity, then add a small
// vorticity term. This is the per-pixel pressure/advection solve used by the
// single-frame effect.
float2 fluidVelocity(float x, float y)
{
    float h=0.8+min(radius*.02,8.0);
    float2 v=fluidVelocityRaw(x,y);
    float2 vl=fluidVelocityRaw(x-h,y), vr=fluidVelocityRaw(x+h,y);
    float2 vd=fluidVelocityRaw(x,y-h), vu=fluidVelocityRaw(x,y+h);
    float2 pressureForce=float2(vr.x-vl.x,vu.y-vd.y)/(2.0*h);
    v-=pressureForce*saturate(pressure/100.0)*.32;
    float2 average=(vl+vr+vd+vu)*.25;
    v=lerp(v,average,saturate(viscosity/100.0)*.45);
    float curl=(vr.y-vl.y-vu.x+vd.x)/(2.0*h);
    v+=float2(-v.y,v.x)*curl*saturate(dispersion/150.0)*.06;
    float m=sqrt(v.x*v.x+v.y*v.y);
    return m>2.5 ? v*(2.5/m) : v;
}

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
    else if (mode < 1.5)
    {
        // Difference of successive radial samples excites a damped RGB wave kernel.
        // Each edge is a source; signed waves interfere, rather than just blurring.
        float wr=0.0, wg=0.0, wb=0.0;
        LOOP for(int d=0; d<16; ++d)
        {
            float dx=directionX(d),dy=directionY(d);
            float previous=l;
            LOOP for(int s=1; s<=16; ++s)
            {
                float u=float(s)/16.0;
                float dist=u*radius;
                Pixel q=sampleAt(x+dx*dist,y+dy*dist);
                float current=q.a>0.00001 ? light(q) : previous;
                float e=(current-previous)*min(q.a,src.a);
                previous=current;
                float envelope=waveEnvelope(s-1);
                wr+=e*envelope*waveR(s-1);
                wg+=e*envelope*waveG(s-1);
                wb+=e*envelope*waveB(s-1);
            }
        }
        float gain=glow*1.8;
        float base=1.0-saturate(dispersion/150.0)*.8;
        dst.r=(1.0-(1.0-src.r/src.a*base)/(1.0+abs(wr)*gain))*src.a;
        dst.g=(1.0-(1.0-src.g/src.a*base)/(1.0+abs(wg)*gain))*src.a;
        dst.b=(1.0-(1.0-src.b/src.a*base)/(1.0+abs(wb)*gain))*src.a;
    }
    else
    {
        // Semi-Lagrangian dye advection with a local pressure/viscosity solve.
        // Color controls both the velocity direction (hue) and the transported mass (chroma).
        if (radius <= 0.0 || waterAmount <= 0.0) return src;
        float water=saturate(waterAmount/100.0);
        int count=(int)clamp(iterations,1.0,12.0);
        float stepSize=radius/max(float(count),1.0f);
        float px=x, py=y;
        float rr=0.0, gg=0.0, bb=0.0, weight=0.0;
        float peak=0.0;
        Pixel tip=src;
        LOOP for (int i=0; i<12; ++i)
        {
            if (i>=count) break;
            float2 velocity=fluidVelocity(px,py);
            float speed=sqrt(velocity.x*velocity.x+velocity.y*velocity.y);
            float2 direction=norm2(velocity);
            // Backtrace from the output pixel to fetch upstream dye.
            float travel=stepSize*(.20+.80*water)*min(speed,1.65f);
            px-=direction.x*travel; py-=direction.y*travel;
            tip=sampleAt(px,py);
            float dyeMass=.18+.82*water;
            float colorMass=.35+.65*saturate(chroma(tip)*2.0);
            float fade=exp(-saturate(viscosity/100.0)*float(i)/max(float(count),1.0f)*1.4);
            float w=dyeMass*colorMass*fade*(.45+.55*float(i+1)/max(float(count),1.0f))*tip.a;
            if (tip.a>0.00001)
            {
                rr+=tip.r/tip.a*w; gg+=tip.g/tip.a*w; bb+=tip.b/tip.a*w;
                weight+=w;
            }
            peak=max(peak,abs(light(tip)-l)*tip.a);
        }
        if (weight>0.00001)
        {
            float tr=tip.a>0.00001 ? tip.r/tip.a : rr/weight;
            float tg=tip.a>0.00001 ? tip.g/tip.a : gg/weight;
            float tb=tip.a>0.00001 ? tip.b/tip.a : bb/weight;
            float diffusion=saturate(viscosity/100.0)*.35;
            float sheen=peak*glow*.7;
            float tint=l*density*.15+phase*.12;
            float ar=lerp(lerp(tr,rr/weight,.30),l,diffusion);
            float ag=lerp(lerp(tg,gg/weight,.30),l,diffusion);
            float ab=lerp(lerp(tb,bb/weight,.30),l,diffusion);
            ar=saturate(ar+sheen*palette(tint,0.0));
            ag=saturate(ag+sheen*palette(tint,.3333333));
            ab=saturate(ab+sheen*palette(tint,.6666667));
            float carry=saturate(.25+.75*water);
            dst.r=lerp(src.r,ar*src.a,carry);
            dst.g=lerp(src.g,ag*src.a,carry);
            dst.b=lerp(src.b,ab*src.a,carry);
        }
    }
    dst.r=lerp(src.r,dst.r,amount); dst.g=lerp(src.g,dst.g,amount); dst.b=lerp(src.b,dst.b,amount);
    dst.a=src.a;
    return dst;
}
