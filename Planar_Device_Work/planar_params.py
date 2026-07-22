"""Planar-FeFET SNN params (auto-extracted; geometry-only diff vs GAA, same calibrated par).
Drop-in analogue of Device_Optimization/SNN_PARAMETERS.md for the ECG-LSNN stage1.
Device = bulk planar NMOS FeFET, single top MFIS gate SiO2 2nm/HZO 10nm/TiN, p-body 5e17.
Op point: V_read=0.0 V, V_pgm=4.5 V, V_DS=0.05 V, WF=4.35 eV.
"""
DEVICE = dict(
    arch="planar (bulk, single top gate)",
    # --- electrostatics ---
    SS_ers_mVdec=98.4,           # subthreshold slope, erased branch (steepest)
    Vth_ers_V=0.943,              # erased Vth @ Icc=1e-2 uA/um
    Vth_pgm_V=float("-inf"),        # programmed latched fully-ON: Vth_pgm < -1.0 V (never crosses Icc)
    MW_volts_lowerbound=1.94,        # >= this; true window larger (Vth_pgm below sweep floor)
    # --- read window / conductance (-> stage1 fefet_synapse) ---
    R_off_ohm=1.2173e+09,           # erased read @ Vg=0
    R_on_ohm=2.0582e+02,            # programmed read @ Vg=0
    window=5.9144e+06,             # ON/OFF current ratio at Vg=0
    g_min_S=8.2151e-10,            # 1/R_off  -> g_min
    g_max_S=4.8587e-03,            # 1/R_on   -> g_max
    n_levels=8,                  # distinguishable LTP levels (>=1.5x apart)
    # --- dynamics / energy ---
    dVth_per_pulse_V=-4.6005e-02,   # mean Vth shift per program pulse (via SS)
    E_pulse_J=6.847e-13,        # integ V_pgm*|I_gate|dt, mean per program pulse (per um)
    fire_ratio=3.574e+06,         # ID(pN)/ID_baseline at op point
    fire_ratio_p9=1.019e+05,         # ID(p9)/ID_baseline (GAA fire-at-P9 criterion)
    retention_pct_100us=67.8,   # % programmed current retained over 100 us hold
    # --- polarization ---
    dP_C_cm2=3.887e-06,              # |P_pgm - P_ers| retained (top-FE y-probe)
    # --- operating point ---
    V_read=0.0, V_pgm=4.5, V_DS=0.05, WF=4.35,
)

# stage1 drop-in: g_min, g_max = DEVICE["g_min_S"], DEVICE["g_max_S"]; NLEVELS=DEVICE["n_levels"]
