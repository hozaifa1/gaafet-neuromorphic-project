import planar, numpy as np
vgs = [round(float(x), 3) for x in np.arange(0.0, 1.351, 0.05)]  # 28 pts through erased turn-on
print("fine vgs:", vgs, flush=True)
planar.run_mw("planarfine", VE=-6.0, VP=6.0, vgs=vgs)
