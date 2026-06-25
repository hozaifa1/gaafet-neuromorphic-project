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
"""

# =============================================================================
# DEVICE PHYSICS  (from the optimized fe07 fine transfer-curve + memory window)
# =============================================================================
DEVICE = {
    "Vth_virgin": 0.018,          # V  erased-state Vth @ Icc=1e-2 µA/µm (fine I-V)
    "Vth_fire": -0.318,           # V  programmed-state Vth (fine I-V)
    "SS": 62.3e-3,                # V/dec  subthreshold slope (near-ideal; 5 nm body)
    "ID_baseline": 7.0e-10,       # A  erased read current @ VGS_read=0 V (fine I-V)
    "ID_fire": 2.14e-8,           # A  read current after 9 pulses (LTP)
    "MW": 0.336,                  # V  memory window = Vth_virgin - Vth_fire
    "AreaFactor": 0.071,          # dimensionless (unchanged)
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
    "fire_ratio": 30.6,           # actual ID(P9)/ID_baseline  (prior device: 2.035)
    "dVth_per_pulse": -18.3e-3,   # V/pulse  = -SS * 0.294 dec/pulse (LTP, 0.3 µs pulse)
    "leak_drop_ratio": 0.0,       # NON-VOLATILE: conductance holds flat 100 µs at V_G=0
    # → device does NOT self-leak; LIF leak = depolarising refresh or circuit-level.
    "reset_completeness": 100.0,  # % erase returns to a clean retained off-state
    # (multi-cycle endurance drift not yet characterised — optional follow-up)
    "R_on_estimate": 2.34e6,      # Ω  VDS/ID_fire = 0.05V / 2.14e-8 A  (was 2.58e3)
    "R_off_estimate": 7.14e7,     # Ω  VDS/ID_baseline = 0.05V / 7.0e-10 A (was 5.25e3)
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
    "E_spike": 1.4e-17,           # J  ~0.014 fJ per +2 V/0.3 µs program pulse (gate switching)
    "E_per_pulse": 1.4e-17,       # J  (≈0.21 fJ for the full 15-pulse potentiation)
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
          f"fire_ratio {LIF['fire_ratio']:.1f}x (prior 2.0x) | "
          f"ON/OFF(full) ~3140x | E ~{PENDING['E_spike']*1e15:.3f} fJ/pulse")
    print("=" * 70)


if __name__ == "__main__":
    print_parameters()
