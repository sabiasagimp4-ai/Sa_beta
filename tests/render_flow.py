"""CPU execution of the production shader core; pixel units at source resolution."""
from render import render
from PIL import Image, ImageDraw, ImageFont
from pathlib import Path
import numpy as np
import json, sys, time

PRESETS = [
    ('01 Contour silk', [2,1,32,8,0,.3,0,0,70,35,75,65,4]),
    ('02 Liquid glass', [2,1,65,5,35,.4,.4,0,100,80,55,35,6]),
    ('03 Pigment currents', [2,1,120,7,65,.8,0,.3,130,130,45,28,8]),
    ('04 Oil ribbons', [2,1,180,12,90,1.4,.7,0,150,165,35,20,9]),
    ('05 Color whirlpool', [2,1,280,5,100,1.8,1.2,.5,180,190,70,12,10]),
    ('06 Silk storm', [2,1,380,18,150,2.4,.3,1.2,200,200,90,5,12]),
]

def main():
    out=Path(sys.argv[2]);out.mkdir(parents=True,exist_ok=True)
    src=np.array(Image.open(sys.argv[1]).convert('RGBA'),dtype=np.float32)/255
    src[:,:,:3]*=src[:,:,3:4]
    sheet=Image.new('RGB',(1440,828),'#10141b');draw=ImageDraw.Draw(sheet)
    font=ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf',19)
    records=[]
    for i,(name,p) in enumerate(PRESETS):
        start=time.perf_counter();dst=render(src,p)
        im=Image.fromarray(np.uint8(np.clip(dst[:,:,:3],0,1)*255+.5))
        fn=name.replace(' ','_')+'.png';im.save(out/fn)
        x=i%3*480;y=i//3*414
        sheet.paste(im.resize((480,360),Image.Resampling.LANCZOS),(x,y))
        draw.text((x+12,y+363),name,font=font,fill='white')
        draw.text((x+12,y+388),f'R {p[2]} / D {p[3]} / Color {p[9]} / Water {p[8]} / Iter {p[12]}',font=font,fill='#aebacf')
        records.append(dict(name=name,parameters=p,file=fn,seconds=time.perf_counter()-start))
        print(name,round(records[-1]['seconds'],2),flush=True)
    sheet.save(out/'flow_contact.jpg',quality=95)
    (out/'parameters.json').write_text(json.dumps(records,indent=2))

if __name__=='__main__': main()
