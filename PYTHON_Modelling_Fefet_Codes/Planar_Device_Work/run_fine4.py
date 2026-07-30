import planar, numpy as np
fine = [round(float(x), 3) for x in np.arange(-0.3, 1.001, 0.05)]
ext = [-3.0, -2.6, -2.2, -1.8, -1.4, -1.0, -0.6]
vgs = sorted(set(ext + fine))
print("vgs:", vgs, flush=True)
print("n_points:", len(vgs), flush=True)
planar.run_mw("planarfinal", VE=-4.0, VP=3.5, vgs=vgs)
