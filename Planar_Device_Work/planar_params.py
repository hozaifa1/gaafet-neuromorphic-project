"""Planar-FeFET SNN params (auto-extracted). TRUE single-gate ABLATION of the
optimized GAA: identical T_si=5nm/T_ox=1nm/T_fe=7nm/T_metal=5nm/L_gate=100nm/L_ov=15nm/
N_sub=1e16/N_sd=5e19/WF=4.35 (Device_Optimization/sde/sde_opt.cmd); only the bottom gate
stack removed. Floating body (no substrate contact, same as GAA). Areafactor=1.0 (no
wraparound to emulate with one gate; GAA's 0.071 was a double-gate-emulating-GAA fudge).
Drop-in analogue of Device_Optimization/SNN_PARAMETERS.md for the ECG-LSNN stage1.
Op point: V_read=0.0 V, V_pgm=2.3 V, V_DS=0.05 V, WF=4.35 eV; erase -3.5V/5us.
Memory-window/SS characterization used VE=-4.0/VP=+3.5 -- a moderate overdrive past
planar's OWN coercive point (~3.0V), proportionally matching how GAA's own ivgen.py
overdrives past ITS coercive point (VE=-3.0/VP=2.5 vs op +/-2.0V) -- same methodology,
not an arbitrary voltage.
"""
DEVICE = dict(
    arch="planar (single top gate ablation of the GAA nanosheet, floating body)",
    # --- electrostatics ---
    SS_ers_mVdec=75.1,          # subthreshold slope, erased branch
    SS_pgm_mVdec=51.9,          # subthreshold slope, programmed branch (clean sweep)
    Vth_ers_V=0.0196,            # erased Vth @ Icc=1e-2 uA/um
    Vth_pgm_V=-1.4049,            # programmed Vth (clean, minimal-read-history sweep)
    MW_volts=1.4245,            # Vth_ers - Vth_pgm
    # --- read window / conductance (-> stage1 fefet_synapse) ---
    R_off_ohm=6.0644e+06,              # erased read @ Vg=0
    R_on_ohm=4.2626e+02,                # programmed read @ Vg=0
    window=1.4227e+04,                # ON/OFF current ratio at Vg=0
    g_min_S=1.6490e-07,                # 1/R_off  -> g_min
    g_max_S=2.3460e-03,                # 1/R_on   -> g_max
    n_levels=10,                      # distinguishable LTP levels (>=1.5x apart)
    # --- dynamics / energy ---
    dVth_per_pulse_V=-2.7061e-02,  # mean Vth shift per program pulse (via SS_ers)
    E_pulse_J=3.022e-13,            # integ V_pgm*|I_gate|dt, mean per program pulse (per um)
    fire_ratio=8.178e+03,        # ID(pN)/ID_baseline at op point
    fire_ratio_p9=1.756e+03,        # ID(p9)/ID_baseline (GAA fire-at-P9 criterion)
    retention_pct_100us=98.5,  # % programmed current retained over 100 us hold
    # --- polarization ---
    dP_C_cm2=5.129e-06,                  # |P_pgm - P_ers| retained (top-FE y-probe)
    # --- operating point ---
    V_read=0.0, V_pgm=2.3, V_DS=0.05, WF=4.35,
)

# stage1 drop-in: g_min, g_max = DEVICE["g_min_S"], DEVICE["g_max_S"]; NLEVELS=DEVICE["n_levels"]
