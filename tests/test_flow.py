import numpy as np
from render import render
from render_flow import PRESETS

rng=np.random.default_rng(813)
src=rng.random((27,31,4),dtype=np.float32)
src[:,:,:3]*=src[:,:,3:4]
for _,p in PRESETS:
    dst=render(src,p)
    assert np.isfinite(dst).all()
    assert (dst>=0).all() and (dst[:,:,:3]<=src[:,:,3:4]+1e-6).all()
    assert np.array_equal(dst[:,:,3],src[:,:,3])
    assert np.array_equal(dst,render(src,p))
    zero=p.copy();zero[1]=0
    assert np.array_equal(render(src,zero),src)
    zero=p.copy();zero[2]=0
    assert np.array_equal(render(src,zero),src)
    assert not render(np.zeros_like(src),p).any()
for shape in [(1,1,4),(1,29,4),(31,1,4),(27,31,4)]:
    flat=np.full(shape,.25,np.float32);flat[:,:,3]=.5
    for d in (.25,64):
        p=[2,1,512,d,150,4,1000,6.28]
        assert np.allclose(render(flat,p),flat,atol=2e-6), 'flat field must stay flat'
# A coloured step must actually be transported by the curl field.
step=np.zeros((41,47,4),np.float32);step[:,:,3]=1;step[:,:23,0]=1;step[:,23:,2]=1
out=render(step,[2,1,80,8,100,0,.3,0])
assert np.abs(out-step).max()>.1
print('PASS flow: 6 presets, identity, alpha, repeatability, transparent/flat/degenerate inputs, extremes, transport')
