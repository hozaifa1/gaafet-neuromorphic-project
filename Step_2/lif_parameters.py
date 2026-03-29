"""
LIF Parameters for Step 2: FeFET-based Spiking Neural Network
===========================================================

Extracted from SimC v6 TCAD simulations (pw=100ns, Vpulse=5/6/7V).
Optimal operating point: 6V → Fire at P9 (gradual integration → spike)

Author: TCAD Analysis Pipeline
Date: March 2026
"""

# =============================================================================
# DEVICE PHYSICS (from calibration Run 16)
# =============================================================================
DEVICE = {
    "Vth_virgin": 0.263,          # V (threshold voltage in virgin state)
    "Vth_fire": 0.203,            # V (estimated: Vth after 9 pulses at 6V)
    "SS": 60.8e-3,                # V/dec (subthreshold slope)
    "ID_baseline": 9.525e-6,      # A (read current at VGS_read=0.20V)
    "ID_fire": 1.938e-5,          # A (6V at P9 = 2.035× baseline)
    "MW": 0.681,                  # V (memory window from hysteresis sweep)
    "AreaFactor": 0.071,          # dimensionless (device scaling factor)
}

# =============================================================================
# OPERATING CONDITIONS (from v6 optimal 6V node)
# =============================================================================
OPERATING = {
    "VGS_read": 0.20,             # V (constant read voltage, below Vth)
    "Vpulse_optimal": 6.0,        # V (sweet spot: fire at P9)
    "Vpulse_min_fire": 6.0,       # V (5V saturates at 1.89×, doesn't fire)
    "Vreset": -5.0,               # V (reset voltage)
    "pw": 100e-9,                 # s (100ns pulse width)
    "tau_E": 1e-6,                # s (ferroelectric switching time constant)
    "pw_over_tau_E": 0.1,         # dimensionless (optimal gradual integration ratio)
}

# =============================================================================
# LIF DYNAMICS (extracted from v6 6V node)
# =============================================================================
LIF = {
    "N_fire": 9,                  # pulses (fire at P9 for 6V)
    "fire_threshold": 2.0,        # ID/ID_baseline ratio
    "fire_ratio": 2.035,          # actual ratio at fire (6V P9)
    "dVth_per_pulse": -6.7e-3,    # V/pulse (avg ΔVth in gradual regime P1-P9)
    "leak_drop_ratio": 0.20,      # ~20% current drop in 5µs gap
    "reset_completeness": 77.2,   # % (post-reset returns to 77% of baseline)
}

# =============================================================================
# POLARIZATION (from v6 data at HZO layer)
# =============================================================================
POLARIZATION = {
    "P_baseline": -0.63e-6,       # C/cm² (baseline polarization)
    "P_fire": 1.22e-6,            # C/cm² (polarization at fire)
    "Delta_P_fire": 1.85e-6,      # C/cm² (total switched polarization)
    "Ec_estimate": 1.2,             # V (coercive voltage, from HZO paper)
    "V_HZO_at_6V": 1.73,          # V (V_FE at Vpulse=6V via cap divider)
}

# =============================================================================
# PENDING PARAMETERS (require additional simulations)
# =============================================================================
PENDING = {
    "tau_leak": None,             # s (leak time constant — needs τ_P > 0 run)
    "E_spike": None,              # J (energy per spike — needs transient power)
    "E_per_pulse": None,          # J (energy per pulse — needs power integration)
}

# =============================================================================
# SNN MAPPING CONSTANTS
# =============================================================================
SNN = {
    "pulse_period": 202e-9,       # s (TR + PW + TF + T_READ = 202ns)
    "integration_window": 9 * 202e-9,  # s (N_fire × pulse_period)
    "weight_to_Vpulse_slope": 0.5,  # V per weight unit (example mapping)
    "max_weight_Vpulse": 6.5,       # V (max Vpulse for weight=1.0)
    "min_weight_Vpulse": 5.5,       # V (min Vpulse for weight=0.1)
}

# =============================================================================
# COMPLETE PARAMETER DICTIONARY (for easy import)
# =============================================================================
LIF_PARAMETERS = {**DEVICE, **OPERATING, **LIF, **POLARIZATION}


def print_parameters():
    """Print all extracted LIF parameters."""
    print("=" * 70)
    print("LIF PARAMETERS EXTRACTED FROM SimC v6 (6V Node — Fire at P9)")
    print("=" * 70)
    
    print("\n--- DEVICE PHYSICS ---")
    for k, v in DEVICE.items():
        unit = "V" if "V" in k else ("A" if "ID" in k else ("V/dec" if "SS" in k else ""))
        print(f"  {k:20s}: {v:12.4e} {unit}")
    
    print("\n--- OPERATING CONDITIONS ---")
    for k, v in OPERATING.items():
        unit = "V" if "V" in k else ("s" if "tau" in k or "pw" in k else "")
        print(f"  {k:20s}: {v:12.4e} {unit}")
    
    print("\n--- LIF DYNAMICS ---")
    for k, v in LIF.items():
        unit = "pulses" if "N_fire" in k else ("V/pulse" if "dVth" in k else "%")
        if k == "fire_threshold":
            unit = "ratio"
        elif k == "fire_ratio":
            unit = "ratio"
        print(f"  {k:20s}: {v:12.4f} {unit}")
    
    print("\n--- POLARIZATION ---")
    for k, v in POLARIZATION.items():
        unit = "C/cm²" if "P" in k and k != "V_HZO" else "V"
        print(f"  {k:20s}: {v:12.4e} {unit}")
    
    print("\n--- PENDING (for future work) ---")
    for k, v in PENDING.items():
        val = f"{v:.4e}" if v else "TBD"
        unit = "s" if "tau" in k else "J"
        print(f"  {k:20s}: {val:>12s} {unit}")
    
    print("\n" + "=" * 70)
    print(f"Integration window: {SNN['integration_window']*1e6:.2f} µs ({LIF['N_fire']} pulses)")
    print(f"Fire threshold: ID_ratio > {LIF['fire_threshold']:.1f}×")
    print(f"Actual fire: ID_ratio = {LIF['fire_ratio']:.3f}× at P{LIF['N_fire']}")
    print("=" * 70)


if __name__ == "__main__":
    print_parameters()
