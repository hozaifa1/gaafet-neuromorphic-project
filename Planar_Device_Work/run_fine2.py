import planar, numpy as np
fine = [round(float(x), 3) for x in np.arange(-0.3, 0.701, 0.05)]
ext = [-2.2, -1.8, -1.4, -1.0, -0.6]
vgs = sorted(set(ext + fine))
print("vgs:", vgs, flush=True)
planar.run_mw("planarfine2", VE=-5.0, VP=5.0, vgs=vgs)
