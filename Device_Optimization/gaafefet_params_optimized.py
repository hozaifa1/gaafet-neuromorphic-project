"""
LIF Parameters — OPTIMIZED GAA-FeFET (drop-in replacement for gaafefet_params.py)
================================================================================

Extracted from the optimized device (Device_Optimization/, mesh fe07) after the
autonomous device-optimization campaign. Same structure/keys as the original
gaafefet_params.py so the existing SNN code (model_2.py / main_ecg_*.py) runs
unchanged — only the VALUES change.

Optimized geometry: T_ox=1 nm, T_si=5 nm, T_fe=7 nm, L_g=100 nm; calibrated HZO
Preisach (P_r=32 µC/cm², F_c=1.4 MV/cm). Operating point: read at V_G=0 V,
potentiate +2 V/0.3 µs pulses, erase -2 V.  See OPTIMIZED_DEVICE.md / OPT_LOG.md.

Author: TCAD optimization pipeline.  Date: 2026-06-22.
Provenance for every value is in the trailing comment (sim source).

NORMALIZATION (2026-07-31, PLOT_PLAN.md Part I).  Every absolute current, charge,
resistance and energy below is stated for ONE nanosheet under the single width
convention in norm.py: W_eff = TESW = 2*(W + T_si) = 90 nm, which maps the 2D
double-gate slab onto the GAA via Areafactor = W_eff/2 = 0.045 um.  The runs
themselves executed with Areafactor = 0.071 (a leftover from the superseded first
calibration campaign), so every absolute value here is the simulated one times
0.6338; resistances are divided by it.  The old dimensionless area key is gone --
the factor is applied upstream in norm.py, and re-applying it here was the bug
that made these numbers a third, undocumented convention.

HONEST CAVEAT: the absolute current level is NOT experimentally calibrated.  The
Liao-2022 overlay fits a free width scalar, which absorbs any constant
normalization error (the fitted gap is 141x).  What IS calibrated: the memory
window, V_t, SS, the on/off ratio, and the turn-on shape.
"""

# =============================================================================
# DEVICE PHYSICS  (from the optimized fe07 fine transfer-curve + memory window)
# =============================================================================
DEVICE = {
    # --- all six from ONE node: iv_fe07b (RR-0), the 41-point retained I-V ---
    "Vth_virgin": 0.024,          # V  erased-state Vth @ I_cc = 6.34e-3 uA/um
    "Vth_fire": -0.363,           # V  programmed-state Vth, same criterion
    "SS": 63.5e-3,                # V/dec  programmed branch, steepest >=2-decade fit
    "ID_baseline": 4.05e-10,      # A  erased read @ V_G=0   (4.504e-3 uA/um)
    "ID_fire": 2.193e-6,          # A  programmed read @ V_G=0 (24.37 uA/um) -- see note
    "MW": 0.387,                  # V  memory window = Vth_virgin - Vth_fire
    # PROVENANCE (RR-0, 2026-08-01).  These six now all come from iv_fe07b, the
    # 41-point retained I-V (-1.0..+1.0 V, 50 mV steps) under app.par.  They
    # previously came from mwfine (19 points, -0.4..+0.5 V).  Both use the same
    # +-2.0 V / 5 us write and the same par, so the shift is NOT a physics change:
    # it is post-write settling.  The retained state relaxes on the tau_E = 1 us
    # scale after the write ends, and the three nodes read V_G=0 after different
    # numbers of preceding read points:
    #
    #   node       reads before V_G=0    erased        programmed
    #   mw_fe07     4  (0.24 us)         5.96e-3       18.70 uA/um
    #   mwfine      8  (0.48 us)         4.92e-3       20.95 uA/um
    #   iv_fe07b   20  (1.20 us)         4.50e-3       24.37 uA/um
    #
    # The two states move APART with settling time, so the longest-settled read
    # is the closest to the true retained state. This also explains contradiction
    # C2 (the "21 % gap" between two erased-at-V_G=0 numbers): it is a
    # measurement-delay effect, not an inconsistency, and it is quantified above.
    #
    # SS: 62.3 mV/dec was the steepest single 50 mV pair. A single pair on a
    # 50 mV grid spans a whole decade, so one point sets the answer; the
    # programmed branch has an ambipolar minimum at V_G = -0.55 V whose crossover
    # reads as 45 mV/dec. The value above is a fit over >=2 decades starting >=1
    # decade above that minimum. Sub-60 mV/dec is still expected here and is the
    # NC steepening figure B4 reports; it is not claimed off a single point.
    #
    # NOTE on ID_fire: this key is the PROGRAMMED read at V_G=0 from the same
    # node, so DEVICE is internally consistent. The LIF fire current after 9
    # sub-coercive pulses is a different measurement and lives in LIF below.
}

# =============================================================================
# OPERATING CONDITIONS  (optimized operating point)
# =============================================================================
OPERATING = {
    "VGS_read": 0.0,              # V  read at V_G=0 (electron channel; -0.5 V is GIDL)
    "Vpulse_optimal": 2.0,        # V  potentiation pulse (was 6 V)
    "Vpulse_min_fire": 2.0,       # V
    "Vreset": -2.0,               # V  erase/reset (was -5 V)
    "pw": 0.3e-6,                 # s  potentiation pulse width (gradual LTP; ~0.3*tau_E)
    "tau_E": 1e-6,                # s  FE switching time constant (calibrated, unchanged)
    "pw_over_tau_E": 0.3,         # dimensionless
}

# =============================================================================
# LIF DYNAMICS  (from the LTP potentiation curve, read @ V_G=0)
# =============================================================================
LIF = {
    "N_fire": 9,                  # pulses (fire criterion kept at P9 for comparison)
    "fire_threshold": 2.0,        # ID/ID_baseline detection ratio
    "fire_ratio": 18.4,           # ID(P9)/ID_baseline, BOTH from t8_ltp (see note)
    # CORRECTED 2026-08-01. The published 30.6x divided t8_ltp's pulse-9 read by
    # mwfine's baseline -- two different nodes, so two different post-write
    # settling times. Using t8_ltp's own baseline_pre read (8.21e-3 uA/um) gives
    # 18.4x. Same class of error as the Areafactor one: a ratio assembled from
    # numbers that were never measured together.
    "dVth_per_pulse": -18.3e-3,   # V/pulse  = -SS * 0.294 dec/pulse (LTP, 0.3 µs pulse)
    "leak_drop_ratio": 0.0,       # NON-VOLATILE: conductance holds flat 100 µs at V_G=0
    # → device does NOT self-leak; LIF leak = depolarising refresh or circuit-level.
    "reset_completeness": 100.0,  # % erase returns to a clean retained off-state
    # (multi-cycle endurance drift not yet characterised — optional follow-up)
    # All four below are t8_ltp only, so the SNN synapse's dynamic range is a
    # single coherent measurement rather than a mix of nodes.
    "ID_baseline_ltp": 7.389e-10,  # A  t8_ltp baseline_pre (8.21e-3 uA/um)
    "ID_p9": 1.359e-8,            # A  read after 9 pulses  (1.510e-1 uA/um)
    "ID_p15": 7.485e-7,           # A  read after 15 pulses (8.317 uA/um)
    "R_off_estimate": 6.767e7,    # Ω  VDS/ID_baseline_ltp
    "R_on_estimate": 3.680e6,     # Ω  VDS/ID_p9
    "R_on_p15": 6.680e4,          # Ω  VDS/ID_p15
    "g_min": 1.478e-8,            # S  1/R_off -- the SNN synapse's low weight
    "g_max": 2.718e-7,            # S  1/R_on at pulse 9 (the fire criterion)
    "g_max_p15": 1.497e-5,        # S  1/R at pulse 15, the top analog level
    "dynamic_range_p15": 1013.1,  # ID_p15 / ID_baseline_ltp
    # NOTE: R values are ~10^4 higher than the prior device (lower currents → higher R,
    # huge ON/OFF contrast). The SNN's tau = C_mem*(R_h+R_s) and gain = (R_h+R_s)*s
    # must be re-tuned via C_mem and input_scaling s, exactly as the PDF describes
    # (e.g. for tau=11.11 ms: C_mem = tau/(R_off+R_on) ≈ 11.11e-3 / 7.16e7 ≈ 155 pF).
}

# =============================================================================
# POLARIZATION  (probe Pol/y at FE midpoint; sign = top-FE y-orientation)
# =============================================================================
POLARIZATION = {
    "P_baseline": 0.317e-6,       # C/cm²  erased retained polarisation
    "P_fire": -1.944e-6,          # C/cm²  programmed retained polarisation
    "Delta_P_fire": -2.261e-6,    # C/cm²  switched polarisation (|ΔP| ≈ 2.26)
    "Ec_estimate": 0.98,          # V  coercive voltage = F_c*T_fe = 1.4MV/cm * 7nm
    "V_HZO_at_Vpulse": 0.83,      # V  V_FE at Vpulse=2 V (|E|≈0.85 F_c via probe)
}

# =============================================================================
# PENDING / ENERGY
# =============================================================================
PENDING = {
    "tau_leak": None,             # NON-VOLATILE at V_G=0 (no self-decay over 100 µs);
    # an engineered leak needs a depolarising hold bias — see OPTIMIZED_DEVICE.md.
    "E_spike": 8.87e-18,          # J  ~0.0089 fJ per +2 V/0.3 µs program pulse (gate switching)
    "E_per_pulse": 8.87e-18,      # J  (≈0.13 fJ for the full 15-pulse potentiation)
}

# =============================================================================
# SNN MAPPING CONSTANTS
# =============================================================================
SNN = {
    "pulse_period": 0.331e-6,     # s  rise(1ns)+pw(0.3µs)+fall(1ns)+read(30ns)
    "integration_window": 9 * 0.331e-6,  # s
    "weight_to_Vpulse_slope": 0.5,   # V per weight unit (example mapping around 2 V)
    "max_weight_Vpulse": 2.5,        # V  (was 6.5)
    "min_weight_Vpulse": 1.5,        # V  (was 5.5)
}

LIF_PARAMETERS = {**DEVICE, **OPERATING, **LIF, **POLARIZATION}


def print_parameters():
    print("=" * 70)
    print("LIF PARAMETERS — OPTIMIZED GAA-FeFET (fe07, read @ V_G=0)")
    print("=" * 70)
    for name, block in [("DEVICE", DEVICE), ("OPERATING", OPERATING),
                        ("LIF", LIF), ("POLARIZATION", POLARIZATION),
                        ("PENDING/ENERGY", PENDING), ("SNN", SNN)]:
        print(f"\n--- {name} ---")
        for k, v in block.items():
            print(f"  {k:22s}: {v}")
    print("\n" + "=" * 70)
    print(f"Memory window {DEVICE['MW']:.3f} V | SS {DEVICE['SS']*1e3:.1f} mV/dec | "
          f"fire_ratio {LIF['fire_ratio']:.1f}x (9-pulse LIF contrast) | "
          f"retained ON/OFF 5410x | E ~{PENDING['E_spike']*1e15:.4f} fJ/pulse")
    print("W_eff = 90 nm gate perimeter (norm.py). Absolute current is NOT "
          "experimentally calibrated -- window / V_t / SS / on-off / shape are.")
    print("=" * 70)


if __name__ == "__main__":
    print_parameters()
