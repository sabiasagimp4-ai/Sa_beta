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
    low=p.copy();low[8]=0
    assert np.array_equal(render(src,low),src), 'zero water must be identity'
for shape in [(1,1,4),(1,29,4),(31,1,4),(27,31,4)]:
    flat=np.full(shape,.25,np.float32);flat[:,:,3]=.5
    for d in (.25,64):
        p=[2,1,512,d,150,4,1000,6.28,100,100,55,28,12]
        assert np.allclose(render(flat,p),flat,atol=2e-6), 'flat field must stay flat'
# A coloured step must actually be transported by the curl field.
step=np.zeros((41,47,4),np.float32);step[:,:,3]=1;step[:,:23,0]=1;step[:,23:,2]=1
out=render(step,[2,1,240,12,150,1.4,.3,0,180,200,70,12,10])
assert np.abs(out-step).max()>.1
# The new controls must alter transport independently: hue/chroma can redirect
# the velocity field, while water amount changes how much dye is carried.
base=[2,1,160,8,100,1,.3,0,100,0,55,28,8]
color_guided=base.copy();color_guided[9]=200
assert np.abs(render(step,base)-render(step,color_guided)).max()>.05
thin=base.copy();thin[8]=20
full=base.copy();full[8]=200
assert np.abs(render(step,thin)-render(step,full)).max()>.05
print('PASS flow: presets, identity, alpha, repeatability, transparent/flat/degenerate inputs, extremes, color-guided direction, water transport')
