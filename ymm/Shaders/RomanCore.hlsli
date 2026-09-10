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
        // Integrate a static image-guided velocity field. Each frame is independent.
        // Luminance contours steer pigment; a curl field folds flat regions into eddies.
        if (radius <= 0.0) return src;
        float px=x, py=y;
        float h=1.0+min(radius*.04,8.0);
        float frequency=density*.0040906154;
        float stepSize=radius/32.0;
        float ca=cos(angle), sa=sin(angle);
        float rr=0.0, gg=0.0, bb=0.0, weight=0.0;
        float peak=0.0;
        Pixel tip=src;
        LOOP for (int i=0; i<32; ++i)
        {
            Pixel xp=sampleAt(px+h,py), xm=sampleAt(px-h,py);
            Pixel yp=sampleAt(px,py+h), ym=sampleAt(px,py-h);
            float gx=(light(xp)-light(xm))*min(xp.a,xm.a);
            float gy=(light(yp)-light(ym))*min(yp.a,ym.a);
            float tx=-gy*14.0, ty=gx*14.0;
            float swirl=dispersion/50.0;
            float u=px*frequency, v=py*frequency;
            float a1=cos(u*.6+v*.8+phase*.71+1.7);
            float a2=cos(-u*.89+v*.45-phase*.37);
            float vx=tx*ca-ty*sa+swirl*(sin(v+phase)+.48*a1+.135*a2);
            float vy=tx*sa+ty*ca+swirl*(cos(u-phase)-.36*a1+.267*a2);
            // Soft normalization bounds every step, hence total travel <= radius.
            float norm=sqrt(vx*vx+vy*vy+.04);
            px+=stepSize*vx/norm; py+=stepSize*vy/norm;
            tip=sampleAt(px,py);
            float w=(.25+float(i)/32.0)*tip.a;
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
            // Endpoint pigment plus a wake; edge-crossing paths acquire an iridescent sheen.
            float sheen=peak*glow*.7;
            float tint=l*density*.15+phase*.12;
            dst.r=saturate(lerp(tr,rr/weight,.3)+sheen*palette(tint,0.0))*src.a;
            dst.g=saturate(lerp(tg,gg/weight,.3)+sheen*palette(tint,.3333333))*src.a;
            dst.b=saturate(lerp(tb,bb/weight,.3)+sheen*palette(tint,.6666667))*src.a;
        }
    }
    dst.r=lerp(src.r,dst.r,amount); dst.g=lerp(src.g,dst.g,amount); dst.b=lerp(src.b,dst.b,amount);
    dst.a=src.a;
    return dst;
}

