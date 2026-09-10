import numpy as np
from render import render, PRESETS

rng=np.random.default_rng(20260910)
src=rng.random((19,23,4),dtype=np.float32)
src[:,:,:3]*=src[:,:,3:4]
count=0
for _,preset in PRESETS:
    a=render(src,preset)
    assert np.isfinite(a).all()
    assert (a>=0).all() and (a<=1).all()
    assert np.array_equal(a[:,:,3],src[:,:,3])
    assert (a[:,:,:3]<=a[:,:,3:4]+1e-6).all()
    p=preset.copy();p[1]=0
    assert np.array_equal(render(src,p),src), 'mix zero must be identity'
    assert np.array_equal(render(src,preset),a), 'seek/replay determinism'
    assert not render(np.zeros_like(src),preset).any()
    count+=6
for mode in (0,1):
    for shape in [(1,1,4),(1,17,4),(13,1,4)]:
        one=np.full(shape,.5,np.float32);one[:,:,3]=1
        for radius in (0,512):
            out=render(one,[mode,1,radius,64,150,4,1000,6.28])
            assert np.isfinite(out).all()
            count+=1
# No edges => no waves, including at frame boundaries.
flat=np.ones((23,17,4),np.float32);flat[:,:,:3]=.4
assert np.allclose(render(flat,[1,1,512,2,0,4,0,0]),flat)
print(f'PASS {count+1} core checks: alpha, identity, finite extremes, deterministic replay, flat field')
