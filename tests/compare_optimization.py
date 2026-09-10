"""Compare the frozen 8522642 core with the optimized core; optional full-image timings."""
import ctypes,sys,time,json
from pathlib import Path
import numpy as np
from PIL import Image
from render import PTR,LIB,PRESETS
old=ctypes.CDLL(str(Path(__file__).with_name('baseline.so').resolve()))
old.render.argtypes=LIB.render.argtypes;old.render.restype=None

def run(lib,src,p):
    dst=np.empty_like(src)
    p=np.asarray(list(p)+[100,100,55,28,8],np.float32)[:13]
    t=time.perf_counter()
    lib.render(src.ctypes.data_as(PTR),dst.ctypes.data_as(PTR),src.shape[1],src.shape[0],p.ctypes.data_as(PTR))
    return dst,time.perf_counter()-t

rng=np.random.default_rng(137)
cases=[]
for shape in [(1,1,4),(31,29,4),(1,31,4)]:
    src=rng.random(shape,dtype=np.float32);src[:,:,:3]*=src[:,:,3:4]
    cases.append(src)
params=[p for _,p in PRESETS]+[[m,a,r,d,c,g,ph,an] for m in [0,1] for a,r,d,c,g,ph,an in [(0,512,64,150,4,1000,6.28),(1,0,.25,0,0,-1000,-6.28),(1,512,64,150,4,-999.9,2.8)]]
max_error=0
for src in cases:
    for p in params:
        a,_=run(old,src,p);b,_=run(LIB,src,p)
        err=float(np.max(np.abs(a-b)));max_error=max(max_error,err)
        assert err<=1e-6,(p,err)
print('PASS',len(cases)*len(params),'baseline comparisons; max float difference',max_error,flush=True)
if len(sys.argv)>1:
    src=np.asarray(Image.open(sys.argv[1]).convert('RGBA'),np.float32)/255
    src[:,:,:3]*=src[:,:,3:4]
    rows=[]
    for name,p in PRESETS:
        before=[];after=[]
        # Warm both kernels; alternate order to reduce systematic thermal/order bias.
        run(old,src,p);run(LIB,src,p)
        for i in range(3):
            if i%2:
                b,tb=run(LIB,src,p);a,ta=run(old,src,p)
            else:
                a,ta=run(old,src,p);b,tb=run(LIB,src,p)
            before.append(ta);after.append(tb)
        err=float(np.max(np.abs(a-b)))
        a8=np.uint8(np.clip(a,0,1)*255+.5);b8=np.uint8(np.clip(b,0,1)*255+.5)
        row=dict(name=name,before_s=float(np.median(before)),after_s=float(np.median(after)),speedup=float(np.median(before)/np.median(after)),max_float_error=err,changed_8bit_channels=int(np.count_nonzero(a8!=b8)))
        rows.append(row);print(json.dumps(row),flush=True)
    Path(sys.argv[2]).write_text(json.dumps(dict(resolution=[src.shape[1],src.shape[0]],rows=rows),indent=2))
