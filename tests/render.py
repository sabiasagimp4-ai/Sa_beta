"""Render the very same scalar core as the Direct2D shader; no generated imagery."""
import ctypes, json, sys, time
from pathlib import Path
import numpy as np
from PIL import Image, ImageDraw, ImageFont

LIB = ctypes.CDLL(str(Path(__file__).with_name('reference.so').resolve()))
PTR = ctypes.POINTER(ctypes.c_float)
LIB.render.argtypes = [PTR,PTR,ctypes.c_int,ctypes.c_int,PTR]
LIB.render.restype = None

def render(src, parameters):
    src = np.ascontiguousarray(src, dtype=np.float32)
    dst = np.empty_like(src)
    # Older presets contain the original eight parameters. Fluid parameters
    # default to a neutral, useful simulation when they are omitted.
    values=list(parameters)+[100,100,55,28,8]
    p = np.asarray(values[:13], dtype=np.float32)
    LIB.render(src.ctypes.data_as(PTR), dst.ctypes.data_as(PTR),src.shape[1],src.shape[0],p.ctypes.data_as(PTR))
    return dst

# mode, mix, radius(px), density, dispersion, glow, phase, angle(radians)
PRESETS = [
 ('01 Glass strata', [0,1,8,8,4,.3,0,0]),
 ('02 Opal layers', [0,1,24,12,12,.8,0,.3]),
 ('03 Chromatic fault', [0,1,64,7,35,.7,.4,0]),
 ('04 Vertical rift', [0,1,90,16,48,.5,.2,1.5707963]),
 ('05 Crystal collapse', [0,1,140,28,70,1.2,.8,.6]),
 ('06 Molten spectrum', [0,1,220,9,100,1.6,1.3,-.4]),
 ('07 Edge halo', [1,1,24,1.2,12,.5,0,0]),
 ('08 Spectral echoes', [1,1,64,2.4,45,1.2,0,0]),
 ('09 Interference field', [1,1,120,3,80,1.8,1,0]),
 ('10 Neon engraving', [1,1,32,4,150,2.6,.4,0]),
 ('11 Electric fog', [1,1,180,1.5,100,2.3,1.4,.2]),
 ('12 Wave catastrophe', [1,1,280,5,150,3.2,.6,0]),
]

def main():
    source=Image.open(sys.argv[1]).convert('RGBA')
    out=Path(sys.argv[2]);out.mkdir(parents=True,exist_ok=True)
    # All presets use original-resolution pixel units.
    src=np.asarray(source,dtype=np.float32)/255
    src[:,:,:3]*=src[:,:,3:4]
    font=ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf',19)
    small=ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf',14)
    sheets=[]; records=[]
    for base in (0,6):
        sheet=Image.new('RGB',(1440,820),(17,19,26));draw=ImageDraw.Draw(sheet)
        for j,(name,p) in enumerate(PRESETS[base:base+6]):
            t=time.perf_counter();dst=render(src,p);seconds=time.perf_counter()-t
            image=Image.fromarray(np.uint8(np.clip(dst[:,:,:3],0,1)*255+.5))
            filename=name.replace(' ','_')+'.png';image.save(out/filename)
            thumb=image.resize((480,360),Image.Resampling.LANCZOS)
            x=(j%3)*480;y=(j//3)*410
            sheet.paste(thumb,(x,y));draw.text((x+12,y+366),name,font=font,fill='white')
            draw.text((x+12,y+391),f'R {p[2]}  D {p[3]}  Color {p[4]}  Glow {p[5]}',font=small,fill='#b9c0d2')
            records.append(dict(name=name,parameters=p,seconds=seconds,file=filename))
            print(name,round(seconds,2),'s',flush=True)
        filename='strata_contact.jpg' if base==0 else 'interference_contact.jpg'
        sheet.save(out/filename,quality=94);sheets.append(filename)
    (out/'parameters.json').write_text(json.dumps(records,indent=2))

if __name__=='__main__':main()
