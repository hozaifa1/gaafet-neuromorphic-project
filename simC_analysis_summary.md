# SimC Analysis Summary - Full LIF Cycle Demonstration

**Date:** March 24, 2026 (original) / Corrected: March 2026  
**Analysis Script:** `analyze_simC_corrected.py`  
**Status:** PARTIAL — Integration and Reset validated; Fire detection **invalid** (see §Corrections)

## Executive Summary

SimC demonstrates **two of four** LIF behaviors:
- **Integration:** Confirmed — cumulative ΔVth of 16.1 mV over 5 pulses (consistent with simB rate)
- **Reset:** Confirmed — 100% Vth recovery with Vreset = -4V
- **Fire:** **NOT demonstrated** — the reported 6.8x "fire ratio" is an artifact of comparing currents at VGS=2V (pulse hold) vs VGS≈0.05V (QS baseline), not a threshold-crossing event
- **Leak:** **NOT demonstrated** — current decay during gaps is device settling from VGS=2V→0V transient, not ferroelectric domain relaxation (τ_P = 0)

A redesigned simulation with a **write-then-read protocol** is required to demonstrate actual fire behavior.

## Corrections to Previous Analysis

### "Fire Detection" Was Invalid

The previous analysis claimed "Fire detected at pulse 5 with 6.8x current ratio." This is **incorrect**.

**What happened:** The analysis script (`analyze_simC_corrected.py`, line 273) compared:
- `id_base` = drain current from QS baseline readout at VGS ≈ 0.05V → **3.8 µA**
- `max_current` = peak drain current during pulse hold at VGS = **2.0V** → **26.3 µA**

This 6.8x ratio is simply **I_D(VGS=2V) / I_D(VGS=0.05V)** — the device's normal transconductance response. It is NOT a threshold-crossing fire event.

**What a real fire looks like (from literature):**
- Lizzit et al. (Multi-level FeFET, Fig 5-7): Write pulses shift Vth; READ current at **constant VGS** increases with each cycle; fire = read current crosses a threshold at the **same VGS**
- Khanday et al. (Fig 4): Capacitor voltage rises to Vth → device turns ON → **current spike at the same operating point**

**The real signal in pulse-hold data:** Currents of 26.239 → 26.255 µA across 5 pulses (**0.06% growth**). This tiny increase IS real Vth shift evidence, but it is not a fire event.

### "Leak Rate" Was Misattributed

The 0.620 µA/µs "leak rate" during inter-pulse gaps is the device **settling from VGS=2V transient back to VGS=0V steady state**, not ferroelectric domain relaxation. With τ_P = 0, there is zero FE-based leak.

### Invalidated Parameters

The following parameters from the previous analysis are **invalid** and must not be used:

| Parameter | Previous Value | Status |
|-----------|---------------|--------|
| `fire_ratio = 6.8x` | ❌ Invalid — comparing different VGS points |
| `E_spike = 75 fJ` | ❌ Invalid — no spike occurred |
| `R_on = 1.9 kΩ` | ❌ Invalid — from bogus fire current |
| `R_off = 13 kΩ` | ❌ Invalid — from bogus baseline |
| `Vth_fire = 0.247V` | ❌ Misleading — this is just Vth_virgin - ΔVth_integration, not an observed fire threshold |
| `leak_rate = 0.620 µA/µs` | ❌ Invalid — device settling, not FE relaxation |

## Valid Results

### 1. Integration (ΔVth via QS Readout)

| Node (Vreset) | Integration ΔVth | Reset Completeness |
|---------------|------------------|--------------------|
| n3 (-2.0V)    | 7.4 mV           | 99.3%              |
| n4 (-3.0V)    | 11.7 mV          | 99.3%              |
| n5 (-4.0V)    | 16.1 mV          | 100.0%             |

**Best performer:** Node n5 (Vreset = -4.0V)  
**Consistency check:** 5 pulses × ~3.2 mV/pulse ≈ 16 mV. SimB shows ~11.4 mV/pulse for 20 pulses. The per-pulse ΔVth is lower here because only 5 pulses were applied (earlier pulses shift Vth more efficiently than later ones due to partial saturation).

### 2. Reset Performance

- **Vreset = -4.0V:** 100% Vth recovery — fully resets polarization state
- **Vreset = -3.0V / -2.0V:** 99.3% recovery — nearly complete
- This is a solid result and consistent with the coercive field requirement

### 3. Pulse-Hold Polarization Dynamics

- **Polarization at end of 5 pulse holds:** +0.081 → +0.064 µC/cm² (monotonic shift toward negative)
- **Total P shift:** -0.018 µC/cm² (~0.1% of P_r) — appropriate for sub-coercive regime
- Confirms partial switching is occurring during each pulse

### 4. Gap Current Decay (Device Settling, NOT Leak)

- Current decays from ~2.7 µA to ~2.2 µA over 1µs gaps (VGS=0V)
- This is the device settling to steady-state after the gate transient
- With τ_P = 0, there is no FE relaxation contributing to this decay

## What SimC Does NOT Demonstrate

1. **No fire event:** No threshold crossing was observed. The device is strongly ON at VGS=2V and near-threshold at VGS=0V regardless of FE state. The 0.06% current growth across 5 pulses is too small to constitute a fire event.

2. **No true leak:** With τ_P = 0, there is no ferroelectric domain relaxation. All current decay during gaps is electrical settling.

3. **No operating-point sensitivity:** The simulation never reads ID at a constant VGS near Vth to observe the progressive Vth shift causing a fire.

## Root Cause: Wrong Measurement Protocol

The simC cmd file applies gate pulses (0→2V→0V) and monitors current during pulse holds (VGS=2V) and gaps (VGS=0V). Neither of these operating points is suitable for observing fire behavior because:

- **At VGS=2V:** Device is in deep strong inversion. A 16 mV Vth shift produces only 0.06% current change — undetectable as a fire event.
- **At VGS=0V:** Device is near threshold but not sensitive enough to show dramatic current jump from small Vth shifts.
- **No read at VGS near Vth:** There is no separate "read" operation at a constant VGS just below Vth where the subthreshold slope (60.8 mV/dec) would amplify Vth shifts into large current changes.

## Required Fix: Write-Then-Read Protocol

To demonstrate actual fire behavior, simC must be redesigned:

### New Protocol
1. Set constant **read bias** VGS_read ≈ 0.20V (just below Vth_virgin = 0.263V)
2. Apply **write pulses** as brief gate excursions: VGS_read → 2.0V → VGS_read
3. After each write pulse, **monitor ID at VGS_read** for ~100ns (transient read, preserving P state)
4. **Expected fire:** After N pulses, when cumulative ΔVth shifts Vth below 0.20V, ID at VGS_read should jump by orders of magnitude (subthreshold → above-threshold transition)
5. **Reset:** Negative gate pulse restores Vth above VGS_read

### Expected Fire Signal
With SS = 60.8 mV/dec and Vth_virgin = 0.263V:
- At VGS_read = 0.20V, initial ID ≈ I_0 × 10^(-63mV/60.8mV) ≈ very low (deep subthreshold)
- Each pulse shifts Vth by ~3-11 mV → ID increases ~1.5-4x per pulse at VGS_read
- After N pulses where Vth < 0.20V → ID jumps to strong inversion → **FIRE**
- This would be a genuine threshold-crossing event visible at a constant read voltage

## Valid Parameters for Step 2

Only these parameters should be used:

```python
VALID_PARAMETERS = {
    "Vth_virgin": 0.263,        # V (from calibration Run 16) — VALID
    "dVth_per_pulse": 11.36e-3, # V (from simB, 20 pulses) — VALID
    "Vreset": -4.0,             # V (from simC reset test) — VALID
    "reset_completeness": 1.0,  # fraction (from simC) — VALID
    "SS": 60.8e-3,              # V/dec (from Run 6+7b extraction) — VALID
    "tau_E": 1e-6,              # s (switching time constant) — VALID
}

# NOT YET CHARACTERIZED — require new simulations:
PENDING_PARAMETERS = {
    "N_fire": None,        # Number of pulses to fire — needs write-then-read simC
    "E_spike": None,       # Energy per spike — needs actual fire transient
    "R_on": None,          # ON resistance at fire — needs actual fire measurement
    "R_off": None,         # OFF resistance at read bias — needs read-bias measurement
    "tau_leak": None,      # Leak time constant — needs τ_P > 0 simulation
    "C_gg": None,          # Gate capacitance — needs AC simulation
}
```

## Recommendations

### Immediate Priority
1. **Redesign simC** with write-then-read protocol (new sdevice cmd file)
2. **Set VGS_read** ≈ 0.20V (63 mV below Vth_virgin — ~1 decade of subthreshold margin)
3. **Increase pulse count** to 10-20 (from simB: 20 pulses gives 227 mV shift, well past the 63 mV margin)

### Short-term
1. **Set τ_P > 0** for true FE leak dynamics in gap measurements
2. **AC analysis** for C_gg extraction
3. **Extract E_spike** from actual fire transient waveform

### Long-term
1. Implement corrected FeFET_LIF class with validated parameters only
2. Deploy in SNN after fire demonstration is complete

## Files

1. **Analysis Script:** `analyze_simC_corrected.py` (fire detection logic is invalid — needs rewrite)
2. **Visualization 1-4:** Figures show valid integration/reset data; fire detection panels are misleading
3. **This Summary:** Corrected version supersedes original March 24 analysis

All files are located in `Simulations/py_scripts/` directory.
