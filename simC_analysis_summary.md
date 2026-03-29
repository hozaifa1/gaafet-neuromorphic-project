# SimC Analysis Summary — Write-Then-Read LIF Protocol

**Date:** March 2026 (original QS-based) → April 2026 (write-then-read v3/v4)
**Status:** Integration ✅ | Leak ✅ | Reset ✅ | Fire ⚠️ (not yet gradual — v5 planned)

## Executive Summary

The write-then-read protocol successfully demonstrates **three of four** LIF behaviors. The remaining challenge is achieving **gradual multi-pulse integration** before fire — v3/v4 showed that pw/τ_E = 1 causes saturation within 3 pulses. SimC v5 (pw=100ns, pw/τ_E=0.1) is designed to fix this.

| LIF Behavior | v3 (3/4/5V) | v4 (1.5/2/2.5V) | v5 (planned) |
|---|---|---|---|
| **Integration** | ✅ saturates by P3 | ✅ saturates by P3 | Target: linear P1→P20 |
| **Leak** | ✅ gap visible P5→P6 | ✅ gap visible P5→P6 | ✅ (τ_P=0; future: τ_P>0) |
| **Fire** (ratio>2×) | ⚠️ P1 only (4-5V) | ❌ none reach 2× | Target: P8-15 |
| **Reset** | ✅ 76-99% | ⚠️ overshoots (113-188%) | Target: ~100% (Vreset=-4V) |

## Protocol Description

Unlike the original simC (which read current at VGS=2V during write pulses), the write-then-read protocol reads at a **constant VGS_read=0.20V** (just below Vth_virgin=0.263V). This amplifies small Vth shifts into measurable current ratio changes via the subthreshold slope (SS=60.8 mV/dec).

**Sequence per pulse:** Rise (1ns) → Write hold (pw) → Fall (1ns) → Read hold (100ns)
**Metrics:** $I_{D,read}/I_{D,baseline}$ ratio, polarization Py, estimated ΔVth

## SimC v3 Results — pw=1µs, Vpulse=3/4/5V

**Sweep:** `@Vpulse@` = 3.0, 4.0, 5.0V | N=10 pulses | Vreset=-6V | τ_E=1µs

| Vpulse | P1 Ratio | P10 Ratio | Reset % | Fire? |
|--------|----------|-----------|---------|-------|
| 3.0V | 1.80× | 1.93× | 98.7% | No (close) |
| 4.0V | **2.04×** | 2.17× | 83.4% | **P1** |
| 5.0V | **2.24×** | 2.36× | 76.1% | **P1** |

**Key findings:**
- 4V/5V fire on first pulse — pw=1µs is too long (pw/τ_E=1 → 63% switching per pulse)
- 3V approaches fire but saturates by P3 (1.80→1.87→1.91→plateau)
- Leak gap at P5→P6 shows current dip — ferroelectric relaxation signature
- Reset completeness inversely correlated with Vpulse (stronger P harder to reset)

## SimC v4 Results — pw=1µs, Vpulse=1.5/2.0/2.5V

**Sweep:** `@Vpulse@` = 1.5, 2.0, 2.5V | N=10 pulses | Vreset=-6V | τ_E=1µs

> SWB directories named n3(3V)/n4(4V)/n5(5V) — actual Vpulse verified from gate OuterVoltage in rise files.

| Vpulse | P1 Ratio | P10 Ratio | ΔVth P10 (mV) | Reset % |
|--------|----------|-----------|---------------|---------|
| 1.5V | 1.35× | 1.43× | −9.7 | 188% ⚠️ |
| 2.0V | 1.51× | 1.62× | −12.8 | 138% ⚠️ |
| 2.5V | 1.66× | 1.78× | −15.2 | 113% ⚠️ |

**Key findings:**
- **No fire** — all saturate below 1.8× (well short of 2× threshold)
- Same exponential saturation pattern (pw/τ_E = 1)
- **Reset overshoots** — Vreset=-6V too strong for these small polarization shifts
- Lower Vpulse reduces saturation ceiling but does NOT improve linearity

## Root Cause: pw/τ_E Ratio Too High

With pw/τ_E = 1µs/1µs = 1, each pulse switches ~63% of remaining switchable polarization (1 - e^(-1)). This causes:
- P1: 63% switched → big jump
- P2: 63% of remaining 37% = 23% → small additional
- P3: 63% of remaining 14% = 9% → nearly saturated
- **Result:** Exponential saturation in 3 pulses, regardless of Vpulse

**Fix:** Reduce pw/τ_E to 0.1 → ~10% switching per pulse → ~10 pulses to 65% → gradual linear integration.

## SimC v5 Plan — pw=100ns, Vpulse=3/4/5V, Vreset=-4V

| Parameter | v3 | v4 | **v5** |
|-----------|----|----|--------|
| pw | 1µs | 1µs | **100ns** |
| pw/τ_E | 1.0 | 1.0 | **0.1** |
| Vpulse | 3/4/5V | 1.5/2/2.5V | **3/4/5V** |
| N_PULSES | 10 | 10 | **20** |
| Vreset | -6V | -6V | **-4V** |
| LEAK_AFTER | 5 | 5 | **10** |

**Expected results:**
- 3V: ~1.08× per pulse → fire after ~25 pulses (may not reach in 20)
- **4V: ~1.10× per pulse → fire after ~10 pulses** ← optimal target
- 5V: ~1.12× per pulse → fire after ~8 pulses

**Files:** `Simulations/simC/sdevice_simC_v5.cmd`, `generate_simC_v5.py`

## Valid Parameters for Step 2

```python
VALID_PARAMETERS = {
    "Vth_virgin": 0.263,        # V (from calibration Run 16)
    "ID_baseline": 9.525e-6,    # A (from write-then-read at VGS_read=0.20V)
    "Vreset": -4.0,             # V (v5 target; v3 showed -6V works but overshoots at low Vpulse)
    "SS": 60.8e-3,              # V/dec (from Run 6+7b extraction)
    "tau_E": 1e-6,              # s (switching time constant in par file)
    "MW": 0.681,                # V (from calibration Run 16)
}

PENDING_PARAMETERS = {  # Require v5 results
    "N_fire": None,        # Number of pulses to fire at optimal Vpulse
    "dVth_per_pulse": None, # ΔVth per pulse in gradual regime (v5)
    "E_spike": None,       # Energy per spike from fire transient
    "tau_leak": None,      # Leak time constant (needs τ_P > 0)
}
```

## Next Steps

1. **Run SimC v5** on Sentaurus server (SWB: sweep @Vpulse@ = 3.0, 4.0, 5.0)
2. **Analyze v5 results** — expect gradual integration curve + fire at P8-15
3. **If fire confirmed:** Extract N_fire, E_spike, dVth_per_pulse → populate PENDING_PARAMETERS
4. **If no fire at P20:** Increase N_PULSES to 30, or try Vpulse=6V
5. **After fire confirmed:** Run with τ_P > 0 for true leak characterization
6. **Final:** Extract all LIF parameters → feed into Step 2 SNN model

## Analysis Scripts & Plots

| File | Purpose |
|------|---------|
| `py_scripts/analyze_simC_v3.py` | v4 analysis (updated from v3, reads current v4 data) |
| `py_scripts/simC_v3_fig[1-6]_*.png` | v3 results (6 plots) |
| `py_scripts/simC_v4_fig[1-6]_*.png` | v4 results (6 plots) |
| `simC/generate_simC_v3.py` | v3 cmd generator |
| `simC/generate_simC_v4.py` | v4 cmd generator |
| `simC/generate_simC_v5.py` | v5 cmd generator |
| `simC/sdevice_simC_v[3-5].cmd` | Simulation command files |
